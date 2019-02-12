#if defined _entity_system_included
  #endinput
#endif
#define _entity_system_included
#pragma tabsize 0 // Sorry

#define MENU_CALLBACK(%0) public int %0 (Menu menu, MenuAction action, int param1, int param2)

enum EntityEdit
{
	Edit_None = -1,

	Edit_Entity,	
	Edit_Custom
};


//stock
stock const char g_sAdminMenuCategory[] = "entity_system";
stock const char g_sSaveKeyKV[][] = 
{
	"pos",
	"angles",
	"color"
};

stock void TelepotEntityToClient(int client, int entity)
{
	float fPos[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", fPos); 

	TeleportEntity(entity, fPos, NULL_VECTOR, NULL_VECTOR);
}

// Natives

native int 		Entity_GetClientEditEntity(int client);
native void 		Entity_SetClientEditEntity(int client, int entity);

native void 		Entity_OpenEditMenu(int client);
native void		Entity_OpenCustomEditMenu(int client);
native void 		Entity_TeleportToEditEntity(int client);
native int 		Entity_GetAdminMenuHandle();
native KeyValues 	Entity_GetKeyValues();
native void 		Entity_GetKeyValuesPath(char[] sPath, int iMaxLength);

//Forwards

forward void Entity_RequestType(ArrayList hList);
forward void Entity_OnAdminMenuCreated(TopMenu hAdmin, TopMenuObject hCategory);
forward void Entity_EndEditMenu(int client, char[] sClassName, bool bCustom, bool bSave, int iValue);
forward void Entity_OnEntityRegister(int iEntity, char[] sClassName, bool bEdit, KeyValues kv);
forward void Entity_CustomEntitySpawn(int iEntity, bool bCustom, KeyValues kv)