stock void CreateEditMenu(int client)
{
	if(g_Type[client] == EditType_None || !g_iEntityEdited[client] || !IsValidEntity(g_iEntityEdited[client])) return;

	Menu menu = new Menu(Edit_);
	menu.ExitBackButton = true;
	menu.ExitButton = false;

	menu.SetTitle("Редактируем: %d [%s]\n%s", g_iEntityEdited[client], g_sClassName[client], CreateTitleEditMenu(client));

	char sDisplay[64];

	menu.AddItem(NULL_STRING, "Обновить\n ");

	FormatEx(sDisplay, sizeof sDisplay, "Редактируем: %s", g_sRedact[g_TypePos[client]]);
	menu.AddItem(NULL_STRING, sDisplay);

	FormatEx(sDisplay, sizeof sDisplay, "%s: %s\n ", 
	g_TypePos[client] == Type_RGB ? "Цвет" : "Ось", GetClientItemEdit(client));

	/* ??77?7??
	[SM] Exception reported: Heap leak detected: hp:12220 should be 12216!
	g_TypePos[client] == Type_RGB ? g_sChangeRGB[ g_Color[client] ] : GetClientAxisEdit(client) );  => GetClientItemEdit(client)
	*/

	menu.AddItem(NULL_STRING, sDisplay);
	

	menu.AddItem(NULL_STRING, "Телепортироваться к энтити");
	menu.AddItem(NULL_STRING, "Телепортировать ко мне\n");

	menu.AddItem(NULL_STRING, "Сохранение/Удаление =>", ITEMDRAW_DISABLED);

	menu.AddItem(NULL_STRING, "Сохранить изменения");
	menu.AddItem(NULL_STRING, "Удалить изменения");
	

	menu.Display(client, MENU_TIME_FOREVER);
}
stock void CreateCustomEditMenu(int client)
{
	if(g_Type[client] != EditType_Custom || !g_iEntityEdited[client] || !IsValidEntity(g_iEntityEdited[client])) return;

	Menu menu = new Menu(EditCustom_);
	menu.ExitBackButton = true;
	menu.ExitButton = false;

	menu.SetTitle("Редактируем: %d [%s]\nТип: %s\nСейчас: %d [ %d:%d ]", 
	g_iEntityEdited[client], g_sClassName[client], g_sCustomName[client],g_iCustomCurrent[client], g_iCustomSettings[Settings_MIN],g_iCustomSettings[Settings_MAX]);

	menu.AddItem("1", 		"+ 1");
	menu.AddItem("10", 		"+ 10");
	menu.AddItem("100", 	"+ 100");
	menu.AddItem("-1", 		"- 1");
	menu.AddItem("-10", 	"- 10");
	menu.AddItem("-100", 	"- 100\nСохранение=>");

	menu.AddItem("s", "Сохранить");

	menu.Display(client, MENU_TIME_FOREVER);
	
}
public int EditCustom_(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:	menu.Close();
		case MenuAction_Select:
		{
			char sInfo[8];
			menu.GetItem(param2, sInfo, sizeof sInfo);

			if(sInfo[0] == 's')
			{
				g_Type[param1] = EditType_None;
				Forward_EndEditMenu(param1, true, true, g_iCustomCurrent[param1]);

				return 0;
			}

			int iValue = StringToInt(sInfo);
			g_iCustomCurrent[param1] += iValue;

			if(			g_iCustomCurrent[param1] < g_iCustomSettings[param1][Settings_MIN]) g_iCustomCurrent[param1] = g_iCustomSettings[param1][Settings_MIN];
			else if (	g_iCustomCurrent[param1] > g_iCustomSettings[param1][Settings_MAX])	g_iCustomCurrent[param1] = g_iCustomSettings[param1][Settings_MIN];

			CreateCustomEditMenu(param1);
		}
		case MenuAction_Cancel: if(param2 == MenuCancel_ExitBack) 	Forward_EndEditMenu(param1, true);
	}
	return 0;
}
public int Edit_(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:	menu.Close();
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 1:
				{
					g_TypePos[param1]++;
					if(g_TypePos[param1] >= Type_MAX) g_TypePos[param1] = Type_Pos;
				}
				case 2:
				{
					if(g_TypePos[param1] == Type_RGB)
					{
						g_Color[param1]++;
						if(g_Color[param1] > Color_Blue) g_Color[param1] = Color_Red;
					}
					else
					{
						switch(g_Axis[param1])
						{
							case Axis_X:	g_Axis[param1] = Axis_Y;
							case Axis_Y :	g_Axis[param1] = Axis_Z;
							default:		g_Axis[param1] = Axis_X;
						}
					}
				}
				case 3:	TeleportToEditEntity(param1);
				case 4:	TelepotEntityToClient(param1, g_iEntityEdited[param1]);
				case 6:	KVEditSave(param1);
				case 7:	KVEditSave(param1, false);
			}
			CreateEditMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				g_Type[param1] = EditType_None;
				Forward_EndEditMenu(param1);
			}
		}
	}
}