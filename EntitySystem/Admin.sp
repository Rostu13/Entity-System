
public void OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);

    if (hTopMenu == g_hAdmin)
    {
        return;
    }
    g_hAdmin = hTopMenu;

    TopMenuObject hCategory = g_hAdmin.AddCategory(g_sAdminMenuCategory, Handler_Entity_System, "sm_entity_system", ADMFLAG_ROOT, "Управление энтити");

    if(hCategory != INVALID_TOPMENUOBJECT)
    {
        Forward_OnAdminMenuCreated(g_hAdmin,hCategory);
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