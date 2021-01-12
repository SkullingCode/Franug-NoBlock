/*  SM Franug NoBlock
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>


#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.2"


ConVar sm_noblock_cts;
ConVar sm_noblock_ts;
ConVar sm_noblock_time;
ConVar noblock2time;
ConVar advertisenb;

bool g_badvertisenb;


bool g_ShouldCollide[MAXPLAYERS+1] = { true, ... };
bool g_IsNoBlock[MAXPLAYERS+1] = {false, ...};
bool g_IsNoBlock2[MAXPLAYERS+1] = {false, ...};

int Veces[MAXPLAYERS+1] = 0;
Handle timers[MAXPLAYERS + 1];

Handle g_timer = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "SM Franug NoBlock",
	author = "Franc1sco franug/Edited JZ",
	description = "",
	version = VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public void  OnPluginStart()
{

	HookEvent("round_freeze_end", Event_RoundStart, EventHookMode_Post);

	HookEvent("player_spawn", PlayerSpawn);

	CreateConVar("Franug-Noblock", VERSION, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	sm_noblock_cts = CreateConVar("sm_noblock_cts", "1", "CT max for noblock in round start");
	sm_noblock_ts = CreateConVar("sm_noblock_ts", "1", "Ts max for noblock in round start");
	sm_noblock_time = CreateConVar("sm_noblock_time", "6.0", "Secods of first noblock (low value because can cause Mayhem bug).");
	noblock2time = CreateConVar("sm_noblock2_time", "10.0", "Seconds of secondary noblock");
	advertisenb = CreateConVar("sm_noblock_advertise", "1", "Advertise NoBlock is enabled/disabled in chat");
	
	if (advertisenb.IntValue == 0)
	{
		g_badvertisenb=false;
	}
	else
	{
		g_badvertisenb=true;
	}

	RegConsoleCmd("sm_noblock", DONoBlock);
	RegConsoleCmd("sm_nb", DONoBlock);
}
public void OnAllPluginsLoaded()
{
	GeneralDataConfig();
}
public void OnMapStart()
{
	GeneralDataConfig();
}
public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{

	int Ts, CTs;
	for(int i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			switch(GetClientTeam(i)) {				
				case CS_TEAM_T: Ts++;				
				case CS_TEAM_CT: CTs++;			
			}
		}
	}

	if (Ts > GetConVarInt(sm_noblock_ts) && CTs > GetConVarInt(sm_noblock_cts))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
				if (g_badvertisenb)
					PrintToChat(i, " \x04[NoBlock]\x01 You have %i seconds of primary NoBlock", GetConVarInt(sm_noblock_time));
									
				g_IsNoBlock[i] = true;
									
			}
		}
		if (g_timer != INVALID_HANDLE)KillTimer(g_timer);
		
		g_timer = CreateTimer(GetConVarFloat(sm_noblock_time), DesactivadoNB);
	}
}

public Action DesactivadoNB(Handle timer)
{
	g_timer = INVALID_HANDLE;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (g_IsNoBlock[client])
			{
				SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
				if (g_badvertisenb)
					PrintToChat(client, " \x04[NoBlock]\x01 Now you have %i seconds of secondary NoBlock", GetConVarInt(noblock2time));
				g_IsNoBlock[client] = false;

				Veces[client] = GetConVarInt(noblock2time);
				CreateTimer(1.0, Repetidor, client, TIMER_REPEAT);
				g_IsNoBlock2[client] = true;
			}
		}
	}
}

public Action DesactivadoNB2(Handle timer, any client)
{
   if (IsClientInGame(client) && IsPlayerAlive(client))
   {
	 if (g_IsNoBlock2[client])
	 {
		 g_IsNoBlock2[client] = false;
		 if (g_badvertisenb)
			PrintToChat(client, " \x04[NoBlock]\x01 Now you dont have NoBlock");
	 }
   }
}

 

public Action DONoBlock(int client,int args)
{
   if (IsClientInGame(client) && IsPlayerAlive(client) && !g_IsNoBlock[client])
   {
		 //SetEntData(client, g_offsCollisionGroup, 2, 4, true);
		 if (g_badvertisenb)
			PrintToChat(client, " \x04[NoBlock]\x01 You have %i seconds of NoBlock", GetConVarInt(noblock2time));
		 CreateTimer(GetConVarInt(noblock2time) * 1.0, DesactivadoNB2, client);
		 g_IsNoBlock2[client] = true;
   }
   else
   {
		if (g_badvertisenb)
			PrintToChat(client, " \x04[NoBlock]\x01 You already have NoBlock or you are dead");
   }
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_IsNoBlock[client] = false;
	g_IsNoBlock2[client] = false;
	OnClientDisconnect(client);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_ShouldCollide, ShouldCollide);
	SDKHook(client, SDKHook_StartTouch, Touch);
	SDKHook(client, SDKHook_Touch, Touch);
	SDKHook(client, SDKHook_EndTouch, EndTouch);
}





public bool ShouldCollide(int entity, int collisiongroup, int contentsmask, bool result)
{
		
	if (contentsmask == 33636363)
	{
		return g_ShouldCollide[entity];
	}
	
	return true;
}

public void Touch(int ent1, int ent2)
{

	if(ent1 == ent2)
		return;
	if(ent1 > MaxClients || ent1 == 0)
		return;
	if(ent2 > MaxClients || ent2 == 0)
		return;

	if(g_IsNoBlock2[ent1])
	{
		Veces[ent1] = GetConVarInt(noblock2time);
		g_ShouldCollide[ent1] = false;
		g_ShouldCollide[ent2] = false;
	}
}

public void OnClientDisconnect(int client)
{
	if (timers[client] != INVALID_HANDLE)KillTimer(timers[client]);
	
	timers[client] = INVALID_HANDLE;
}

public void EndTouch(int ent1, int ent2)
{

	if(ent1 == ent2)
		return;
	if(ent1 > MaxClients || ent1 == 0)
		return;
	if(ent2 > MaxClients || ent2 == 0)
		return;

	if(!g_ShouldCollide[ent1])
	{
		if (timers[ent1] != INVALID_HANDLE)KillTimer(timers[ent1]);
		timers[ent1] = CreateTimer(3.0, TurnOnCollision, ent1);
	}

	if(!g_ShouldCollide[ent2])
	{
		if (timers[ent2] != INVALID_HANDLE)KillTimer(timers[ent2]);
		timers[ent2] = CreateTimer(3.0, TurnOnCollision, ent2);
	}
} 

public Action TurnOnCollision(Handle timer, any client)
{
	timers[client] = INVALID_HANDLE;
	if (IsClientInGame(client) && IsPlayerAlive(client) && !g_ShouldCollide[client])
		g_ShouldCollide[client] = true;

} 

public Action Repetidor(Handle timer, any client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	if (Veces[client] == 0)
	{
		g_IsNoBlock2[client] = false;
		if (g_badvertisenb)
			PrintToChat(client, " \x04[NoBlock]\x01 Now you dont have NoBlock");
		return Plugin_Stop;
	}

	else if(!g_IsNoBlock2[client])
	{
		return Plugin_Stop;
	}

	Veces[client] -= 1;

	return Plugin_Continue;
}
void GeneralDataConfig()
{
//++++++++++++++GENERAL DATA FROM CONFIG++++++++++++++++++++++++++++++++++++	

	char GeneralDataLoc[128];
	BuildPath(Path_SM,GeneralDataLoc,sizeof(GeneralDataLoc),"configs/noblock/general.txt");
	Handle cfgGeneralData = CreateKeyValues("General Data");
	if(!FileToKeyValues(cfgGeneralData, GeneralDataLoc)){LogToGame("Unable to load General Data key value from configs/noblock/general.txt");}
	
	sm_noblock_cts.IntValue = KvGetNum(cfgGeneralData, "enable_ct_nb", 1);
	sm_noblock_ts.IntValue = KvGetNum(cfgGeneralData, "enable_t_nb", 1);
	sm_noblock_time.FloatValue = KvGetFloat(cfgGeneralData, "primary_nb_time", 6.0);
	noblock2time.FloatValue = KvGetFloat(cfgGeneralData, "secondary_nb_time", 10.0);
	advertisenb.IntValue = KvGetNum(cfgGeneralData, "print_chat_nb", 1);
	
	

	CloseHandle(cfgGeneralData);
	cfgGeneralData=INVALID_HANDLE;
	
	if (advertisenb.IntValue == 0)
	{
		g_badvertisenb=false;
	}
	else
	{
		g_badvertisenb=true;
	}
}