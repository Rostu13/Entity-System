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
	version		= "4.0.0",
	url			= "https://vk.com/rostu13"
};

#define IsCustomEntity 0

enum 
{
	Settings_Name,
	Settings_Min,
	Settings_Max,
}

enum ChangeType
{
	Type_Pos,
	Type_Angles,
	Type_RGB
};
enum ChangePos
{
	Axis_X,
	Axis_Z,
	Axis_Y
};

enum ChangeRGB
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

enum struct EnitityInfo
{
	int id; // Какую entity Администратор редактирует.
	char sName[32];

	EntityEdit edit;
	ChangeType type;
	ChangePos axis;
	ChangeRGB color;

}
enum struct CustomInfo
{
	int diff[2]; // diffrenece
	int current;
	char sInfo[32];
}

EnitityInfo g_eEntity[MAXPLAYERS + 1];
CustomInfo g_eCustom[MAXPLAYERS + 1];

#define Settings_MIN 0
#define Settings_MAX 1

TopMenu g_hAdmin;

KeyValues g_hKv;
char g_sPath[PLATFORM_MAX_PATH];
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

	g_iRenderClrOffset  = FindSendPropInfo( "CCSPlayer", "m_clrRender"); 

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
	g_eEntity[client].edit = Edit_None;
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

	int iHammerID;
	char sClassName[64];
	char sEntityId[16];

	bool bEdit;

	for (int iEntity = MAXPLAYERS + 1; iEntity <= GetEntityCount(); ++iEntity)
	{
		if(!IsValidEdict(iEntity)) continue;

		GetEdictClassname(iEntity, sClassName, sizeof sClassName);

		if(g_hRegisteredTypes.FindString(sClassName) == -1) continue;

		iHammerID = GetEntProp(iEntity, Prop_Data, "m_iHammerID");
		IntToString(iHammerID, sEntityId,sizeof sEntityId);

		bEdit = iHammerID == IsCustomEntity ? false : g_hKv.JumpToKey(sEntityId);
		Forward_OnEntityRegister(iEntity, sClassName, bEdit, g_hKv );

		if(bEdit)
			ChangeEntitySettings(iEntity);

		g_hKv.Rewind();
	}

	delete g_hRegisteredTypes;
	g_hKv.Rewind();

	return Plugin_Continue;
}
public void Event_Start(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if(!GameRules_GetProp("m_bWarmupPeriod"))	OnMapStart();
}
public void OnClientPutInServer(int client)
{
	g_eEntity[client].id = 0;
	g_eEntity[client].edit = Edit_None;
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	static int iEntity; iEntity = g_eEntity[client].id;

	if(g_eEntity[client].edit == Edit_None || !iEntity || !IsValidEntity(iEntity)
	|| (!(buttons & IN_USE) == !(buttons & IN_RELOAD)))
		return Plugin_Continue;

	if(g_eEntity[client].type == Type_RGB)
	{
		static ChangeRGB color; color = g_eEntity[client].color; // I don't even know if it is better
		static int iColor[4];
		GetEntDataArray(iEntity, g_iRenderClrOffset, iColor, 4, 1);

		if(buttons & IN_USE)	iColor[color]++;
		else 					iColor[color]--;

		if(iColor[color] < 1) iColor[color] = 1;
		else if (iColor[color] > 255) iColor[color] = 255;

		SetEntDataArray(iEntity, g_iRenderClrOffset, iColor, 4, 1);
	}
	else
	{
		static ChangePos axis; axis = g_eEntity[client].axis;
		static float fVec[3];
		if(g_eEntity[client].type == Type_Pos)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fVec);

			if(buttons & IN_USE)	fVec[axis]++;
			else 					fVec[axis]--;

			TeleportEntity(iEntity, fVec, NULL_VECTOR, NULL_VECTOR);
		}
		else if(g_eEntity[client].type == Type_Angles)
		{
			GetEntPropVector(iEntity, Prop_Send, "m_angRotation", fVec);

			if(buttons & IN_USE)		fVec[axis]++;
			else 						fVec[axis]--;

			if(FloatAbs(fVec[axis]) > 360)
				fVec[axis] = FloatFraction(fVec[axis]) + RoundToZero(fVec[axis]) % 360;

			SetEntPropVector(iEntity, Prop_Send, "m_angRotation", fVec);
		}
	}

	return Plugin_Continue;
}
