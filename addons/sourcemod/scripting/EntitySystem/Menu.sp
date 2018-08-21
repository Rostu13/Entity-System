stock void CreateEditMenu(int client)
{
	if(!g_bEditPosEntity[client] || !g_iEntityEdited[client] || !IsValidEntity(g_iEntityEdited[client])) return;

	Menu menu = new Menu(Edit_);
	menu.ExitBackButton = true;
	menu.ExitButton = false;

	char sDisplay[256];

	menu.AddItem(NULL_STRING, "Обновить\n ");

	FormatEx(sDisplay, sizeof sDisplay, "Редактируем: %s", g_TypePos[client] == Type_Pos ? "Позицию" : g_TypePos[client] == Type_Angles ? "Углы" : "");
	menu.AddItem(NULL_STRING, sDisplay);

	FormatEx(sDisplay, sizeof sDisplay, "Ось: %c\n ", GetClientAxisEdit(client));
	menu.AddItem(NULL_STRING, sDisplay);

	menu.AddItem(NULL_STRING, "Телепортироваться к энтити");
	menu.AddItem(NULL_STRING, "Телепортировать ко мне\n");

	menu.AddItem(NULL_STRING, "Сохранение/Удаление =>", ITEMDRAW_DISABLED);

	menu.AddItem(NULL_STRING, "Сохранить изменения");
	menu.AddItem(NULL_STRING, "Удалить изменения");

	float fVec[3];
	GetEntPropVector(g_iEntityEdited[client], Prop_Send, g_TypePos[client] == Type_Pos ? "m_vecOrigin" : "m_angRotation", fVec);
	//VERY BADDDD
	menu.SetTitle("Редактируем: %d\nТип: %s\n%s X : %.2f %s\n%s Y : %.2f %s\n%s Z : %.2f %s", g_iEntityEdited[client], g_sClassName[client],
	g_Axis[client] == Axis_X ? ">>" : "", fVec[0], g_Axis[client] == Axis_X ? "<<" : "",
	g_Axis[client] == Axis_Y ? ">>" : "", fVec[2], g_Axis[client] == Axis_Y ? "<<" : "",
	g_Axis[client] == Axis_Z ? ">>" : "", fVec[1], g_Axis[client] == Axis_Z ? "<<" : "" );

	menu.Display(client, MENU_TIME_FOREVER);
}

public int Edit_(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			if(param1 != MenuEnd_Selected && param1) g_bEditPosEntity[param1] = false;
			delete menu;
		}
		case MenuAction_Select:
		{
			switch(param2)
			{
				//Тип
				case 1:
				{
					g_TypePos[param1]++;
					if(g_TypePos[param1] > Type_Angles) g_TypePos[param1] = Type_Pos;
				}
				//Ось
				case 2:
				{
					switch(g_Axis[param1])
					{
						case Axis_X:	g_Axis[param1] = Axis_Y;
						case Axis_Y :	g_Axis[param1] = Axis_Z;
						default:		g_Axis[param1] = Axis_X;
					}
				}
				//К энтити
				case 3:	TeleportToEditEntity(param1);
				//Ко мне
				case 4:	TelepotEntityToClient(param1, g_iEntityEdited[param1]);
				// Сохранить
				case 6:	KVEditPosSave(param1);
				// Удалить
				case 7:	KVEditPosSave(param1, false);
			}
			CreateEditMenu(param1);
		}
		case MenuAction_Cancel:	if(param2 == MenuCancel_ExitBack) Forward_EndEditMenu(param1);
	}
}