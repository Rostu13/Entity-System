stock void CreateEditMenu(int iClient)
{
    if(!g_bEditPosEntity[iClient] || !g_iEntityEdited[iClient] || !IsValidEntity(g_iEntityEdited[iClient])) return;

    Menu menu = new Menu(Edit_);
    menu.ExitBackButton = true;
    menu.ExitButton = false;

    char sDisplay[256];

    menu.AddItem(NULL_STRING, "Обновить\n ");

    FormatEx(sDisplay, sizeof sDisplay, "Редактируем: %s", g_TypePos[iClient] == Type_Pos ? "Позицию" : g_TypePos[iClient] == Type_Angles ? "Углы" : "");
    menu.AddItem(NULL_STRING, sDisplay);

    FormatEx(sDisplay, sizeof sDisplay, "Ось: %c\n ",GetClientAxisEdit(iClient));
    menu.AddItem(NULL_STRING, sDisplay);

    menu.AddItem(NULL_STRING, "Телепортироваться к энтити");
    menu.AddItem(NULL_STRING, "Телепортировать ко мне");

    float fVec[3];
    GetEntPropVector(g_iEntityEdited[iClient], Prop_Send, g_TypePos[iClient] == Type_Pos ? "m_vecOrigin" : "m_angRotation", fVec);
    //VERY BADDDD
    menu.SetTitle("Редактируем: %d\nТип: %s\n%s X : %.2f %s\n%s Y : %.2f %s\n%s Z : %.2f %s", g_iEntityEdited[iClient], g_sClassName[iClient],
    g_Axis[iClient] == Axis_X ? ">>" : "", fVec[0], g_Axis[iClient] == Axis_X ? "<<" : "",
    g_Axis[iClient] == Axis_Y ? ">>" : "", fVec[2], g_Axis[iClient] == Axis_Y ? "<<" : "",
    g_Axis[iClient] == Axis_Z ? ">>" : "", fVec[1], g_Axis[iClient] == Axis_Z ? "<<" : "" );

    menu.Display(iClient, MENU_TIME_FOREVER);
}
public int Edit_(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End)
    {
        if(param1 != MenuEnd_Selected) g_bEditPosEntity[param1] = false;

        delete menu;
    }
    else if(action == MenuAction_Select)
    {
        switch(param2)
        {
            case 1: // Тип
            {
                g_TypePos[param1]++;

                if(g_TypePos[param1] > Type_Angles) g_TypePos[param1] = Type_Pos;
            }
            case 2:// Ось
            {
                switch(g_Axis[param1])
                {
                    case Axis_X:        g_Axis[param1] = Axis_Y;
                    case Axis_Y :       g_Axis[param1] = Axis_Z;
                    default:            g_Axis[param1] = Axis_X;
                }
            }
            case 3: // К энтити
            {
                TeleportToEditEntity(param1);
            }
            case 4: // Ко мне
            {
                TelepotEntityToClient(param1,g_iEntityEdited[param1]);
            }
        }
        CreateEditMenu(param1);
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        Forward_EndEditMenu(param1);
    }
}