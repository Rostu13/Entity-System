
public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);
	if (hTopMenu == g_hAdmin) return;
	g_hAdmin = hTopMenu;

	TopMenuObject hCategory = g_hAdmin.AddCategory(g_sAdminMenuCategory, Handler_Entity_System, "sm_entity_system", ADMFLAG_ROOT, "Управление энтити");

	if(hCategory != INVALID_TOPMENUOBJECT) 
	{
		g_hAdmin.AddItem("entity_system_reload", Handler_Reload, hCategory, "trigger_teleport", ADMFLAG_ROOT, "Перезагрузить список Entity");
		Forward_OnAdminMenuCreated(g_hAdmin,hCategory);
	}
}
public void Handler_Entity_System(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption, TopMenuAction_DisplayTitle: FormatEx(sBuffer, maxlength, "Управление Entity");
	}
}
public void Handler_Reload (TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
    switch(action)
    {
        case TopMenuAction_DisplayOption:
        {
            FormatEx(sBuffer,maxlength,"Перезагрузить список Entity\n ");
        }
        case TopMenuAction_SelectOption:
        {
            PrintToChat(iClient, "Вы успешно запустили перезагрузку списка Entity");
			OnMapStart();
        }
    }
}