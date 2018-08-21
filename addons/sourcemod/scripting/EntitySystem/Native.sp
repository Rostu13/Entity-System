stock void Entity_CreateNative()
{
	CreateNative("Entity_IsWorking", Native_IsWorking);
	CreateNative("Entity_RegisterType", Native_RegisterType);
	CreateNative("Entity_UnRegisterType", Native_UnRegisterType);

	CreateNative("Entity_GetClientEditEntity", Native_GetClientEditEntity);
	CreateNative("Entity_SetClientEditEntity", Native_SetClientEditEntity);
//	Classname = trigger_teleport/ambient_generic/...
	CreateNative("Entity_GetClientEditClassName", Native_GetClientEditClassName);

	CreateNative("Entity_EditMenuAccess", Native_EditMenuAccess);

	CreateNative("Entity_TeleportToEditEntity", Native_TeleportToEditEntity);

	CreateNative("Entity_GetAdminMenuHandle", Native_GetAdminMenuHandle);
}

public int Native_IsWorking(Handle hPlugin, int iParms)
{
	return g_bLoaded;
}

public int Native_RegisterType(Handle hPlugin, int iParms)
{
	char sType[32];
	GetNativeString(1,sType,sizeof sType);

	if(g_hRegisteredTypes.FindString(sType) != -1)
		return;

	g_hRegisteredTypes.PushString(sType);
}

public int Native_UnRegisterType(Handle hPlugin, int iParms)
{
	char sType[32];
	GetNativeString(1,sType,sizeof sType);

	int iType = g_hRegisteredTypes.FindString(sType);
	if(iType == -1)
	{
		ThrowNativeError(1,"[Entity System] Попытка удалить несуществующий тип: %s",sType);
	}

	g_hRegisteredTypes.Erase(iType);
}

public int Native_GetClientEditEntity(Handle hPlugin, int iParms)
{
	int client = GetNativeCell(1);

	return g_iEntityEdited[client];
}

public int Native_SetClientEditEntity(Handle hPlugin, int iParms)
{
	int client = GetNativeCell(1);
	int iEntity = GetNativeCell(2);

	g_iEntityEdited[client] = iEntity;
	GetEdictClassname(iEntity, g_sClassName[client], sizeof(g_sClassName[]));
}

public int Native_GetClientEditClassName(Handle hPlugin, int iParms)
{
	int client = GetNativeCell(1);

	SetNativeString(2, g_sClassName[client], sizeof g_sClassName);
}

public int Native_EditMenuAccess(Handle hPlugin, int iParms)
{
	int client = GetNativeCell(1);
	bool bAcces = GetNativeCell(2);

	g_bEditPosEntity[client] = bAcces;
	CreateEditMenu(client);
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