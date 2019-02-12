stock void Forward_RequestType()
{
	static Handle hForward;

	if(hForward == null) 
		hForward = CreateGlobalForward("Entity_RequestType", ET_Ignore, Param_Cell);

	Call_StartForward(hForward);
	Call_PushCell(g_hRegisteredTypes);
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

stock void Forward_EndEditMenu(int client, bool bCustom = false, bool bSave = false, int iValue = 0)
{
	static Handle hForward;
	if(hForward == null)
		hForward = CreateGlobalForward("Entity_EndEditMenu", ET_Ignore, Param_Cell, Param_String, Param_Cell,Param_Cell, Param_Cell);

	Call_StartForward(hForward);
	Call_PushCell(client);
	Call_PushString(g_eEntity[client].sName);
	Call_PushCell(bCustom);
	Call_PushCell(bSave);
	Call_PushCell(iValue);
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
/*
stock void Forward_CustomEntitySpawn(int iEntity, bool bCustom, KeyValues kv)
{
	static Handle hForward;

	if(hForward == null)
		hForward = CreateGlobalForward("Entity_CustomEntitySpawn", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	Call_StartForward(hForward);
	Call_PushCell(iEntity);
	Call_PushCell(bCustom);
	Call_PushCell(kv);
	Call_Finish();
}
*/