#if defined _entity_system_included
  #endinput
#endif
#define _entity_system_included

stock const char g_sAdminMenuCategory[] = "entity_system";

stock void TelepotEntityToClient(int client, int entity)
{
	float fPos[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", fPos); 

	TeleportEntity(entity, fPos, NULL_VECTOR, NULL_VECTOR);
}

native bool Entity_IsWorking();

native void Entity_RegisterType(const char[] name);
native void Entity_UnRegisterType(const char[] name);

native int entityity_GetClientEditEntity(int client);
native void Entity_SetClientEditEntity(int client, int entity);

native void Entity_GetClientEditClassName(int client, char[] class);

native bool Entity_EditMenuAccess(int client, bool acces);
native void Entity_TeleportToEditEntity(int client);
native int entityity_GetAdminMenuHandle();