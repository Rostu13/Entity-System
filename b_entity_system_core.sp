#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <csgo_colors>
#include <entity_system>

#undef REQUIRE_PLUGIN 
#include <adminmenu>

#pragma tabsize 0

public Plugin myinfo = 
{
	name = "Entity System Core",
	author = "Rostu",
	description = "Ядро для управления Entity сервера ",
	version = "2.0",
	url = "https://vk.com/rostu13"
};
/*
static const char g_sEntityType[][] = 
{
    "trigger_teleport",
    "info_teleport_destination",
    "ambient_generic"
}

static const char g_sModelInfoTeleport[][] = 
{
    "materials/Editor/gray.vmt",
    "materials/Editor/gray.vtf",
    "materials/Editor/orange.vmt",
    "materials/Editor/orange.vtf",
    "models/Player/ct_urban.dx80.vtx",
    "models/Player/ct_urban.dx90.vtx",
    "models/Player/ct_urban.phy",
    "models/Player/ct_urban.sw.vtx",
    "models/Player/ct_urban.vvd",
    "models/Player/ct_urban.mdl"
};
*/
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

int g_iEntityEdited[MAXPLAYERS + 1]; // Какую entity Администратор редактирует.
bool g_bEditPosEntity[MAXPLAYERS + 1];

ArrayList g_hRegisteredTypes;

bool g_bLate;
bool g_bLoaded;

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

    if (LibraryExists("adminmenu"))
    {
        TopMenu hTopMenu;
        if ((hTopMenu = GetAdminTopMenu()) != null)
        {
            OnAdminMenuReady(hTopMenu);
        }
    }
    if(g_bLate)
    {
        for(int x = 1; x<= MaxClients;x++)
        {
            if(IsClientInGame(x) && !IsFakeClient(x))
            {
                OnClientPutIntServer(x);
            }
        }
		
		ServerCommand("sm plugins reload adminmenu");
    }
    
    Forward_RequestType();
    g_bLoaded = true;
}

public OnLibraryRemoved(const char[] szName)
{
    if (StrEqual(szName, "adminmenu"))
    {
        g_hAdmin = null;
    }
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
		if ( !IsValidEdict(entity) )
		{
			continue;
		}
		
		GetEdictClassname(entity, sClassName, sizeof sClassName);

        if(g_hRegisteredTypes.FindString(sClassName) == -1)
        {
            continue;
        }

        Forward_OnEntityRegister(entity, sClassName);
	}
}
public void OnClientPutIntServer(int iClient)
{
    g_bEditPosEntity[iClient] = false;
    g_iEntityEdited[iClient] = 0;
}
public Action Cmd_EditMenu(int iClient, int iArgs)
{
    CreateEditMenu(iClient);
}
public Action OnPlayerRunCmd(int iClient, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if(!g_bEditPosEntity[iClient] || !g_iEntityEdited[iClient] || !IsValidEntity(g_iEntityEdited[iClient])) return Plugin_Continue;

    if(buttons & IN_USE || (buttons & IN_RELOAD))
    {
        if(g_TypePos[iClient] == Type_Pos)
        {
            static float fPos[3];
		    GetEntPropVector(g_iEntityEdited[iClient], Prop_Send, "m_vecOrigin", fPos);

            if(buttons & IN_USE && !(buttons & IN_RELOAD))
            {
                fPos[g_Axis[iClient]]++;
            }
            else if( !(buttons & IN_USE) && buttons & IN_RELOAD)
            {
                fPos[g_Axis[iClient]]--;
            }

            TeleportEntity(g_iEntityEdited[iClient], fPos, NULL_VECTOR, NULL_VECTOR);
        }
        else if(g_TypePos[iClient] == Type_Angles)
        {
            static float fRotateVec[3];
            GetEntPropVector(g_iEntityEdited[iClient], Prop_Send, "m_angRotation", fRotateVec);

            if(buttons & IN_USE && !(buttons & IN_RELOAD))
            {
                fRotateVec[g_Axis[iClient]]++;
            }
            else if( !(buttons & IN_USE) && buttons & IN_RELOAD)
            {
                fRotateVec[g_Axis[iClient]]--;
            }

            if(fRotateVec[g_Axis[iClient]] > 360.0)          fRotateVec[g_Axis[iClient]] =   360.0;
            else if (fRotateVec[g_Axis[iClient]] < -360.0) fRotateVec[g_Axis[iClient]]  =   -360.0;

            SetEntPropVector(g_iEntityEdited[iClient], Prop_Send, "m_angRotation", fRotateVec); 
        }
    }
    return Plugin_Continue;
}

stock void TeleportToEditEntity(int iClient)
{
    float fPos[3];
    GetEntPropVector(g_iEntityEdited[iClient], Prop_Data, "m_vecOrigin", fPos);

    TeleportEntity(iClient,fPos,NULL_VECTOR,NULL_VECTOR);
}
stock char GetClientAxisEdit(int iClient)
{
    if(     g_Axis[iClient] == Axis_X) return 'X';
    else if(g_Axis[iClient] == Axis_Y) return 'Y';
    else if(g_Axis[iClient] == Axis_Z) return 'Z';

    return ' ';
}
