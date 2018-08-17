#if defined _entity_system_included
  #endinput
#endif
#define _entity_system_included

stock const char g_sAdminMenuCategory[] = "entity_system";

stock void TelepotEntityToClient(int iClient, int iEntity)
{
	float fPos[3];
	GetEntPropVector(iClient, Prop_Data, "m_vecOrigin", fPos); 

	TeleportEntity(iEntity,fPos,NULL_VECTOR, NULL_VECTOR);
}

native bool Entity_IsWorking();

native void Entity_RegisterType(const char[] sName);
native void Entity_UnRegisterType(const char[] sName);

native int Entity_GetClientEditEntity(int iClient);
native void Entity_SetClientEditEntity(int iClient, int iEntity);

native void Entity_GetClientEditClassName(int iClient, char[] sClassName);

native bool Entity_EditMenuAccess(int iClient, bool bAcces);
native void Entity_TeleportToEditEntity(int iClient);
native int Entity_GetAdminMenuHandle();