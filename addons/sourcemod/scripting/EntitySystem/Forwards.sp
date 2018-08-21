stock void Forward_RequestType()
{
	static Handle hForward;

	if(hForward == null) 
		hForward = CreateGlobalForward("Entity_RequestType", ET_Ignore);

	Call_StartForward(hForward);
	Call_Finish();
}

stock void Forward_OnAdminMenuCreated(TopMenu hMenu, TopMenuObject hCategory)
{
	static Handle hForward;

	if(hForward == null)
		hForward = CreateGlobalForward("Entity_OnAdminMenuCreated", ET_Ignore, Param_Cell, Param_Cell);

	Call_StartForward(hForward);
	Call_PushCell(hMenu);
	Call_PushCell(hCategory);
	Call_Finish();
}

stock void Forward_EndEditMenu(int client)
{
	static Handle hForward;
	if(hForward == null)
		hForward = CreateGlobalForward("Entity_EndEditMenu", ET_Ignore, Param_Cell, Param_String);

	Call_StartForward(hForward);
	Call_PushCell(client);
	Call_PushString(g_sClassName[client]);
	Call_Finish();
}

stock void Forward_OnEntityRegister(int iEntity, char[] sClassName, bool bEdit, KeyValues kv)
{
	static Handle hForward;

	if(hForward == null)
		hForward = CreateGlobalForward("Entity_OnEntityRegister", ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Cell);

	Call_StartForward(hForward);
	Call_PushCell(iEntity);
	Call_PushString(sClassName);
	Call_PushCell(bEdit);
	Call_PushCell(kv);
	Call_Finish();
}