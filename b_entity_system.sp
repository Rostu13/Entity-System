#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <csgo_colors>

/* TODO
Из-за изменения ключа триггера (любого) сервер начинает вас ТПШить на нулевые координаты, и не важно, какой trigger_teleport вы заденете.
Fix ? - Сохранения координатов info_teleport_destrasction

Редактирование info_teleport_destraction + моделька чтобы более понимать.

Редактирование других энтити
Возможность сохранения своих изменения
*/

#undef REQUIRE_PLUGIN 
#include <adminmenu>

#pragma tabsize 0

public Plugin myinfo = 
{
	name = "Entity System [BETA]",
	author = "Rostu",
	description = "Управление энтити trigger_teleport ",
	version = "1.0",
	url = "https://vk.com/rostu13"
};

enum 
{
    Chat_WaitNone = -1,

    Chat_WaitKey,
    Chat_WaitAngles
};

TopMenu g_hAdmin;

Menu g_hEntityTeleportMenu;
int g_iEntityEdited[MAXPLAYERS + 1]; // Какую entity Администратор редактирует.

int g_iEntityDraw[MAXPLAYERS + 1];
bool g_bDisplay[MAXPLAYERS + 1];        //Включена ли подсветка триггера

ArrayList g_hBlockedEntity;
bool g_bShow[MAXPLAYERS + 1];

char g_sKeyEntity[MAXPLAYERS + 1][64];
int g_iChat[MAXPLAYERS + 1] = { -1, ...};

int g_iMoveEntity[MAXPLAYERS + 1];

//other
int g_Offset_m_fEffects;
#define EF_NODRAW 32

bool g_bLate;

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] sError, int iErrorMax)
{
	g_bLate = bLate;
}

