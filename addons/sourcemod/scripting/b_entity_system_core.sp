#include <sourcemod>

#pragma newdecls required

#include <sdkhooks>
#include <sdktools>

#undef REQUIRE_PLUGIN 
#include <adminmenu>

#include <entity_system>

public Plugin myinfo = 
{
	name		= "[Entity System] Core",
	author		= "Rostu",
	description	= "Ядро для управления Entity сервера ",
	version		= "3.0.0",
	url			= "https://vk.com/rostu13"
};

enum 
{
	Settings_Name,
	Settings_Min,
	Settings_Max,
}

enum ChangeTypeEntity
{
	Type_Pos,
	Type_Angles,
	Type_RGB,

	// Future
	Type_MAX
};
enum ChangePosEntity
{
	Axis_X,
	Axis_Z,
	Axis_Y
};

enum ChangeRGBEntity
{
	Color_Red,
	Color_Green,
	Color_Blue
};
stock const char g_sChangeRGB[][] =
{
	"Красный",
	"Зеленый",
	"Синий"
};

stock const char g_sRedact[][] = 
{
	"Позицию",
	"Углы",
	"RGB"
};

EntityEditType g_Type[MAXPLAYERS + 1];
ChangeTypeEntity 	g_TypePos	[MAXPLAYERS + 1];
ChangePosEntity 	g_Axis		[MAXPLAYERS + 1];
ChangeRGBEntity 	g_Color		[MAXPLAYERS + 1];

#define Settings_MIN 0
#define Settings_MAX 1

int g_iCustomSettings[MAXPLAYERS + 1][2];
int g_iCustomCurrent[MAXPLAYERS + 1];
char g_sCustomName[MAXPLAYERS + 1][32];

TopMenu g_hAdmin;

KeyValues g_hKv;
char g_sPath[PLATFORM_MAX_PATH];

char g_sClassName[MAXPLAYERS + 1][32];

int g_iEntityEdited[MAXPLAYERS + 1];	// Какую entity Администратор редактирует.
bool g_bEditPosEntity[MAXPLAYERS + 1];

ArrayList g_hRegisteredTypes;

int g_iRenderClrOffset;

bool g_bLate;

#include "EntitySystem/Stock.sp"
#include "EntitySystem/Native.sp"
#include "EntitySystem/Forwards.sp"
#include "EntitySystem/Admin.sp"
#include "EntitySystem/Menu.sp"

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] sError, int iErrorMax)
{
	g_bLate = bLate;
	Entity_CreateNative();
	RegPluginLibrary( "entity_system" );
}

public void OnPluginStart()
{
	HookEvent("round_start", Event_Start,EventHookMode_PostNoCopy);

	g_iRenderClrOffset  = FindSendPropInfo( "CCSPlayer", "m_clrRender"   ); 

	if(LibraryExists("adminmenu"))
	{
		TopMenu hTopMenu;
		if((hTopMenu = GetAdminTopMenu()) != null) OnAdminMenuReady(hTopMenu);
	}

	if(g_bLate)
		for(int x = 1; x <= MaxClients; x++) if(IsClientInGame(x) && !IsFakeClient(x)) OnClientPutInServer(x);
}

public void OnLibraryRemoved(const char[] sName)
{
	if(!strcmp(sName, "adminmenu")) g_hAdmin = null;
}
public void OnClientDisconnect(int client)
{
	g_Type[client] = EditType_None;
}

public void OnMapStart()
{
	if(g_hKv != null) g_hKv.Close();

	BuildPath(Path_SM, g_sPath,sizeof g_sPath, "configs/EntitySystem");
	if ( !DirExistsEx( g_sPath ) ) return;
    
    char sMap[128];
    GetCurrentMapSafe( sMap, sizeof sMap);

    Format( g_sPath, sizeof g_sPath, "%s/%s.ini", g_sPath, sMap );

	g_hKv = new KeyValues("entity");
	g_hKv.ImportFromFile(g_sPath);

	CreateTimer(2.0, Timer_DelayEntity, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DelayEntity(Handle hTimer)
{
	if(g_hRegisteredTypes != null) g_hRegisteredTypes.Close();
	g_hRegisteredTypes = new ArrayList(ByteCountToCells(32));

	Forward_RequestType();

	if(!g_hRegisteredTypes.Length)
	{
		g_hRegisteredTypes.Close();
		return Plugin_Continue;
	}

	char sClassName[64];
	char sEntity[8];

	bool bEdit;

	for (int entity = MAXPLAYERS + 1; entity <= GetEntityCount(); ++entity)
	{
		if(!IsValidEdict(entity)) continue;

		GetEdictClassname(entity, sClassName, sizeof sClassName);

		if(g_hRegisteredTypes.FindString(sClassName) == -1) continue;

		IntToString(entity, sEntity,sizeof sEntity);

		bEdit = g_hKv.JumpToKey(sEntity);
		Forward_OnEntityRegister(entity, sClassName, bEdit, g_hKv );

		if(bEdit)
			ChangeEntityCustomPos(entity);

		g_hKv.Rewind();
	}

	delete g_hRegisteredTypes;
	g_hKv.Rewind();

	return Plugin_Continue;
}
public void Event_Start(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if(!GameRules_GetProp("m_bWarmupPeriod"))	ChangeEntity();
}
public void OnClientPutInServer(int client)
{
	g_bEditPosEntity[client] = false;
	g_iEntityEdited[client] = 0;

	g_Type[client] = EditType_None;
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(g_Type[client] == EditType_None || !g_iEntityEdited[client] || !IsValidEntity(g_iEntityEdited[client])
	|| (!(buttons & IN_USE) == !(buttons & IN_RELOAD)))
		return Plugin_Continue;

	if(g_TypePos[client] == Type_RGB)
	{
		static int iColor[4];
		GetEntDataArray(g_iEntityEdited[client], g_iRenderClrOffset, iColor, 4, 1);

		if(buttons & IN_USE)	iColor[g_Color[client]]++;
		else 					iColor[g_Color[client]]--;

		if(iColor[g_Color[client]] < 1) iColor[g_Color[client]] = 1;
		else if (iColor[g_Color[client]] > 255) iColor[g_Color[client]] = 255;

		SetEntDataArray(g_iEntityEdited[client], g_iRenderClrOffset, iColor, 4, 1);
	}
	else
	{
		static float fVec[3];
		if(g_TypePos[client] == Type_Pos)
		{
			GetEntPropVector(g_iEntityEdited[client], Prop_Send, "m_vecOrigin", fVec);

			if(buttons & IN_USE)	fVec[g_Axis[client]]++;
			else 					fVec[g_Axis[client]]--;

			TeleportEntity(g_iEntityEdited[client], fVec, NULL_VECTOR, NULL_VECTOR);
		}
		else if(g_TypePos[client] == Type_Angles)
		{
			GetEntPropVector(g_iEntityEdited[client], Prop_Send, "m_angRotation", fVec);

			if(buttons & IN_USE)		fVec[g_Axis[client]]++;
			else 						fVec[g_Axis[client]]--;

			if(FloatAbs(fVec[g_Axis[client]]) > 360)
				fVec[g_Axis[client]] = FloatFraction(fVec[g_Axis[client]]) + RoundToZero(fVec[g_Axis[client]]) % 360;

			SetEntPropVector(g_iEntityEdited[client], Prop_Send, "m_angRotation", fVec);
		}
	}

	return Plugin_Continue;
}
