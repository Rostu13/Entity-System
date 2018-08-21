stock void KVEditPosSave(int client, bool bSave = true)
{
	char sKey[12];
	IntToString(g_iEntityEdited[client],sKey,sizeof sKey);

	float fTemp[3];

	if(bSave)
		GetEntPropVector(g_iEntityEdited[client], Prop_Data, g_TypePos[client] == Type_Pos ? "m_vecOrigin" : "m_angRotation", fTemp);

	if(g_hKv.JumpToKey(sKey, bSave))
	{
		g_hKv.SetVector(g_TypePos[client] == Type_Pos ? g_sPosKeyKV : g_sAnglesKeyKV, fTemp);

		g_hKv.Rewind();
		g_hKv.ExportToFile(g_sPath);
	}
}
stock void ChangeEntity()
{
    if(!g_hKv.GotoFirstSubKey()) return;

    char sEntity[8];
    int iEntity;
    do 
    {
        if(!g_hKv.GetSectionName(sEntity,sizeof sEntity)) continue;

        iEntity = StringToInt(sEntity);
        ChangeEntityCustomPos(iEntity);
    }
    while(g_hKv.GotoNextKey())

    g_hKv.Rewind();
}
stock void ChangeEntityCustomPos(int iEntity)
{
    static float fPos[3];

    g_hKv.GetVector(g_sPosKeyKV, fPos);

    if(!IsNullVector(fPos))
        TeleportEntity(iEntity, fPos, NULL_VECTOR, NULL_VECTOR);
}
//https://github.com/TotallyMehis/Influx-Timer/blob/35ac15e283cc1f208721bc0985e83b41fc70f848/addons/sourcemod/scripting/include/msharedutil/misc.inc#L134-L148
stock bool DirExistsExtend(const char[] sPath)
{
    if ( !DirExists( sPath ) )
    {
        CreateDirectory( sPath, 511 );
        
        if ( !DirExists( sPath ) )
        {
            LogError( "Не удалось создать папку [%s]", sPath);
            return false;
        }
    }
    
    return true;
}
//https://github.com/TotallyMehis/Influx-Timer/blob/35ac15e283cc1f208721bc0985e83b41fc70f848/addons/sourcemod/scripting/include/msharedutil/misc.inc#L18-L69
stock void GetCurrentMapSafe( char[] sz, int len )
{
    char map[128];
    GetCurrentMapLower( map, sizeof( map ) );

    
    int lastpos = -1;
    
    int start = 0;
    int pos = -1;
    
    while ( (pos = FindCharInString( map[start], '/' )) != -1 )
    {
        lastpos = pos + start + 1;
        
        start += pos + 1;
    }
    
    if ( lastpos != -1 && map[lastpos] != '\0' )
    {
        strcopy( sz, len, map[lastpos] );
    }
    else
    {
        strcopy( sz, len, map );
    }
    
}
stock void GetCurrentMapLower( char[] sz, int len )
{
    GetCurrentMap( sz, len );
    
    StringToLower( sz );
}
stock void StringToLower( char[] sz )
{
    int len = strlen( sz );
    
    for ( int i = 0; i < len; i++ )
        if ( IsCharUpper( sz[i] ) )
            sz[i] = CharToLower( sz[i] );
}
stock void TeleportToEditEntity(int client)
{
	float fPos[3];
	GetEntPropVector(g_iEntityEdited[client], Prop_Data, "m_vecOrigin", fPos);

	TeleportEntity(client,fPos,NULL_VECTOR,NULL_VECTOR);
}
stock int GetClientAxisEdit(int client)
{
	return 'X' + view_as<int>(g_Axis[client]);
}