public void OnPluginStart()
{
    g_hEntityTeleportMenu = new Menu(trigger_teleport_);

    RegConsoleCmd("sm_testlist",Cmd_Triggers);
	RegConsoleCmd("sm_print_trigger",Cmd_Print);
	//RegConsoleCmd("sm_tptrigger",Cmd_TpMe);

    AddCommandListener(CallBack, "say");
    AddCommandListener(CallBack, "say_team");
    AddCommandListener(CallBack, "say2");

	if ( (g_Offset_m_fEffects = FindSendPropInfo("CBaseEntity", "m_fEffects")) == -1)
		SetFailState("[Entity System] Could not find CBaseEntity:m_fEffects");

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
    }
}
public OnLibraryRemoved(const char[] szName)
{
    if (StrEqual(szName, "adminmenu"))
    {
        g_hAdmin = null;
    }
}
public Action CallBack(int iClient, const char[] command, int args)     
{     
   // PrintToChatAll("[%N] %d",iClient, g_bChat[iClient]);
    if (iClient > 0 && g_iChat[iClient] != Chat_WaitNone)
    {  
        char sText[64];  
        GetCmdArgString(sText, sizeof sText);  
        StripQuotes(sText);   

        if(g_iChat[iClient] == Chat_WaitKey)
        {
            strcopy(g_sKeyEntity[iClient],sizeof g_sKeyEntity, sText);	
            ChangeEntityKey(iClient);	
        }
        else if (g_iChat[iClient] == Chat_WaitAngles)
        {
            int iValue = StringToInt(sText);
            if(iValue >= 1 && iValue <= 90)
            {
                g_iMoveEntity[iClient] = iValue;
                CreateEditMenu(iClient);

                g_iChat[iClient] = Chat_WaitNone;
            }
        }
    }
    return Plugin_Continue;  
} 
public Action Cmd_Print(int iClient, int args)
{
	g_bShow[iClient] = !g_bShow[iClient];
	CGOPrintToChat(iClient,"Вы %s отображение инфы о триггере",g_bShow[iClient] ? "включили" : "выключили" );
}
/*
public Action Cmd_TpMe(int iClient, int args)
{
	float fPos[3];
    GetEntPropVector(iClient, Prop_Data, "m_vecOrigin", fPos); 
	
	TeleportEntity(785,fPos,NULL_VECTOR, NULL_VECTOR);
}
*/
public Action Cmd_Triggers(int iClient, int args)
{
    char sBuffer[64];
	CGOPrintToChatAll("%d",GetEntityCount());
    for (int entity = 168; entity <= GetEntityCount(); ++entity)
	{
		if ( !IsValidEdict(entity) )
		{
			PrintToConsole(iClient,"[%d]INVALID",entity);
			continue;
		}
        GetEdictClassname(entity, sBuffer, sizeof(sBuffer));
        PrintToConsole(iClient,"[%d] - %s",entity,sBuffer);
    }
}
public void OnMapStart()
{
    if(g_hBlockedEntity != null) delete g_hBlockedEntity;
    g_hBlockedEntity = new ArrayList();

    g_hEntityTeleportMenu.RemoveAllItems();
    g_hEntityTeleportMenu.SetTitle("Keys => На какой info_teleport_destination телепортирует триггер");
    g_hEntityTeleportMenu.ExitBackButton = true;
	
    CreateTimer(3.0, Timer_DelayEntity, _, TIMER_FLAG_NO_MAPCHANGE);
}
stock Action Timer_DelayEntity(Handle hTimer)
{
    char sBuffer[64];
    char sKey[16];
    char sInfo[32];

    for (int entity = MAXPLAYERS + 1; entity <= GetEntityCount(); ++entity)
	{
		if ( !IsValidEdict(entity) )
		{
			//CGOPrintToChatAll("[%d]INVALID",entity);
			continue;
		}
		
		GetEdictClassname(entity, sBuffer, sizeof(sBuffer));
		//CGOPrintToChatAll("[%d] [%s]",entity,sBuffer);
        if(strcmp(sBuffer,"trigger_teleport") != 0) 
        {
           // LogToFile("addons/entity.log","[%d][%s]",entity,sBuffer);
            continue;
        }

        GetEntPropString(entity,Prop_Data,"m_target",sKey,sizeof sKey); // keys for info_teleport_disctraction
        Format(sBuffer,sizeof sBuffer, "[%d] %s [%s]",entity,sBuffer,sKey);
        IntToString(entity,sInfo,sizeof sInfo);
        g_hEntityTeleportMenu.AddItem(sInfo,sBuffer);

        SDKHook(entity, SDKHook_StartTouch, OnTrigger_Start);
        SDKHook(entity, SDKHook_EndTouch, OnTrigger);
        SDKHook(entity, SDKHook_Touch, OnTrigger);
	}
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
	
    if(activator && activator <= MaxClients)
    {
        if(IsClientConnected(activator))
        {
			if(g_bShow[activator])
			CGOPrintToChat(activator, "[%N] %d [%d]",activator,entity,g_hBlockedEntity.FindValue(entity));
			
            if(IsFakeClient(activator) || g_hBlockedEntity.FindValue(entity) != -1)
            {
                return Plugin_Handled;
            }
        }
    }
   
    return Plugin_Continue;
}
public void OnClientPutIntServer(int iClient)
{
    g_bDisplay[iClient] = false;
    g_iChat[iClient] = Chat_WaitNone;
    g_iEntityDraw[iClient] = -1;
}
public void OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);

    if (hTopMenu == g_hAdmin)
    {
        return;
    }
    g_hAdmin = hTopMenu;

    TopMenuObject hCategory = g_hAdmin.AddCategory("entity_system", Handler_Entity_System, "sm_entity_system", ADMFLAG_ROOT, "Управление энтити");

    if(hCategory != INVALID_TOPMENUOBJECT)
    {
        g_hAdmin.AddItem("entity_system_teleport", Handler_Trigger_Teleport, hCategory, "trigger_teleport", ADMFLAG_ROOT, "Список trigger_teleport");
    }
}
public void Handler_Entity_System(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
    switch (action)
    {
        case TopMenuAction_DisplayOption:
        {
            FormatEx(sBuffer, maxlength, "Управление Entity");
        }
        case TopMenuAction_DisplayTitle:
        {
            FormatEx(sBuffer, maxlength, "Управление Entity");
        }
    }
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
        g_iEntityEdited[param1] = StringToInt(sEntity);
        TriggerTeleportEditMenu(param1);   
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        FakeClientCommand(param1, "sm_admin");
    }
}
void TriggerTeleportEditMenu (int iClient)
{
    char sClassName[32];
    char sKey[16];
    Menu menu = new Menu(trigger_teleport_edit_);
    menu.ExitBackButton = true;

    GetEdictClassname(g_iEntityEdited[iClient],sClassName,sizeof sClassName); // ClassName => trigger_teleport
    GetEntPropString(g_iEntityEdited[iClient],Prop_Data,"m_target",sKey,sizeof sKey); // Keytrigger => stage_2

    menu.SetTitle("Вы редактируете %d энтити\nИмя: %s\nКлюч: %s\nЧто хотите сделать?",g_iEntityEdited[iClient],sClassName,sKey);

    char sInfo[64];

    float fPos[3];
    GetEntPropVector(g_iEntityEdited[iClient], Prop_Data, "m_vecOrigin", fPos);
    FormatEx(sInfo,sizeof sInfo, "%.3f;%.3f;%.3f",fPos[0],fPos[1],fPos[2]);
    menu.AddItem(sInfo,"Телепортироваться");

    FormatEx(sInfo,sizeof sInfo,"Подсветка Entity [ %s ]",g_bDisplay[iClient] ? "Включена" : "Выключена");
    menu.AddItem("",sInfo);
    menu.AddItem("","Сменить key триггера");

    FormatEx(sInfo,sizeof sInfo, "Статус: %s", g_hBlockedEntity.FindValue(g_iEntityEdited[iClient]) == -1 ? "Включен" : "Выключен");
    menu.AddItem("",sInfo);

    menu.AddItem(NULL_STRING,"Расположение");

    menu.Display(iClient, MENU_TIME_FOREVER);
}
public int trigger_teleport_edit_(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End) delete menu;
    else if (action == MenuAction_Select)
    {
        switch(param2)
        {
            case 0: // Позиция [Телепортироваться]
            {
                char sInfo[64];
                char sResults[4][16];
                float fPos[3];
                menu.GetItem(param2,sInfo,sizeof sInfo);
                int dlen = ExplodeString(sInfo,";",sResults,sizeof sResults,sizeof(sResults[]), true);
                for(int x = 0; x< dlen;x++)
                {
                    TrimString(sResults[x]);
                    fPos[x] = StringToFloat(sResults[x]);
                }
                TeleportEntity(param1,fPos,NULL_VECTOR,NULL_VECTOR);
            }
            case 1: // Подсветить
            {
                g_bDisplay[param1] = !g_bDisplay[param1];
                SetClientDrawTrigger(param1, g_bDisplay[param1] ? g_iEntityEdited[param1] : -1);
                CGOPrintToChat(param1, "Вы успешно %s подсветку %d энтити",g_bDisplay[param1] ? "включили" : "выключили",g_iEntityEdited[param1]);
            }
            case 2: // Сменить Key
            {
                g_iChat[param1] = Chat_WaitKey;
                g_sKeyEntity[param1][0] = 0;
                ChangeEntityKey(param1);
                return 0;
            }
            case 3: // Смена статуса
            {
                int index = g_hBlockedEntity.FindValue(g_iEntityEdited[param1]);
                if(index != -1) g_hBlockedEntity.Erase(index);
				else g_hBlockedEntity.Push(g_iEntityEdited[param1]);

                CGOPrintToChat(param1, "Вы успешно %s энтити %d",index == -1 ? "Выключили" : "Включили", g_iEntityEdited[param1]);
            }
            case 4: // Расположение
            {
                g_iMoveEntity[param1] = 1;
                CreateEditMenu(param1);
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
stock void ChangeEntityKey(int iClient)
{
    static char sKey[64];
    GetEntPropString(g_iEntityEdited[iClient],Prop_Data,"m_target",sKey,sizeof sKey);

    if(!g_sKeyEntity[iClient][0])  strcopy(g_sKeyEntity[iClient],sizeof g_sKeyEntity, sKey);

    bool bOld = (strcmp(sKey,g_sKeyEntity[iClient]) == 0);

    Menu menu = new Menu(Key_);
    menu.SetTitle("Смена ключа энтити:\nId: %d\nКлюч сейчас: %s\nВаш ключ: %s", g_iEntityEdited[iClient], sKey, g_sKeyEntity[iClient] );

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
stock void CreateEditMenu(int iClient, bool bNext = false)
{
	Menu menu = new Menu(Edit_);
    menu.ExitBackButton = true;
    
    float fPos[3];
	GetEntPropVector(g_iEntityEdited[iClient], Prop_Send, "m_vecOrigin", fPos);

    float fRotateVec[3];
	GetEntPropVector(g_iEntityEdited[iClient], Prop_Send, "m_angRotation", fRotateVec);
	//RotateVec[0] = 90.0;

	menu.SetTitle("%d - редактируете\nКоординаты:\n1: %.2f\n 2: %.2f\n3: %.2f\nУглы\n1: %.2f\n2: %.2f\n3: %.2f",g_iEntityEdited[iClient], fPos[0], fPos[1], fPos[2],fRotateVec[0],fRotateVec[1],fRotateVec[2]);

    char sInfo[16];
    char sDisplay[16];

    char sSymbol[2];
    for(int x = 0; x < 3;x++)
    {
        sSymbol[0] = x == 0 ? 'X' : x == 1 ? 'Y' : 'Z';

        FormatEx(sInfo,sizeof sInfo, "%d%c",g_iMoveEntity[iClient], sSymbol[0]);
        FormatEx(sDisplay, sizeof sDisplay, "%d %c", g_iMoveEntity[iClient], sSymbol[0]);
        menu.AddItem(sInfo, sDisplay);

        FormatEx(sInfo,sizeof sInfo, "%d%c",-g_iMoveEntity[iClient], sSymbol[0]);
        FormatEx(sDisplay, sizeof sDisplay, "%d %c", -g_iMoveEntity[iClient], sSymbol[0]);
        menu.AddItem(sInfo, sDisplay);
    }
    /*
    menu.AddItem("1x"	, "+1 X");
    menu.AddItem("-1x"	, "-1 X");

    menu.AddItem("1y"	, "+1 Y");
    menu.AddItem("-1y"	, "-1 Y");

    menu.AddItem("1z", "+1 Z");
    menu.AddItem("-1z", "-1 Z");
    */

    menu.AddItem(NULL_STRING,"Настройка перемешения энтити\n ");

    FormatEx(sInfo, sizeof sInfo, "%d", g_iMoveEntity[iClient]);
    FormatEx(sDisplay,sizeof sDisplay, "+ %d градусов", g_iMoveEntity[iClient]);
    menu.AddItem(sInfo, sDisplay);

    FormatEx(sInfo, sizeof sInfo, "%d", -g_iMoveEntity[iClient]);
    FormatEx(sDisplay,sizeof sDisplay, "- %d градусов",g_iMoveEntity[iClient]);
    menu.AddItem(sInfo, sDisplay);

    if(bNext)
    {
        menu.DisplayAt(iClient, 6, MENU_TIME_FOREVER);
    }
    else
    {
	    menu.Display(iClient, MENU_TIME_FOREVER);
    }
}
public int Edit_ (Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End) delete menu;
	else if(action == MenuAction_Select)
	{
        char sInfo[8];
		menu.GetItem(param2, sInfo,sizeof sInfo);

        if(param2 == 6)
        {
            g_iChat[param1] = Chat_WaitAngles;
            CreateEditMoveEntityMenu(param1);
        }
        else if(param2 > 6)
        {
            int iValue = StringToInt(sInfo);

            float fRotateVec[3];
	        GetEntPropVector(g_iEntityEdited[param1], Prop_Send, "m_angRotation", fRotateVec);

            fRotateVec[0] += iValue;
            
            if(fRotateVec[0] > 360.0) fRotateVec[0] = 360.0;
            else if (fRotateVec[0] < -360.0) fRotateVec[0] = -360.0;

            SetEntPropVector(g_iEntityEdited[param1], Prop_Send, "m_angRotation", fRotateVec); 

            CreateEditMenu(param1, true);
            return 0;
        }
        

		int iLen = strlen(sInfo);

		char sSymbol[2];
		sSymbol[0] = sInfo[iLen - 1];
		sInfo[iLen - 1] = 0;

		int iInfo = StringToInt(sInfo);

		float fPos[3];
		GetEntPropVector(g_iEntityEdited[param1], Prop_Send, "m_vecOrigin", fPos);

		switch(sSymbol[0])
		{
			case 'X':
			{
				fPos[0] += iInfo;
			}
			case 'Y':
			{
				fPos[2] += iInfo;
			}
			case 'Z':
			{
				fPos[1] += iInfo;
			}
		}

		TeleportEntity(g_iEntityEdited[param1], fPos, NULL_VECTOR, NULL_VECTOR);
		CreateEditMenu(param1);
	}
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        TriggerTeleportEditMenu(param1);
    }
	return 0;
}
stock void CreateEditMoveEntityMenu(int iClient)
{
    static Menu menu;

    if(menu == null)
    {
        menu = new Menu(EditMove_);
        menu.SetTitle("Напишите в чат число [1 - 90] для установления перемещения энтити");
        menu.AddItem(NULL_STRING,"Назад");
        menu.ExitButton = false;
    }

    menu.Display(iClient, MENU_TIME_FOREVER);
}
public int EditMove_ (Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_Select)
	{
        CreateEditMenu(param1);
    }
}

//https://forums.alliedmods.net/showthread.php?p=2470255
stock void SetClientDrawTrigger(int iClient, int entity)
{
	int effectFlags = GetEntData(entity, g_Offset_m_fEffects);
	int edictFlags = GetEdictFlags(entity);
	
	// Determine whether to transmit or not
	if (entity != -1) {
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
	if (entity != -1)
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	else
		SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

	g_iEntityDraw[iClient]=  entity;
}

public Action Hook_SetTransmit(int entity, int client)
{
	if(g_iEntityDraw[client] == entity) return Plugin_Continue;
	
	return Plugin_Handled;

}