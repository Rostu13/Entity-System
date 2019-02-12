
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <csgo_colors>

#undef REQUIRE_PLUGIN 
#include <adminmenu>

#include <entity_system>

public Plugin myinfo = 
{
	name = "[Entity System] Trigger_",
	author = "Rostu",
	description = "Модуль для управления Entity с классом trigger_ ",
	version = "1.4",
	url = "https://vk.com/rostu13"
};

static const char g_sEntityClassName[] = "trigger_teleport";

Menu g_hEntityTeleportMenu;

int g_iEntityDraw[MAXPLAYERS + 1];
bool g_bDisplay[MAXPLAYERS + 1];        //Включена ли подсветка триггера

ArrayList g_hBlockedEntity;
bool g_bShow[MAXPLAYERS + 1];

//char g_sKeyEntity[MAXPLAYERS + 1][64];
//int g_iChat[MAXPLAYERS + 1] = { -1, ...};


//other
int g_Offset_m_fEffects;
#define EF_NODRAW 32

public void OnPluginStart()
{
	g_hEntityTeleportMenu = new Menu(trigger_teleport_);

	HookEvent("round_start", Event_Start);

	RegConsoleCmd("sm_print_trigger",Cmd_Print);

	if ( (g_Offset_m_fEffects = FindSendPropInfo("CBaseEntity", "m_fEffects")) == -1)
		SetFailState("[Entity System] Could not find CBaseEntity:m_fEffects");

    if(LibraryExists( "entity_system" ))
	{
		TopMenu hAdmin = view_as<TopMenu>(Entity_GetAdminMenuHandle());
	    if(hAdmin == null)  return;

        TopMenuObject hCategory = hAdmin.FindCategory(g_sAdminMenuCategory);
	    if(hCategory != INVALID_TOPMENUOBJECT)  Entity_OnAdminMenuCreated(hAdmin, hCategory);
	}	
}
public void Entity_RequestType(ArrayList hList)
{
    hList.PushString(g_sEntityClassName);

    if(g_hBlockedEntity != null) g_hBlockedEntity.Close();
    g_hBlockedEntity = new ArrayList();

    g_hEntityTeleportMenu.RemoveAllItems();
    g_hEntityTeleportMenu.SetTitle("Keys => На какой info_teleport_destination телепортирует триггер");
    g_hEntityTeleportMenu.ExitBackButton = true;
}

public Action Cmd_Print(int iClient, int args)
{
	g_bShow[iClient] = !g_bShow[iClient];
	CGOPrintToChat(iClient,"Вы %s отображение информации о триггере",g_bShow[iClient] ? "включили" : "выключили" );
}
public void OnClientPutInServer(int iClient)
{
    g_bDisplay[iClient] = false;
    g_iEntityDraw[iClient] = -1;
}

public void Event_Start(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	char sClassName[64];

	for (int iEntity = MAXPLAYERS + 1; iEntity <= GetEntityCount(); ++iEntity)
	{
		if(!IsValidEdict(iEntity)) continue;

		GetEdictClassname(iEntity, sClassName, sizeof sClassName);

		if(strcmp(sClassName, g_sEntityClassName) != 0) continue;
        HookTrigger(iEntity);
	}
}
stock void HookTrigger(int iEntity)
{
    SDKHook(iEntity, SDKHook_StartTouch, OnTrigger_Start);
    SDKHook(iEntity, SDKHook_EndTouch, OnTrigger);
    SDKHook(iEntity, SDKHook_Touch, OnTrigger);
}
public void Entity_OnAdminMenuCreated(TopMenu hAdmin, TopMenuObject hCategory)
{
    hAdmin.AddItem("entity_system_teleport", Handler_Trigger_Teleport, hCategory, "trigger_teleport", ADMFLAG_ROOT, "Список trigger_teleport");
}
public void Handler_Trigger_Teleport (TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
    switch(action)
    {
        case TopMenuAction_DisplayOption:
        {
            FormatEx(sBuffer,maxlength,"Список trigger_teleport");
        }
        case TopMenuAction_SelectOption:
        {
            g_hEntityTeleportMenu.Display(iClient, MENU_TIME_FOREVER);
        }
    }
}

