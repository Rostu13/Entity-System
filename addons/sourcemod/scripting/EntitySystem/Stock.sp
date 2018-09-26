stock void KVEditSave(int client, bool bSave = true)
{
	char sKey[12];
	IntToString(g_iEntityEdited[client],sKey,sizeof sKey);

	float fTemp[3];
    int iColor[4];

	if(bSave)
    {
        if(g_TypePos[client] == Type_RGB)   GetEntDataArray(g_iEntityEdited[client], g_iRenderClrOffset, iColor, 4, 1); 
		else                                GetEntPropVector(g_iEntityEdited[client], Prop_Data, g_TypePos[client] == Type_Pos ? "m_vecOrigin" : "m_angRotation", fTemp);
    }

	if(g_hKv.JumpToKey(sKey, bSave))
	{
        if(g_TypePos[client] == Type_RGB)   g_hKv.SetColor4("color", iColor);
		else                                g_hKv.SetVector(g_sSaveKeyKV[g_TypePos[client]],  fTemp);

		g_hKv.Rewind();
		g_hKv.ExportToFile(g_sPath);
	}
}
stock void ChangeEntity()
{
    if(!g_hKv.GotoFirstSubKey()) return;

    char sEntity[8];
    int iEntity;
    bool bCustom;
    do 
    {
        if(!g_hKv.GetSectionName(sEntity,sizeof sEntity)) continue;

        iEntity = StringToInt(sEntity);
        bCustom = view_as<bool>(g_hKv.GetNum("custom"));
        if(!bCustom && !IsValidEntity(iEntity)) continue;

        ChangeEntityCustomPos(iEntity);

        Forward_CustomEntitySpawn(iEntity, bCustom, g_hKv);
    }
    while(g_hKv.GotoNextKey())

    g_hKv.Rewind();
}
stock void ChangeEntityCustomPos(int iEntity)
{
    static float    fPos[3];
    static float    fAngles[3];
    static int      iColor[4];

    g_hKv.GetVector(g_sSaveKeyKV[Type_Pos], fPos);
    g_hKv.GetVector(g_sSaveKeyKV[Type_Angles], fAngles);
    g_hKv.GetColor4(g_sSaveKeyKV[Type_RGB], iColor);

    if(!IsNullVectorEx(fPos))                       TeleportEntity(iEntity, fPos, NULL_VECTOR, NULL_VECTOR);
    if(!IsNullVectorEx(fPos))                       SetEntPropVector(iEntity, Prop_Send, "m_angRotation", fAngles);
    if( iColor[0] && iColor[1] && iColor[2])        SetEntDataArray(iEntity, g_iRenderClrOffset, iColor, 4, 1);
}
stock bool IsNullVectorEx(float fPos[3])
{
    return (fPos[0] == 0.0 && fPos[1] == 0.0 && fPos[2] == 0.0);
}
stock char CreateTitleEditMenu(int client)
{
    int iColor[4];
    float fVec[3];

    if(g_TypePos[client] == Type_RGB)   GetEntDataArray(g_iEntityEdited[client], g_iRenderClrOffset, iColor, 4, 1); 
    else                            	GetEntPropVector(g_iEntityEdited[client], Prop_Send, g_TypePos[client] == Type_Pos ? "m_vecOrigin" : "m_angRotation", fVec);

    char sDisplay[128];
    char sBuffer[32];

    for(int x = 0; x < 3; x++)
    {
        if(g_TypePos[client] == Type_RGB)
        {
            FormatEx(sBuffer,sizeof sBuffer, "%s %d", g_sChangeRGB[x], iColor[x]);
        }
        else 
        {
            FormatEx(sBuffer,sizeof sBuffer, "%c %.2f", 'X' + x, fVec[ GetNumberAxis( x ) ] );
        }
        if( (g_TypePos[client] == Type_RGB && view_as<int>(g_Color[client]) == x ) 
            || (g_TypePos[client] != Type_RGB &&g_Axis[client] == GetNumberAxis( x ) ))         Format(sBuffer,sizeof sBuffer, ">> %s <<\n", sBuffer);
        else                                                                                    Format(sBuffer,sizeof sBuffer, "%s\n", sBuffer);

        Format(sDisplay,sizeof sDisplay, "%s%s", sDisplay, sBuffer);
    }

    return sDisplay;
}
stock void TeleportToEditEntity(int client)
{
	float fPos[3];
	GetEntPropVector(g_iEntityEdited[client], Prop_Data, "m_vecOrigin", fPos);

	TeleportEntity(client,fPos,NULL_VECTOR,NULL_VECTOR);
}
/*EntitySystem/Menu.sp(16 -- 18) : error 033: array must be indexed (variable "GetClientAxisEdit")
stock char GetClientAxisEdit(int client)
{
    switch(g_Axis[client])
    {
        case Axis_X:	return 'X';
        case Axis_Y:	return 'Y';
        case Axis_Z:    return 'Z';
    }

    return ' ';
}
*/
stock char GetClientAxisEdit(int client)
{
    char sSymbol[2];

    switch(g_Axis[client])
    {
        case Axis_X:	sSymbol =  "X";
        case Axis_Y:	sSymbol =  "Y";
        case Axis_Z:    sSymbol =  "Z";
    }

    return sSymbol;
}

stock ChangePosEntity GetNumberAxis(int axis)
{
    switch(axis)
    {
        case 0: return Axis_X;
        case 1: return Axis_Y;
    }

    return Axis_Z;
}
stock char[] GetClientItemEdit(int client)
{
	char sBuffer[24];

	if( g_TypePos[client] == Type_RGB )
	{
		FormatEx(sBuffer,sizeof sBuffer, "%s", g_sChangeRGB[ g_Color[client] ]);
		return sBuffer
	}
	FormatEx(sBuffer,sizeof sBuffer, "%s",GetClientAxisEdit(client) );

	return sBuffer;
}

//https://github.com/TotallyMehis/Influx-Timer/blob/35ac15e283cc1f208721bc0985e83b41fc70f848/addons/sourcemod/scripting/include/msharedutil/misc.inc#L134-L148
stock bool DirExistsEx(const char[] sPath)
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