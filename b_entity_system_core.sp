#include <csgo_colors>

#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <entity_system>

#undef REQUIRE_PLUGIN 
#include <adminmenu>

public Plugin myinfo = 
{
	name		= "[Entity System] Core",
	author		= "Rostu",
	description	= "Ядро для управления Entity сервера ",
	version		= "2.0.1",
	url			= "https://vk.com/rostu13"
};

enum ChangeTypePosEntity
{
	Type_Pos,
	Type_Angles
};

enum ChangePosEntity
{
	Axis_X,
	Axis_Z,
	Axis_Y
};

ChangeTypePosEntity g_TypePos[MAXPLAYERS + 1];
ChangePosEntity g_Axis[MAXPLAYERS + 1];

TopMenu g_hAdmin;

char g_sClassName[MAXPLAYERS + 1][32];

int g_iEntityEdited[MAXPLAYERS + 1];	// Какую entity Администратор редактирует.
bool g_bEditPosEntity[MAXPLAYERS + 1];

ArrayList g_hRegisteredTypes;

bool g_bLate,
	g_bLoaded;

#include "EntitySystem/Native.sp"
#include "EntitySystem/Forwards.sp"
#include "EntitySystem/Admin.sp"
#include "EntitySystem/Menu.sp"

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] sError, int iErrorMax)
{
	g_bLate = bLate;
	Entity_CreateNative();
}

public void OnPluginStart()
{
	g_hRegisteredTypes = new ArrayList(ByteCountToCells(32));

	RegConsoleCmd("sm_editmenu", Cmd_EditMenu);

	if(LibraryExists("adminmenu"))
	{
		TopMenu hTopMenu;
		if((hTopMenu = GetAdminTopMenu()) != null) OnAdminMenuReady(hTopMenu);
	}
	if(g_bLate)
	{
		for(int x = 1; x <= MaxClients; x++) if(IsClientInGame(x) && !IsFakeClient(x)) OnClientPutIntServer(x);

		ServerCommand("sm plugins reload adminmenu");
	}

	Forward_RequestType();
	g_bLoaded = true;
}

public void OnLibraryRemoved(const char[] szName)
{
	if(StrEqual(szName, "adminmenu")) g_hAdmin = null;
}

public void OnMapStart()
{
	CreateTimer(3.0, Timer_DelayEntity, _, TIMER_FLAG_NO_MAPCHANGE);
}

stock Action Timer_DelayEntity(Handle hTimer)
{
	char sClassName[64];

	for (int entity = MAXPLAYERS + 1; entity <= GetEntityCount(); ++entity)
	{
		if(!IsValidEdict(entity)) continue;

		GetEdictClassname(entity, sClassName, sizeof sClassName);

		if(g_hRegisteredTypes.FindString(sClassName) == -1) continue;

		Forward_OnEntityRegister(entity, sClassName);
	}
}

public void OnClientPutIntServer(int client)
{
	g_bEditPosEntity[client] = false;
	g_iEntityEdited[client] = 0;
}

public Action Cmd_EditMenu(int client, int iArgs)
{
	CreateEditMenu(client);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(!g_bEditPosEntity[client] || !g_iEntityEdited[client] || !IsValidEntity(g_iEntityEdited[client])
	|| (!(buttons & IN_USE) == !(buttons & IN_RELOAD)))
		return Plugin_Continue;

	static float fVec[3];
	if(g_TypePos[client] == Type_Pos)
	{
		GetEntPropVector(g_iEntityEdited[client], Prop_Send, "m_vecOrigin", fVec);

		if(buttons & IN_USE)
			fVec[g_Axis[client]]++;
		else fVec[g_Axis[client]]--;

		TeleportEntity(g_iEntityEdited[client], fVec, NULL_VECTOR, NULL_VECTOR);
	}
	else if(g_TypePos[client] == Type_Angles)
	{
		GetEntPropVector(g_iEntityEdited[client], Prop_Send, "m_angRotation", fVec);

		if(buttons & IN_USE)
			fVec[g_Axis[client]]++;
		else fVec[g_Axis[client]]--;

		if(FloatAbs(fVec[g_Axis[client]]) > 360)
			fVec[g_Axis[client]] = FloatFraction(fVec[g_Axis[client]]) + RoundToZero(fVec[g_Axis[client]]) % 360;

		SetEntPropVector(g_iEntityEdited[client], Prop_Send, "m_angRotation", fVec);
	}
	return Plugin_Continue;
}

stock void TeleportToEditEntity(int client)
{
	float fPos[3];
	GetEntPropVector(g_iEntityEdited[client], Prop_Data, "m_vecOrigin", fPos);

	TeleportEntity(client,fPos,NULL_VECTOR,NULL_VECTOR);
}

stock int GetClientAxisEdit(int client)
{
	return 'X' + view_as<int>(g_Axis[client]);
}