public int trigger_teleport_(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_Select)
    {
        char sEntity[8];
        menu.GetItem(param2,sEntity,sizeof sEntity);

        Entity_SetClientEditEntity(param1, StringToInt(sEntity));
        
        TriggerTeleportEditMenu(param1);   
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        FakeClientCommand(param1, "sm_admin");
    }
}
public void Entity_OnEntityRegister(int iEntity, char[] sClassName, bool bEdit, KeyValues kv)
{
	if(strcmp(sClassName, g_sEntityClassName) != 0) return;
    
	char sKey[32];
	char sInfo[8];

	GetEntPropString(iEntity,Prop_Data,"m_target",sKey,sizeof sKey); // keys for info_teleport_disctraction
	Format(sClassName,128, "[%d] %s [%s]",iEntity,sClassName,sKey);
	IntToString(iEntity,sInfo,sizeof sInfo);
	g_hEntityTeleportMenu.AddItem(sInfo,sClassName);

    HookTrigger(iEntity);
}

public Action OnTrigger(int entity, int activator)
{
    if(activator && activator <= MaxClients)
    {
        if(IsClientConnected(activator))
        {			
            if(IsFakeClient(activator) || g_hBlockedEntity.FindValue(entity) != -1)
            {
                return Plugin_Handled;
            }
        }
    }
   
    return Plugin_Continue;
}
public Action OnTrigger_Start(int entity, int activator)
{
    static int iFindIndex;
    if(activator && activator <= MaxClients)
    {
		if(IsClientConnected(activator))
		{
            iFindIndex = g_hBlockedEntity.FindValue(entity);

			if(g_bShow[activator])
			CGOPrintToChat(activator, "[%N] %d [%d] [%d]",activator,entity,iFindIndex, GetEntProp(entity, Prop_Data, "m_iHammerID"));
			
			if(IsFakeClient(activator) || iFindIndex != -1)
			{
				return Plugin_Handled;
			}
		}
    }
   
    return Plugin_Continue;
}

void TriggerTeleportEditMenu (int iClient)
{
    char sClassName[32];
    char sKey[16];
    Menu menu = new Menu(trigger_teleport_edit_);
    menu.ExitBackButton = true;

    int iEntity = Entity_GetClientEditEntity(iClient);

    GetEdictClassname(iEntity,sClassName,sizeof sClassName); // ClassName => trigger_teleport
    GetEntPropString(iEntity,Prop_Data,"m_target",sKey,sizeof sKey); // Keytrigger => stage_2

    menu.SetTitle("Вы редактируете %d энтити\nИмя: %s\nКлюч: %s\nЧто хотите сделать?",iEntity,sClassName,sKey);

    char sInfo[64];

    menu.AddItem(sInfo,"Телепортироваться");

    FormatEx(sInfo,sizeof sInfo,"Подсветка Entity [ %s ]",g_bDisplay[iClient] ? "Включена" : "Выключена");
    menu.AddItem("",sInfo);
    menu.AddItem("","Сменить key триггера", ITEMDRAW_DISABLED);

    FormatEx(sInfo,sizeof sInfo, "Статус: %s", g_hBlockedEntity.FindValue(iEntity) == -1 ? "Включен" : "Выключен");
    menu.AddItem("",sInfo);

    menu.AddItem(NULL_STRING,"Расположение");

    menu.Display(iClient, MENU_TIME_FOREVER);
}
public int trigger_teleport_edit_(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End) menu.Close();
    else if (action == MenuAction_Select)
    {
		int iEntity = Entity_GetClientEditEntity(param1);
		switch(param2)
		{
			case 0: // Позиция [Телепортироваться]
			{
				Entity_TeleportToEditEntity(param1);
			}
			case 1: // Подсветить
			{
				g_bDisplay[param1] = !g_bDisplay[param1];
				SetClientDrawTrigger(param1, iEntity, g_bDisplay[param1]);
				CGOPrintToChat(param1, "Вы успешно %s подсветку %d энтити",g_bDisplay[param1] ? "включили" : "выключили",iEntity);
			}
			case 2: // Сменить Key
			{
				/*
				g_iChat[param1] = Chat_WaitKey;
				g_sKeyEntity[param1][0] = 0;
				ChangeEntityKey(param1);
				*/
				return 0;
			}
			case 3: // Смена статуса
			{
				int index = g_hBlockedEntity.FindValue(iEntity);
				if(index != -1) g_hBlockedEntity.Erase(index);
				else g_hBlockedEntity.Push(iEntity);

				CGOPrintToChat(param1, "Вы успешно %s энтити %d",index == -1 ? "Выключили" : "Включили", iEntity);
			}
			case 4: // Расположение
			{
				Entity_OpenEditMenu(param1);
				return 0;
			}
        }
		TriggerTeleportEditMenu(param1);
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        g_hEntityTeleportMenu.Display(param1, MENU_TIME_FOREVER);
    }
    return 0;
}
public void Entity_EndEditMenu(int iClient, char[] sClassName, bool bCustom, bool bSave, int iValue)
{
    if(strcmp(sClassName, g_sEntityClassName) == 0)
        TriggerTeleportEditMenu(iClient);
}

