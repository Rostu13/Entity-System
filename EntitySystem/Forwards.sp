stock void Forward_RequestType()
{
	static Handle hForwardRequestType;

	if(hForwardRequestType == null) hForwardRequestType = CreateGlobalForward("Entity_RequestType", ET_Ignore);

	Call_StartForward(hForwardRequestType);
	Call_Finish();
}

stock void Forward_OnAdminMenuCreated(TopMenu hMenu, TopMenuObject hCategory)
{
	static Handle hForwardOnAdminMenuCreated;
	if(hForwardOnAdminMenuCreated == null)
		hForwardOnAdminMenuCreated = CreateGlobalForward("Entity_OnAdminMenuCreated", ET_Ignore, Param_Cell, Param_Cell);

	Call_StartForward(hForwardOnAdminMenuCreated);
	Call_PushCell(hMenu);
	Call_PushCell(hCategory);
	Call_Finish();
}

stock void Forward_EndEditMenu(int iClient)
{
	static Handle hForwardEndEditMenu;
	if(hForwardEndEditMenu == null)
		hForwardEndEditMenu = CreateGlobalForward("Entity_EndEditMenu", ET_Ignore, Param_Cell, Param_String);

	Call_StartForward(hForwardEndEditMenu);
	Call_PushCell(iClient);
	Call_PushString(g_sClassName[iClient]);
	Call_Finish();
}

stock void Forward_OnEntityRegister(int iEntity, char[] sClassName)
{
	static Handle hForwardOnEntityRegister;
	if(hForwardOnEntityRegister == null)
		hForwardOnEntityRegister = CreateGlobalForward("Entity_OnEntityRegister", ET_Ignore, Param_Cell, Param_String);

	Call_StartForward(hForwardOnEntityRegister);
	Call_PushCell(iEntity);
	Call_PushString(sClassName);
	Call_Finish();
}