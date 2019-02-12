stock void Entity_CreateNative()
{
	CreateNative("Entity_GetClientEditEntity", Native_GetClientEditEntity);
	CreateNative("Entity_SetClientEditEntity", Native_SetClientEditEntity);

	CreateNative("Entity_OpenEditMenu", Native_OpenEditMenu);
	CreateNative("Entity_OpenCustomEditMenu", Native_OpenCustomEditMenu);

	CreateNative("Entity_TeleportToEditEntity", Native_TeleportToEditEntity);

	CreateNative("Entity_GetAdminMenuHandle", Native_GetAdminMenuHandle);
	CreateNative("Entity_GetKeyValues", Native_GetKeyValues);
	CreateNative("Entity_GetKeyValuesPath", Native_GetKeyValuesPath);
}
public int Native_GetClientEditEntity(Handle hPlugin, int iParms)
{
	int client = GetNativeCell(1);

	return g_eEntity[client].id;
}

public int Native_SetClientEditEntity(Handle hPlugin, int iParms)
{
	int client = GetNativeCell(1);
	int iEntity = GetNativeCell(2);

	g_eEntity[client].id = iEntity;
	GetEdictClassname(iEntity, g_eEntity[client].sName, 32);
}
public int Native_OpenEditMenu(Handle hPlugin, int iParms)
{
	int client = GetNativeCell(1);
	
	g_eEntity[client].edit 		= Edit_Entity;
	g_eEntity[client].type 		= Type_Pos;
	g_eEntity[client].axis 		= Axis_X;
	g_eEntity[client].color 	= Color_Red;

	CreateEditMenu(client);
}
public int Native_OpenCustomEditMenu(Handle hPlugin, int iParms)
{
	int client = GetNativeCell(1);
	g_eEntity[client].edit = Edit_Custom;

	CreateCustomEditMenu(client);
}
public int Native_TeleportToEditEntity(Handle hPlugin, int iParms)
{
	int client = GetNativeCell(1);
	TeleportToEditEntity(client);
}

public int Native_GetAdminMenuHandle(Handle hPlugin, int iParms)
{
	return view_as<int>(g_hAdmin);
}
public int Native_GetKeyValues(Handle hPlugin, int iParms)
{
	return view_as<int>(g_hKv);
}
public int Native_GetKeyValuesPath(Handle hPlugin, int iParms)
{
	SetNativeString(1, g_sPath,GetNativeCell(2));
}