/*
stock void ChangeEntityKey(int iClient)
{
    static char sKey[64];
    int iEntity = Entity_GetClientEditEntity(iClient);
    GetEntPropString(iEntity,Prop_Data,"m_target",sKey,sizeof sKey);

    if(!g_sKeyEntity[iClient][0])  strcopy(g_sKeyEntity[iClient],sizeof g_sKeyEntity, sKey);

    bool bOld = (strcmp(sKey,g_sKeyEntity[iClient]) == 0);

    Menu menu = new Menu(Key_);
    menu.SetTitle("Смена ключа энтити:\nId: %d\nКлюч сейчас: %s\nВаш ключ: %s", iEntity, sKey, g_sKeyEntity[iClient] );

    menu.AddItem(NULL_STRING, "Сохранить", bOld ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem(NULL_STRING, "Назад");

    menu.Display(iClient, MENU_TIME_FOREVER);
}
public int Key_(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End) delete menu;
    else if (action == MenuAction_Select)
    {
        if(!param2)
        {
            //char sResult[32];
           // Entity_GetKeyValue(g_iEntityEdited[param1],"Name",sResult,sizeof sResult);
           //DispatchKeyValue(g_iEntityEdited[param1], "Name",g_sKeyEntity[param1]  );
           // PrintToChatAll(" gg %s",g_sKeyEntity[param1],g_sKeyEntity[param1]);
            SetEntPropString(g_iEntityEdited[param1],Prop_Data,"m_target",g_sKeyEntity[param1]); // Смена ключа
        }

        g_iChat[param1] = Chat_WaitNone;
        TriggerTeleportEditMenu(param1);
    }
}
*/

//https://forums.alliedmods.net/showthread.php?p=2470255
stock void SetClientDrawTrigger(int iClient, int entity, bool bDraw)
{
	int effectFlags = GetEntData(entity, g_Offset_m_fEffects);
	int edictFlags = GetEdictFlags(entity);
	
	// Determine whether to transmit or not
	if (bDraw) {
		effectFlags &= ~EF_NODRAW;
		edictFlags &= ~FL_EDICT_DONTSEND;
	} else {
		effectFlags |= EF_NODRAW;
		edictFlags |= FL_EDICT_DONTSEND;
	}
	
	// Apply state changes
	SetEntData(entity, g_Offset_m_fEffects, effectFlags);
	ChangeEdictState(entity, g_Offset_m_fEffects);
	SetEdictFlags(entity, edictFlags);
	
	// Should we hook?
	if (bDraw)
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	else
		SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

	g_iEntityDraw[iClient]=  bDraw ? entity : -1;
}

public Action Hook_SetTransmit(int entity, int client)
{
	if(g_iEntityDraw[client] == entity) return Plugin_Continue;
	
	return Plugin_Handled;

}