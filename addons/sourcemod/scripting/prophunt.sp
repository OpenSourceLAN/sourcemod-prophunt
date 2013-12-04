//  PropHunt by Darkimmortal
//   - GamingMasters.org -
//    Updated by Powerlord
// - reddit.com/r/RUGC_Midwest -

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>

#if !defined SNDCHAN_VOICE2
#define SNDCHAN_VOICE2 7
#endif

#undef REQUIRE_EXTENSIONS
#include <steamtools>
#include <readgamesounds>

#undef REQUIRE_PLUGIN
#include <tf2attributes>

#define PL_VERSION "3.0.0 beta 9"
//--------------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------- MAIN PROPHUNT CONFIGURATION -------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

// Enable for global stats support (.inc file available on request due to potential for cheating and database abuse)
// Default: OFF
//#define STATS

#if defined STATS
#define SELECTOR_PORTS "27019"
#include <selector>
#endif

// Include support for Opt-In MultiMod
// Default: OFF
//#define OIMM

// Give last prop a scattergun and apply jarate to all pyros on last prop alive
// Default: ON
#define SCATTERGUN

// Prop Lock/Unlock sounds
// Default: ON
#define LOCKSOUND

// Extra classes
// Default: ON
#define SHINX

// Event and query logging for debugging purposes
// Default: OFF
//#define LOG

// Allow props to Targe Charge with enemy collisions disabled by pressing reload - pretty shit tbh.
// Default: OFF
//#define CHARGE

// Max ammo in Pyro shotgun
// Default: 2
#define SHOTGUN_MAX_AMMO 2

// Deprecated and switched to ph_antihack cvar
// Anti-exploit system
// Default: ON
//#define ANTIHACK

//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

#if defined OIMM
#include <optin_multimod>
#endif 

#define FLAMETHROWER "models/weapons/w_models/w_flamethrower.mdl"

#define STATE_WAT -1
#define STATE_IDLE 0
#define STATE_RUNNING 1
#define STATE_SWING 2
#define STATE_CROUCH 3

// Not sure what this is for, but pretty sure it's wrong.. player conditions are no longer defined like this
#define PLAYER_ONFIRE (1 << 14)

// Weapon Indexes
#define WEP_SHOTGUN_UNIQUE 199

//Pyro
#define WEP_SHOTGUNPYRO 12

#define WEP_PHLOGISTINATOR 594

#define LOCKVOL 0.7
#define UNBALANCE_LIMIT 1
#define MAXMODELNAME 96
// Not sure what this is for, but pretty sure it's wrong.. player conditions are no longer defined like this
#define TF2_PLAYERCOND_ONFIREALERT    (1<<20)

#define IN_MOVEMENT IN_MOVELEFT | IN_MOVERIGHT | IN_FORWARD | IN_BACK | IN_JUMP

#define TIMER_NAME "prop_hunt_timer"

enum
{
	Item_Classname,
	Item_Index,
	Item_Quality,
	Item_Level,
	Item_Attributes,
}

enum ScReason
{
	ScReason_TeamWin = 0,
	ScReason_TeamLose,
	ScReason_Death,
	ScReason_Kill,
	ScReason_Time,
	ScReason_Friendly
};

enum PropData
{
	String:PropData_Name[MAXMODELNAME],
	String:PropData_Offset[32], // 3 digits, plus 2 spaces, plus a null terminator
	String:PropData_Rotation[32], // 3 digits, plus 2 spaces, plus a null terminator
}

enum RoundChange
{
	RoundChange_NoChange,
	RoundChange_Enable,
	RoundChange_Disable,
}

new bool:g_RoundOver = true;
new bool:g_inPreRound = true;

new bool:g_LastProp;
new bool:g_Attacking[MAXPLAYERS+1];
new bool:g_SetClass[MAXPLAYERS+1];
new bool:g_Spawned[MAXPLAYERS+1];
new bool:g_TouchingCP[MAXPLAYERS+1];
new bool:g_Charge[MAXPLAYERS+1];
new bool:g_First[MAXPLAYERS+1];
new bool:g_HoldingLMB[MAXPLAYERS+1];
new bool:g_HoldingRMB[MAXPLAYERS+1];
new bool:g_AllowedSpawn[MAXPLAYERS+1];
new bool:g_RotLocked[MAXPLAYERS+1];
new bool:g_Hit[MAXPLAYERS+1];
new bool:g_Spec[MAXPLAYERS+1];
new String:g_PlayerModel[MAXPLAYERS+1][MAXMODELNAME];

new String:g_Mapname[128];
new String:g_ServerIP[32];
new String:g_Version[16];

new g_Message_red;
new g_Message_blue;
new g_RoundTime = 175;
new g_Message_bit = 0;
//new g_iVelocity = -1;

#if defined STATS
new bool:g_MapChanging = false;
new g_StartTime;
#endif

//new Handle:g_TimerStart = INVALID_HANDLE;
new	Handle:g_Sounds = INVALID_HANDLE;
new Handle:g_BroadcastSounds = INVALID_HANDLE;

new bool:g_Doors = false;
new bool:g_Relay = false;
new bool:g_Freeze = true;

//new bool:g_weaponRemovals[MAXITEMS];
//new Float:g_weaponNerfs[MAXITEMS];
//new Float:g_weaponSelfDamage[MAXITEMS];

new Handle:g_hWeaponRemovals;
new Handle:g_hWeaponNerfs;
new Handle:g_hWeaponSelfDamage;
new Handle:g_hWeaponStripAttribs;
new Handle:g_hWeaponAddAttribs;
new Handle:g_hWeaponReplacements;

new g_classLimits[2][10];
new TFClassType:g_defaultClass[2];
new Float:g_classSpeeds[10][3]; //0 - Base speed, 1 - Max Speed, 2 - Increment Value
new Float:g_currentSpeed[MAXPLAYERS+1];

//new g_oFOV;
//new g_oDefFOV;

new Handle:g_PropData = INVALID_HANDLE;

new Handle:g_ConfigKeyValues = INVALID_HANDLE;
new Handle:g_ModelName = INVALID_HANDLE;
new Handle:g_ModelOffset = INVALID_HANDLE;
new Handle:g_ModelRotation = INVALID_HANDLE;
new Handle:g_Text1 = INVALID_HANDLE;
new Handle:g_Text2 = INVALID_HANDLE;
new Handle:g_Text3 = INVALID_HANDLE;
new Handle:g_Text4 = INVALID_HANDLE;

//new Handle:g_RoundTimer = INVALID_HANDLE;
new Handle:g_PropMenu = INVALID_HANDLE;

new Handle:g_PHEnable = INVALID_HANDLE;
new Handle:g_PHPropMenu = INVALID_HANDLE;
//new Handle:g_PHAdmFlag = INVALID_HANDLE;
new Handle:g_PHAdvertisements = INVALID_HANDLE;
new Handle:g_PHPreventFallDamage = INVALID_HANDLE;
new Handle:g_PHGameDescription = INVALID_HANDLE;
new Handle:g_PHAirblast = INVALID_HANDLE;
new Handle:g_PHAntiHack = INVALID_HANDLE;
new Handle:g_PHReroll = INVALID_HANDLE;
new Handle:g_PHStaticPropInfo = INVALID_HANDLE;

new String:g_AdText[128] = "";

new bool:g_MapStarted = false;

new bool:g_SteamTools = false;
#if defined OIMM
new bool:g_OptinMultiMod = false;
#endif

new bool:g_Enabled = true;

// Timers
new Handle:g_hAntiHack;
new Handle:g_hLocked;
new Handle:g_hScore;

// Valve CVars we're going to save and adjust
new Handle:g_hArenaRoundTime;
new g_ArenaRoundTime;
new Handle:g_hWeaponCriticals;
new g_WeaponCriticals;
new Handle:g_hIdledealmethod;
new g_Idledealmethod;
new Handle:g_hTournamentStopwatch;
new g_TournamentStopwatch;
new Handle:g_hTournamentHideDominationIcons;
new g_TournamentHideDominationIcons;
new Handle:g_hFriendlyfire;
new g_Friendlyfire;
new Handle:g_hGravity;
new g_Gravity;
new Handle:g_hForcecamera;
new g_Forcecamera;
new Handle:g_hArenaCapEnableTime;
new g_ArenaCapEnableTime;
new Handle:g_hTeamsUnbalanceLimit;
new g_TeamsUnbalanceLimit;
new Handle:g_hArenaMaxStreak;
new g_ArenaMaxStreak;
new Handle:g_hEnableRoundWaitTime;
new g_EnableRoundWaitTime;
new Handle:g_hWaitingForPlayerTime;
new g_WaitingForPlayerTime;
new Handle:g_hArenaUseQueue;
new g_ArenaUseQueue;
new Handle:g_hShowVoiceIcons;
new g_ShowVoiceIcons;
new Handle:g_hSolidObjects;
new g_SolidObjects;
new Handle:g_hArenaPreroundTime;
new g_ArenaPreroundTime;

new Handle:g_hBonusRoundTime;

new g_Replacements[MAXPLAYERS+1][6];
new g_ReplacementCount[MAXPLAYERS+1];
new bool:g_Rerolled[MAXPLAYERS+1] = { false, ... };

new bool:g_CvarsSet;

new RoundChange:g_RoundChange;
new bool:g_MapRunning = false;

new bool:g_CurrentlyFlying[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "PropHunt Redux",
	author = "Darkimmortal and Powerlord",
	description = "Hide as a prop from the evil Pyro menace... or hunt down the hidden prop scum",
	version = PL_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=228086"
}

// Updated in Prophunt Redux from Source SDK 2013's const.h
// https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/public/const.h
enum
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,			// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,		// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// Doors that the player shouldn't collide with
	COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,		// Nonsolid on client and server, pushaway in player code

	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other

	LAST_SHARED_COLLISION_GROUP
}

#if defined STATS

#include "prophunt\stats2.inc"
/*
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:hostname[255], String:ip[32], String:port[8]; //, String:map[92];
	GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
	GetConVarString(FindConVar("ip"), ip, sizeof(ip));
	GetConVarString(FindConVar("hostport"), port, sizeof(port));

	if(StrContains(hostname, "GamingMasters.co.uk", false) != -1)
	{
		if(StrContains(hostname, "PropHunt", false) == -1 && StrContains(hostname, "Arena", false) == -1 && StrContains(hostname, "Dark", false) == -1 &&
				StrContains(ip, "8.9.4.169", false) == -1)
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}
*/
#endif

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("Steam_SetGameDescription");
	return APLRes_Success;
}

public OnPluginStart()
{
	decl String:hostname[255], String:ip[32], String:port[8]; //, String:map[92];
	GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
	GetConVarString(FindConVar("ip"), ip, sizeof(ip));
	GetConVarString(FindConVar("hostport"), port, sizeof(port));

	Format(g_ServerIP, sizeof(g_ServerIP), "%s:%s", ip, port);

	new bool:statsbool = false;
#if defined STATS
	statsbool = true;
#endif

	g_hWeaponRemovals = CreateArray();
	g_hWeaponNerfs = CreateTrie();
	g_hWeaponSelfDamage = CreateTrie();
	g_hWeaponStripAttribs = CreateArray();
	g_hWeaponAddAttribs = CreateTrie();
	g_hWeaponReplacements = CreateTrie();
	
	Format(g_Version, sizeof(g_Version), "%s%s", PL_VERSION, statsbool ? "s":"");
	CreateConVar("prophunt_redux_version", g_Version, "PropHunt Redux Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

//	g_PHAdmFlag = CreateConVar("ph_propmenu_flag", "c", "Flag to use for the PropMenu");
	g_PHEnable = CreateConVar("ph_enable", "1", "Enables the plugin", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_PHPropMenu = CreateConVar("ph_propmenu", "0", "Control use of the propmenu command: -1 = Disabled, 0 = players with the propmenu override", _, true, -1.0, true, 0.0);
	g_PHAdvertisements = CreateConVar("ph_adtext", g_AdText, "Controls the text used for Advertisements");
	g_PHPreventFallDamage = CreateConVar("ph_preventfalldamage", "0", "Set to 1 to prevent fall damage.  Will use TF2Attributes if available due to client prediction", _, true, 0.0, true, 1.0);
	g_PHGameDescription = CreateConVar("ph_gamedescription", "1", "If SteamTools is loaded, set the Game Description to Prop Hunt Redux?", _, true, 0.0, true, 1.0);
	g_PHAirblast = CreateConVar("ph_airblast", "0", "Allow Pyros to airblast? Takes effect on round change unless TF2Attributes is installed.", _, true, 0.0, true, 1.0);
	g_PHAntiHack = CreateConVar("ph_antihack", "1", "Make sure props don't have weapons. Leave this on unless you're having issues with other plugins.", _, true, 0.0, true, 1.0);
	g_PHReroll = CreateConVar("ph_propreroll", "0", "Control use of the propreroll command: -1 = Disabled, 0 = players with the propreroll override", _, true, -1.0, true, 0.0);
	g_PHStaticPropInfo = CreateConVar("ph_staticpropinfo", "1", "Kick players who have r_staticpropinfo set to 1?", _, true, 0.0, true, 1.0);
	
	// These are expensive and should be done just once at plugin start.
	g_hArenaRoundTime = FindConVar("tf_arena_round_time");
	g_hWeaponCriticals = FindConVar("tf_weapon_criticals");
	g_hIdledealmethod = FindConVar("mp_idledealmethod");
	g_hTournamentStopwatch = FindConVar("mp_tournament_stopwatch");
	g_hTournamentHideDominationIcons = FindConVar("tf_tournament_hide_domination_icons");
	g_hFriendlyfire = FindConVar("mp_friendlyfire");
	g_hGravity = FindConVar("sv_gravity");
	g_hForcecamera = FindConVar("mp_forcecamera");
	g_hArenaCapEnableTime = FindConVar("tf_arena_override_cap_enable_time");
	g_hTeamsUnbalanceLimit = FindConVar("mp_teams_unbalance_limit");
	g_hArenaMaxStreak = FindConVar("tf_arena_max_streak");
	g_hEnableRoundWaitTime = FindConVar("mp_enableroundwaittime");
	g_hWaitingForPlayerTime = FindConVar("mp_waitingforplayers_time");
	g_hArenaUseQueue = FindConVar("tf_arena_use_queue");
	g_hShowVoiceIcons = FindConVar("mp_show_voice_icons");
	g_hSolidObjects = FindConVar("tf_solidobjects");
	g_hArenaPreroundTime = FindConVar("tf_arena_preround_time");
	
	g_hBonusRoundTime = FindConVar("mp_bonusroundtime");
	
	HookConVarChange(g_PHEnable, OnEnabledChanged);
	HookConVarChange(g_PHAdvertisements, OnAdTextChanged);
	HookConVarChange(g_PHGameDescription, OnGameDescriptionChanged);
	HookConVarChange(g_PHAntiHack, OnAntiHackChanged);
	HookConVarChange(g_PHStaticPropInfo, OnAntiHackChanged);
	HookConVarChange(g_PHAirblast, OnAirblastChanged);
	HookConVarChange(g_PHPreventFallDamage, OnFallDamageChanged);

	g_Text1 = CreateHudSynchronizer();
	g_Text2 = CreateHudSynchronizer();
	g_Text3 = CreateHudSynchronizer();
	g_Text4 = CreateHudSynchronizer();

	AddServerTag("PropHunt");

	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("player_team", Event_player_team);
	HookEvent("player_death", Event_player_death, EventHookMode_Pre);
	HookEvent("arena_round_start", Event_arena_round_start);
	HookEvent("arena_win_panel", Event_arena_win_panel);
	HookEvent("post_inventory_application", Event_post_inventory_application);
	HookEvent("teamplay_broadcast_audio", Event_teamplay_broadcast_audio, EventHookMode_Pre);
	HookEvent("teamplay_round_start", Event_teamplay_round_start);
	//HookEvent("teamplay_setup_finished", Event_teamplay_setup_finished);

#if defined STATS
	Stats_Init();
#endif

	RegConsoleCmd("help", Command_motd);
	//RegConsoleCmd("motd", Command_motd);
	RegAdminCmd("propmenu", Command_propmenu, ADMFLAG_KICK, "Select a new prop from the prop menu if allowed.");
	RegAdminCmd("propreroll", Command_propreroll, ADMFLAG_KICK, "Change your prop. Useable once per round if allowed.");

	AddFileToDownloadsTable("sound/prophunt/found.mp3");
	AddFileToDownloadsTable("sound/prophunt/snaaake.mp3");
	AddFileToDownloadsTable("sound/prophunt/oneandonly.mp3");
	
	LoadTranslations("prophunt.phrases");
	LoadTranslations("common.phrases");
 
	//g_oFOV = FindSendPropOffs("CBasePlayer", "m_iFOV");
	//g_oDefFOV = FindSendPropOffs("CBasePlayer", "m_iDefaultFOV");
	
	g_Sounds = CreateTrie();
	g_BroadcastSounds = CreateTrie();
	
	loadGlobalConfig();
	
	RegAdminCmd("ph_respawn", Command_respawn, ADMFLAG_ROOT, "Respawns you");
	RegAdminCmd("ph_switch", Command_switch, ADMFLAG_BAN, "Switches to RED");
	RegAdminCmd("ph_internet", Command_internet, ADMFLAG_BAN, "Spams Internet");
	RegAdminCmd("ph_pyro", Command_pyro, ADMFLAG_BAN, "Switches to BLU");
	RegAdminCmd("ph_reloadconfig", Command_ReloadConfig, ADMFLAG_BAN, "Reloads the PropHunt configuration");

	//if((g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")) == -1)
	//LogError("Could not find offset for CBasePlayer::m_vecVelocity[0]");

	//CreateTimer(7.0, Timer_AntiHack, 0, TIMER_REPEAT);
	//CreateTimer(0.6, Timer_Locked, 0, TIMER_REPEAT);
	//CreateTimer(55.0, Timer_Score, 0, TIMER_REPEAT);


	for(new client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			ForcePlayerSuicide(client);
#if defined STATS
			OnClientPostAdminCheck(client);
#endif
		}
	}
	g_PropData = CreateTrie();
	ReadCommonPropData();
	
	AutoExecConfig(true, "prophunt_redux");
}

ReadCommonPropData()
{
	ClearTrie(g_PropData);
	
	decl String:Path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Path, sizeof(Path), "data/prophunt/prop_common.txt");
	new Handle:propCommon = CreateKeyValues("propcommon");
	if (!FileToKeyValues(propCommon, Path))
	{
		LogError("Could not load the g_PropData file!");
		return;
	}
	
	if (!KvGotoFirstSubKey(propCommon))
	{
		LogError("Prop Common file is empty!");
		return;
	}		
	
	new counter = 0;
	do
	{
		counter++;
		decl String:modelPath[PLATFORM_MAX_PATH];
		
		new propData[PropData];
		
		KvGetSectionName(propCommon, modelPath, PLATFORM_MAX_PATH);
		KvGetString(propCommon, "name", propData[PropData_Name], sizeof(propData[PropData_Name]), "");
		KvGetString(propCommon, "offset", propData[PropData_Offset], sizeof(propData[PropData_Offset]), "0 0 0");
		KvGetString(propCommon, "rotation", propData[PropData_Rotation], sizeof(propData[PropData_Rotation]), "0 0 0");
		
		if (!SetTrieArray(g_PropData, modelPath, propData[0], sizeof(propData)))
		{
			LogError("Error saving prop data for %s", modelPath);
		}
		
	} while (KvGotoNextKey(propCommon));
	
	LogMessage("Loaded %d props from props_common.txt", counter);
}

public OnAllPluginsLoaded()
{
	g_SteamTools = LibraryExists("SteamTools");
	if (g_SteamTools)
	{
		UpdateGameDescription();
	}
#if defined OIMM
	g_OptinMultiMod = LibraryExists("optin_multimod");
	if (g_OptinMultiMod)
	{
		OptInMultiMod_Register("Prop Hunt", ValidateMap, MultiMod_Status);
	}
#endif
}

loadGlobalConfig()
{
	decl String:Path[256];
	BuildPath(Path_SM, Path, sizeof(Path), "data/prophunt/prophunt_config.cfg");
	g_ConfigKeyValues = CreateKeyValues("prophunt_config");
	if (!FileToKeyValues(g_ConfigKeyValues, Path))
	{
		LogError("Could not load the PropHunt config file!");
	}
	
	config_parseWeapons();
	config_parseClasses();
	config_parseSounds();
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_SteamTools = true;
		UpdateGameDescription();
	}
#if defined OIMM	
	else
	if (StrEqual(name, "optin_multimod", false))
	{
		g_OptinMultiMod = true;
	}
#endif
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_SteamTools = false;
	}
#if defined OIMM
	else
	if (StrEqual(name, "optin_multimod", false))
	{
		g_OptinMultiMod = false;
	}
#endif
}

public OnGameDescriptionChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateGameDescription();
}

public OnAntiHackChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if ((GetConVarBool(g_PHAntiHack) || GetConVarBool(g_PHStaticPropInfo)) && g_hAntiHack == INVALID_HANDLE)
	{
		g_hAntiHack = CreateTimer(7.0, Timer_AntiHack, 0, TIMER_REPEAT);
	}
	else if (!GetConVarBool(g_PHAntiHack) && !GetConVarBool(g_PHStaticPropInfo) && g_hAntiHack != INVALID_HANDLE)
	{
		CloseHandle(g_hAntiHack);
		g_hAntiHack = INVALID_HANDLE;
	}
}

public OnAirblastChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:airblast = GetConVarBool(g_PHAirblast);

	new flamethrower = -1;
	
	while ((flamethrower = FindEntityByClassname(flamethrower, "tf_weapon_flamethrower")) != -1)
	{
		new iItemDefinitionIndex = GetEntProp(flamethrower, Prop_Send, "m_iItemDefinitionIndex");
		if (iItemDefinitionIndex != WEP_PHLOGISTINATOR || FindValueInArray(g_hWeaponStripAttribs, WEP_PHLOGISTINATOR) >= 0)
		{
			if (airblast)
			{
				TF2Attrib_RemoveByName(flamethrower, "airblast disabled");
			}
			else
			{
				TF2Attrib_SetByName(flamethrower, "airblast disabled", 1.0);
			}
		}
	}
}

public OnFallDamageChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:fall = GetConVarFloat(g_PHPreventFallDamage);
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		TF2Attrib_SetByName(i, "cancel falling damage", fall);
	}
}

UpdateGameDescription(bool:bAddOnly=false)
{
	if (!g_SteamTools)
	{
		return;
	}
	
	decl String:gamemode[128];
	if (g_Enabled && GetConVarBool(g_PHGameDescription))
	{
		if (strlen(g_AdText) > 0)
		{
			Format(gamemode, sizeof(gamemode), "PropHunt Redux %s (%s)", g_Version, g_AdText);
		}
		else
		{
			Format(gamemode, sizeof(gamemode), "PropHunt Redux %s", g_Version);
		}
	}
	else if (bAddOnly)
	{
		// Leave it alone if we're not running, should only be used when configs are executed
		return;
	}
	else
	{
		strcopy(gamemode, sizeof(gamemode), "Team Fortress");
	}
	
	Steam_SetGameDescription(gamemode);
}

config_parseWeapons()
{
	/*
	for(new i = 0; i < MAXITEMS; i++)
	{
		g_weaponNerfs[i] = 1.0;
		g_weaponSelfDamage[i] = 10.0;
		g_weaponRemovals[i] = false;
	}
	*/
	
	ClearArray(g_hWeaponRemovals);
	ClearTrie(g_hWeaponNerfs);
	ClearTrie(g_hWeaponSelfDamage);
	ClearArray(g_hWeaponStripAttribs);
	ClearTrie(g_hWeaponAddAttribs);
	ClearTrie(g_hWeaponReplacements);
	
	if (g_ConfigKeyValues == INVALID_HANDLE)
	{
		return;
	}
	
	while(KvGoBack(g_ConfigKeyValues))
	{
		continue;
	}
	
	if(KvJumpToKey(g_ConfigKeyValues, "items"))
	{
		do
		{
			decl String:SectionName[128];
			KvGotoFirstSubKey(g_ConfigKeyValues);
			KvGetSectionName(g_ConfigKeyValues, SectionName, sizeof(SectionName));
			if(KvGetDataType(g_ConfigKeyValues, "damage_hunters") == KvData_Float)
			{
				SetTrieValue(g_hWeaponNerfs, SectionName, KvGetFloat(g_ConfigKeyValues, "damage_hunters"));
			}
			if(KvGetDataType(g_ConfigKeyValues, "removed_hunters") == KvData_Int)
			{
				if (bool:KvGetNum(g_ConfigKeyValues, "removed_hunters"))
				{
					PushArrayCell(g_hWeaponRemovals, StringToInt(SectionName));
				}
			}
			if(KvGetDataType(g_ConfigKeyValues, "self_damage_hunters") == KvData_Float)
			{
				SetTrieValue(g_hWeaponSelfDamage, SectionName, KvGetFloat(g_ConfigKeyValues, "self_damage_hunters"));
			}
			if(KvGetDataType(g_ConfigKeyValues, "stripattribs") == KvData_Int)
			{
				if (bool:KvGetNum(g_ConfigKeyValues, "stripattribs"))
				{
					PushArrayCell(g_hWeaponStripAttribs, StringToInt(SectionName));
				}
			}
			if(KvGetDataType(g_ConfigKeyValues, "addattribs") == KvData_String)
			{
				new String:attribs[128];
				KvGetString(g_ConfigKeyValues, "addattribs", attribs, sizeof(attribs));
				
				if (attribs[0] != '\0')
				{
					SetTrieString(g_hWeaponAddAttribs, SectionName, attribs);
				}
			}
			if(KvGetDataType(g_ConfigKeyValues, "replace") == KvData_String)
			{
				new String:attribs[128];
				KvGetString(g_ConfigKeyValues, "replace", attribs, sizeof(attribs));
				
				if (attribs[0] != '\0')
				{
					SetTrieString(g_hWeaponReplacements, SectionName, attribs);
				}
			}
		}
		while(KvGotoNextKey(g_ConfigKeyValues));
	}
	else
	{
		LogMessage("[PH] Invalid config! Could not access subkey: items");
	}
}

config_parseClasses()
{
	new red = _:TFTeam_Red-2;
	new blue = _:TFTeam_Blue-2;
	g_defaultClass[red] = TFClass_Scout;
	g_defaultClass[blue] = TFClass_Pyro;
	
	for(new i = 0; i < 10; i++)
	{
		g_classLimits[blue][i] = -1;
		g_classLimits[red][i] = -1;
		g_classSpeeds[i][0] = 300.0;
		g_classSpeeds[i][1] = 400.0;
		g_classSpeeds[i][2] = 15.0;
	}
	
	if (g_ConfigKeyValues == INVALID_HANDLE)
	{
		return;
	}
	
	while(KvGoBack(g_ConfigKeyValues))
	{
		continue;
	}
	
	if(KvJumpToKey(g_ConfigKeyValues, "classes"))
	{
		do
		{
			decl String:SectionName[128];
			KvGotoFirstSubKey(g_ConfigKeyValues);
			KvGetSectionName(g_ConfigKeyValues, SectionName, sizeof(SectionName));
			if(KvGetDataType(g_ConfigKeyValues, "hunter_limit") == KvData_Int)
			{
				g_classLimits[blue][StringToInt(SectionName)] = KvGetNum(g_ConfigKeyValues, "hunter_limit");
			}
			if(KvGetDataType(g_ConfigKeyValues, "prop_limit") == KvData_Int)
			{
				g_classLimits[red][StringToInt(SectionName)] = KvGetNum(g_ConfigKeyValues, "prop_limit");
			}
			if(KvGetDataType(g_ConfigKeyValues, "hunter_default_class") == KvData_Int)
			{
				g_defaultClass[blue] = TFClassType:StringToInt(SectionName);
			}
			if(KvGetDataType(g_ConfigKeyValues, "prop_default_class") == KvData_Int)
			{
				g_defaultClass[red] = TFClassType:StringToInt(SectionName);
			}
			if(KvGetDataType(g_ConfigKeyValues, "base_speed") == KvData_Float)
			{
				g_classSpeeds[StringToInt(SectionName)][0] = KvGetFloat(g_ConfigKeyValues, "base_speed");
			}
			if(KvGetDataType(g_ConfigKeyValues, "max_speed") == KvData_Float)
			{
				g_classSpeeds[StringToInt(SectionName)][1] = KvGetFloat(g_ConfigKeyValues, "max_speed");
			}
			if(KvGetDataType(g_ConfigKeyValues, "speed_increment") == KvData_Float)
			{
				g_classSpeeds[StringToInt(SectionName)][2] = KvGetFloat(g_ConfigKeyValues, "speed_increment");
			}
			
		}
		while(KvGotoNextKey(g_ConfigKeyValues));
	}
	else
	{
		LogMessage("[PH] Invalid config! Could not access subkey: classes");
	}
}

config_parseSounds()
{
	ClearTrie(g_Sounds);
	ClearTrie(g_BroadcastSounds);
	
	if (g_ConfigKeyValues == INVALID_HANDLE)
	{
		return;
	}
	
	while(KvGoBack(g_ConfigKeyValues))
	{
		continue;
	}
	
	if(KvJumpToKey(g_ConfigKeyValues, "sounds"))
	{
		do
		{
			decl String:SectionName[128];
			KvGotoFirstSubKey(g_ConfigKeyValues);
			KvGetSectionName(g_ConfigKeyValues, SectionName, sizeof(SectionName));
			if(KvGetDataType(g_ConfigKeyValues, "sound") == KvData_String)
			{
				decl String:soundString[128];
				KvGetString(g_ConfigKeyValues, "sound", soundString, sizeof(soundString));
				
				if(PrecacheSound(soundString))
				{
					SetTrieString(g_Sounds, SectionName, soundString, true);
				}
			}
			if(KvGetDataType(g_ConfigKeyValues, "broadcast") == KvData_String)
			{
				decl String:soundString[128];
				KvGetString(g_ConfigKeyValues, "broadcast", soundString, sizeof(soundString));
				
				SetTrieString(g_BroadcastSounds, SectionName, soundString, true);
			}
			if(KvGetDataType(g_ConfigKeyValues, "game") == KvData_String)
			{
				decl String:soundString[128];
				KvGetString(g_ConfigKeyValues, "game", soundString, sizeof(soundString));
				
				SetTrieString(g_BroadcastSounds, SectionName, soundString, true);
			}
		}
		while(KvGotoNextKey(g_ConfigKeyValues));
	}
	else
	{
		LogMessage("[PH] Invalid config! Could not access subkey: sounds");
	}
}

SetCVars(){

	SetConVarFlags(g_hArenaRoundTime, GetConVarFlags(g_hArenaRoundTime) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaUseQueue, GetConVarFlags(g_hArenaUseQueue) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaMaxStreak, GetConVarFlags(g_hArenaMaxStreak) & ~(FCVAR_NOTIFY));
	//cvar = FindConVar("mp_tournament");
	//SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hTournamentStopwatch, GetConVarFlags(g_hTournamentStopwatch) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hTournamentHideDominationIcons, GetConVarFlags(g_hTournamentHideDominationIcons) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hTeamsUnbalanceLimit, GetConVarFlags(g_hTeamsUnbalanceLimit) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaPreroundTime, GetConVarFlags(g_hArenaPreroundTime) & ~(FCVAR_NOTIFY));

	g_ArenaRoundTime = GetConVarInt(g_hArenaRoundTime);
	SetConVarInt(g_hArenaRoundTime, 0, true);
	
	g_ArenaUseQueue = GetConVarInt(g_hArenaUseQueue);
	SetConVarInt(g_hArenaUseQueue, 0, true);

	g_ArenaMaxStreak = GetConVarInt(g_hArenaMaxStreak);
	SetConVarInt(g_hArenaMaxStreak, 4, true);
	
	g_TournamentStopwatch = GetConVarInt(g_hTournamentStopwatch);
	SetConVarInt(g_hTournamentStopwatch, 0, true);
	
	g_TournamentHideDominationIcons = GetConVarInt(g_hTournamentHideDominationIcons);
	SetConVarInt(g_hTournamentHideDominationIcons, 0, true);

	g_TeamsUnbalanceLimit = GetConVarInt(g_hTeamsUnbalanceLimit);
	SetConVarInt(g_hTeamsUnbalanceLimit, UNBALANCE_LIMIT, true);

	SetConVarBounds(g_hArenaPreroundTime, ConVarBound_Upper, false);
	g_ArenaPreroundTime = GetConVarInt(g_hArenaPreroundTime);
	SetConVarInt(g_hArenaPreroundTime, IsDedicatedServer() ? 20:5, true);
	
	g_WeaponCriticals = GetConVarInt(g_hWeaponCriticals);
	SetConVarInt(g_hWeaponCriticals, 1, true);
	
	g_Idledealmethod = GetConVarInt(g_hIdledealmethod);
	SetConVarInt(g_hIdledealmethod, 0, true);
	
	g_Friendlyfire = GetConVarInt(g_hFriendlyfire);
	SetConVarInt(g_hFriendlyfire, 0, true);
	
	g_Gravity = GetConVarInt(g_hGravity);
	SetConVarInt(g_hGravity, 500, true);
	
	g_Forcecamera = GetConVarInt(g_hForcecamera);
	SetConVarInt(g_hForcecamera, 1, true);
	
	g_ArenaCapEnableTime = GetConVarInt(g_hArenaCapEnableTime);
	SetConVarInt(g_hArenaCapEnableTime, 3600, true); // Set really high
	
	g_EnableRoundWaitTime = GetConVarInt(g_hEnableRoundWaitTime);
	SetConVarInt(g_hEnableRoundWaitTime, 0, true);

	g_WaitingForPlayerTime = GetConVarInt(g_hWaitingForPlayerTime);
	SetConVarInt(g_hWaitingForPlayerTime, 40, true);
	
	g_ShowVoiceIcons = GetConVarInt(g_hShowVoiceIcons);
	SetConVarInt(g_hShowVoiceIcons, 0, true);

	g_SolidObjects = GetConVarInt(g_hSolidObjects);
	SetConVarInt(g_hSolidObjects, 0, true);
	
	g_CvarsSet = true;
}

ResetCVars()
{
	if (!g_CvarsSet)
		return;
	
	SetConVarFlags(g_hArenaRoundTime, GetConVarFlags(g_hArenaRoundTime) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaUseQueue, GetConVarFlags(g_hArenaUseQueue) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaMaxStreak, GetConVarFlags(g_hArenaMaxStreak) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hTeamsUnbalanceLimit, GetConVarFlags(g_hTeamsUnbalanceLimit) & ~(FCVAR_NOTIFY));
	SetConVarFlags(g_hArenaPreroundTime, GetConVarFlags(g_hArenaPreroundTime) & ~(FCVAR_NOTIFY));

	SetConVarInt(g_hArenaRoundTime, g_ArenaRoundTime, true);
	SetConVarInt(g_hArenaUseQueue, g_ArenaUseQueue, true);
	SetConVarInt(g_hArenaMaxStreak, g_ArenaMaxStreak, true);
	SetConVarInt(g_hTournamentStopwatch, g_TournamentStopwatch, true);
	SetConVarInt(g_hTournamentHideDominationIcons, g_TournamentHideDominationIcons, true);
	SetConVarInt(g_hTeamsUnbalanceLimit, g_TeamsUnbalanceLimit, true);
	SetConVarInt(g_hArenaPreroundTime, g_ArenaPreroundTime, true);
	SetConVarInt(g_hWeaponCriticals, g_WeaponCriticals, true);
	SetConVarInt(g_hIdledealmethod, g_Idledealmethod, true);
	SetConVarInt(g_hFriendlyfire, g_Friendlyfire, true);
	SetConVarInt(g_hGravity, g_Gravity, true);
	SetConVarInt(g_hForcecamera, g_Forcecamera, true);
	SetConVarInt(g_hArenaCapEnableTime, g_ArenaCapEnableTime, true);
	SetConVarInt(g_hEnableRoundWaitTime, g_EnableRoundWaitTime, true);
	SetConVarInt(g_hWaitingForPlayerTime, g_WaitingForPlayerTime, true);
	SetConVarInt(g_hShowVoiceIcons, g_ShowVoiceIcons, true);
	SetConVarInt(g_hSolidObjects, g_SolidObjects, true);
	
	g_CvarsSet = false;
}

public OnConfigsExecuted()
{
	g_Enabled = GetConVarBool(g_PHEnable) && IsPropHuntMap();
	
	g_MapRunning = true;

	if (g_Enabled)
	{
		SetCVars();
	}
	UpdateGameDescription(true);
}

StartTimers(bool:noScoreTimer = false)
{
	if (g_hLocked == INVALID_HANDLE)
	{
		g_hLocked = CreateTimer(0.6, Timer_Locked, 0, TIMER_REPEAT);
	}
		
	if (!noScoreTimer && g_hScore == INVALID_HANDLE)
	{
		g_hScore = CreateTimer(55.0, Timer_Score, 0, TIMER_REPEAT);
	}

	if ((GetConVarBool(g_PHAntiHack) || GetConVarBool(g_PHStaticPropInfo)) && g_hAntiHack == INVALID_HANDLE)
	{
		g_hAntiHack = CreateTimer(7.0, Timer_AntiHack, 0, TIMER_REPEAT);
	}
}

StopTimers()
{
	if (g_hAntiHack != INVALID_HANDLE)
	{
		CloseHandle(g_hAntiHack);
		g_hAntiHack = INVALID_HANDLE;
	}
	
	if (g_hLocked != INVALID_HANDLE)
	{
		CloseHandle(g_hLocked);
		g_hLocked = INVALID_HANDLE;
	}
	
	if (g_hScore != INVALID_HANDLE)
	{
		CloseHandle(g_hScore);
		g_hScore = INVALID_HANDLE;
	}
}

public OnEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!g_MapRunning)
	{
		return;
	}
	
	if (GetConVarBool(g_PHEnable))
	{
		if (g_Enabled)
		{
			g_RoundChange = RoundChange_NoChange; // Reset in case it was RoundChange_Disable
		}
		else
		{
			new bool:enabled = IsPropHuntMap();
			if (enabled)
			{
				g_RoundChange = RoundChange_Enable;
			}
			else
			{
				g_RoundChange = RoundChange_NoChange;
			}
		}
	}
	else
	{
		if (g_Enabled)
		{
			g_RoundChange = RoundChange_Disable;
		}
		else
		{
			g_RoundChange = RoundChange_NoChange;
		}
	}
}

public OnAdTextChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_AdText, sizeof(g_AdText), newValue);
}

public StartTouchHook(entity, other)
{
	if(other <= MaxClients && other > 0 && !g_TouchingCP[other] && IsClientInGame(other) && IsPlayerAlive(other))
	{
		FillHealth(other);
		ExtinguishPlayer(other);
		PrintToChat(other, "%t", "#TF_PH_CPBonus");
		PH_EmitSoundToClient(other, "CPBonus", _, _, SNDLEVEL_AIRCRAFT);
		g_TouchingCP[other] = true;
	}
}

stock FillHealth (entity)
{
	if(IsValidEntity(entity))
	{
		SetEntityHealth(entity, GetEntProp(entity, Prop_Data, "m_iMaxHealth"));
	}
}

/*
stock bool:IsValidAdmin(client)
{
	decl String:flags[26];
	GetConVarString(g_PHAdmFlag, flags, sizeof(flags));
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	new iFlags = ReadFlagString(flags);
	if (GetUserFlagBits(client) & iFlags)
	{
		return true;
	}
	return false;
}
*/

stock ExtinguishPlayer (client){
	if(IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client))
	{
		ExtinguishEntity(client);
		TF2_RemoveCondition(client, TFCond_OnFire);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!g_Enabled)
	{
		return;
	}
	/*
	if(strcmp(classname, "team_control_point") == 0 ||
			strcmp(classname, "team_control_point_round") == 0 ||
			strcmp(classname, "trigger_capture_area") == 0 ||
			strcmp(classname, "func_respawnroom") == 0 ||
			strcmp(classname, "func_respawnroomvisualizer") == 0 ||
			strcmp(classname, "obj_sentrygun") == 0)
	{
		SDKHook(entity, SDKHook_Spawn, OnBullshitEntitySpawned);
	}
	else
	*/
	if (strcmp(classname, "obj_sentrygun") == 0)
	{
		SDKHook(entity, SDKHook_Spawn, OnBullshitEntitySpawned);
	}
	else
	if(strcmp(classname, "prop_dynamic") == 0 || strcmp(classname, "prop_static") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnCPEntitySpawned);
	}
	else
	if(strcmp(classname, "team_control_point_master") == 0)
	{
		SDKHook(entity, SDKHook_Spawn, OnCPMasterSpawned);
	}
	else
	if(strcmp(classname, "tf_weapon_builder") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnBuilderSpawned);
	}
}

public Action:OnBullshitEntitySpawned(entity)
{
	if(IsValidEntity(entity))
		AcceptEntityInput(entity, "Kill");
	
	return Plugin_Continue;
}

// This doesn't actually work, sadly.
// It SHOULD work, but doesn't
public Action:OnBuilderSpawned(entity)
{
	if(IsValidEntity(entity))
	{
		SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, _:TFObject_Sentry);
	}
	return Plugin_Continue;
}

public OnCPEntitySpawned(entity)
{
	decl String:propName[500];
	GetEntPropString(entity, Prop_Data, "m_ModelName", propName, sizeof(propName));
	if(StrEqual(propName, "models/props_gameplay/cap_point_base.mdl"))
	{
		// Reset the skin to neutral.  I'm looking at you, cp_manor_event
		SetVariantInt(0);
		AcceptEntityInput(entity, "Skin");
		// Also, hook it for the heal touch hook
		SDKHook(entity, SDKHook_StartTouch, StartTouchHook);
	}
}

public Action:OnCPMasterSpawned(entity)
{
	if (!g_MapStarted)
	{
		return Plugin_Continue;
	}
	
	new arenaLogic = FindEntityByClassname(-1, "tf_logic_arena");
	if (arenaLogic == -1)
	{
		return Plugin_Continue;
	}
	
	SetEntProp(entity, Prop_Data, "m_bSwitchTeamsOnWin", 0); // Changed in 3.0.0 beta 6, now forced off instead of on.

	decl String:time[5];
	IntToString(g_RoundTime - 30, time, sizeof(time));
	
	decl String:name[64];
	if (GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name)) == 0)
	{
		DispatchKeyValue(entity, "targetname", "master_control_point");
		strcopy(name, sizeof(name), "master_control_point");
	}
	
	new timer = CreateEntityByName("team_round_timer");
	DispatchKeyValue(timer, "targetname", TIMER_NAME);
	DispatchKeyValue(timer, "setup_length", "30");
	DispatchKeyValue(timer, "reset_time", "1");
	DispatchKeyValue(timer, "auto_countdown", "1");
	DispatchKeyValue(timer, "timer_length", time);
	DispatchSpawn(timer);

	decl String:finishedCommand[256];
	
	Format(finishedCommand, sizeof(finishedCommand), "OnFinished %s:SetWinner:%d:0:-1", name, _:TFTeam_Red);
	SetVariantString(finishedCommand);
	AcceptEntityInput(timer, "AddOutput");

	Format(finishedCommand, sizeof(finishedCommand), "OnArenaRoundStart %s:Resume:0:0:-1", TIMER_NAME);
	SetVariantString(finishedCommand);
	AcceptEntityInput(arenaLogic, "AddOutput");
	
	Format(finishedCommand, sizeof(finishedCommand), "OnArenaRoundStart %s:ShowInHUD:1:0:-1", TIMER_NAME);
	SetVariantString(finishedCommand);
	AcceptEntityInput(arenaLogic, "AddOutput");
	
	HookSingleEntityOutput(timer, "OnSetupFinished", OnSetupFinished);

	return Plugin_Continue;
}

public OnMapEnd()
{
#if defined STATS
	g_MapChanging = true;
#endif

	// workaround for CreateEntityByName
	g_MapStarted = false;
	g_MapRunning = false;
	
	ResetCVars();
	StopTimers();
	g_Enabled = false;
	for (new client = 1; client<=MaxClients; client++)
		g_CurrentlyFlying[client] = false;
}

public OnMapStart()
{
	// workaround no win panel event - admin changes, rtv, etc.
	g_RoundOver = true;
	//g_inPreRound = true;
	
	ReadCommonPropData();
	
	GetCurrentMap(g_Mapname, sizeof(g_Mapname));

	new arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
	g_ModelName = CreateArray(arraySize);
	g_ModelOffset = CreateArray(arraySize);
	g_ModelRotation = CreateArray(arraySize);
	PushArrayString(g_ModelName, "models/props_gameplay/cap_point_base.mdl");
	PushArrayString(g_ModelOffset, "0 0 -2");
	PushArrayString(g_ModelRotation, "0 0 0");
	
#if defined STATS
	g_MapChanging = false;
#endif

	if (g_PropMenu != INVALID_HANDLE)
	{
		CloseHandle(g_PropMenu);
		g_PropMenu = INVALID_HANDLE;
	}
	g_PropMenu = CreateMenu(Handler_PropMenu);
	SetMenuTitle(g_PropMenu, "PropHunt Prop Menu");
	SetMenuExitButton(g_PropMenu, true);
	AddMenuItem(g_PropMenu, "models/player/pyro.mdl", "models/player/pyro.mdl");
	AddMenuItem(g_PropMenu, "models/props_halloween/ghost.mdl", "models/props_halloween/ghost.mdl");

	decl String:confil[192], String:buffer[256], String:offset[32], String:rotation[32], String:tidyname[2][32], String:maptidyname[128];
	ExplodeString(g_Mapname, "_", tidyname, 2, 32);
	Format(maptidyname, sizeof(maptidyname), "%s_%s", tidyname[0], tidyname[1]);
	BuildPath(Path_SM, confil, sizeof(confil), "data/prophunt/maps/%s.cfg", maptidyname);
	new Handle:fl = CreateKeyValues("prophuntmapconfig");

	if(!FileToKeyValues(fl, confil))
	{
		LogMessage("[PH] Config file for map %s not found at %s. Disabling plugin.", maptidyname, confil);
		CloseHandle(fl);
		g_Enabled = false;
		return;
	}
	else
	{
		PrintToServer("Successfully loaded %s", confil);
		KvGotoFirstSubKey(fl);
		KvJumpToKey(fl, "Props", false);
		KvGotoFirstSubKey(fl);
		do
		{
			KvGetSectionName(fl, buffer, sizeof(buffer));
			PushArrayString(g_ModelName, buffer);
			AddMenuItem(g_PropMenu, buffer, buffer);
			KvGetString(fl, "offset", offset, sizeof(offset), "0 0 0");
			PushArrayString(g_ModelOffset, offset);
			KvGetString(fl, "rotation", rotation, sizeof(rotation), "0 0 0");
			PushArrayString(g_ModelRotation, rotation);
		}
		while (KvGotoNextKey(fl));
		KvRewind(fl);
		KvJumpToKey(fl, "Settings", false);

		g_Doors = bool:KvGetNum(fl, "doors", 0);
		g_Relay = bool:KvGetNum(fl, "relay", 0);
		g_Freeze = bool:KvGetNum(fl, "freeze", 1);
		g_RoundTime = KvGetNum(fl, "round", 175);

		PrintToServer("Successfully parsed %s", confil);
		PrintToServer("Loaded %i models, doors: %i, relay: %i, freeze: %i, round time: %i.", GetArraySize(g_ModelName)-1, g_Doors ? 1:0, g_Relay ? 1:0, g_Freeze ? 1:0, g_RoundTime);
	}
	CloseHandle(fl);

	decl String:model[100];

	for(new i = 0; i < GetArraySize(g_ModelName); i++)
	{
		GetArrayString(g_ModelName, i, model, sizeof(model));
		if(PrecacheModel(model, true) == 0)
		{
			RemoveFromArray(g_ModelName, i);
		}
	}

	PrecacheModel(FLAMETHROWER, true);
	
	/*new ent = FindEntityByClassname(-1, "team_control_point_master");
	if (ent == 1)
	{
		AcceptEntityInput(ent, "Kill");
	}
	ent = CreateEntityByName("team_control_point_master");
	DispatchKeyValue(ent, "switch_teams", "1");
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "Enable");*/
	
	// workaround for CreateEntityByNsme
	g_MapStarted = true;

	loadGlobalConfig();
	
	// Clear the replacement weapon list
	for (new i = 1; i <= MaxClients; ++i)
	{
		for (new j = 0; j < sizeof(g_Replacements[]); ++j)
		{
			g_Replacements[i][j] = -1;
		}
		g_ReplacementCount[i] = 0;
	}
}

/*
public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (strlen(g_AdText) > 0)
	Format(gameDesc, sizeof(gameDesc), "PropHunt %s (%s)", g_Version, g_AdText);
	else
	Format(gameDesc, sizeof(gameDesc), "PropHunt %s", g_Version);
	
	return Plugin_Changed;
}
*/

public OnPluginEnd()
{
	PrintCenterTextAll("%t", "#TF_PH_PluginReload");
#if defined STATS
	Stats_Uninit();
#endif
	ResetCVars();
	if (g_SteamTools)
	{
		Steam_SetGameDescription("Team Fortress");
	}
#if defined OIMM
	if (g_OptinMultiMod)
	{
		OptInMultiMod_Unregister("Prop Hunt");
	}
#endif
}

public Action:TakeDamageHook(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (!g_Enabled)
	{
		return Plugin_Continue;
	}
	
	if(victim > 0 && attacker > 0 && victim < MaxClients && attacker < MaxClients && IsClientInGame(victim) && IsPlayerAlive(victim) && GetClientTeam(victim) == _:TFTeam_Red
			&& IsClientInGame(attacker) && GetClientTeam(attacker) == _:TFTeam_Blue)
	{

		if(!g_Hit[victim])
		{
			new Float:pos[3];
			GetClientAbsOrigin(victim, pos);
			PH_EmitSoundToClient(victim, "PropFound", _, SNDCHAN_WEAPON, _, _, 0.8, _, victim, pos);
			PH_EmitSoundToClient(attacker, "PropFound", _, SNDCHAN_WEAPON, _, _, 0.8, _, victim, pos);
			g_Hit[victim] = true;
		}
	}
	
	if(weapon > MaxClients && IsValidEntity(weapon))
	{
		new String:weaponIndex[10];
		IntToString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), weaponIndex, sizeof(weaponIndex));
		
		new Float:multiplier;
		if (GetTrieValue(g_hWeaponNerfs, weaponIndex, multiplier))
		{
			damage *= multiplier;
			return Plugin_Changed;
		}
	}
	
	//block prop drowning
	if(damagetype & DMG_DROWN && victim > 0 && victim < MaxClients && IsClientInGame(victim) && GetClientTeam(victim) == _:TFTeam_Red && attacker == 0)
	{
		damage = 0.0;
		return Plugin_Changed;
	}

	if(GetConVarBool(g_PHPreventFallDamage) && damagetype & DMG_FALL && victim > 0 && victim < MaxClients && IsClientInGame(victim) && attacker == 0)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock RemoveAnimeModel (client){
	if(IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client))
	{
		SetVariantString("0 0 0");
		AcceptEntityInput(client, "SetCustomModelOffset");

		AcceptEntityInput(client, "ClearCustomModelRotation");
		
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
	}
}

public OnClientDisconnect(client)
{
#if defined STATS
	OCD(client);
#endif
}

public OnClientDisconnect_Post(client)
{
	ResetPlayer(client);
#if defined STATS
	OCD_Post(client);
#endif
}

stock SwitchView (target, bool:observer, bool:viewmodel){
	g_First[target] = !observer;
	/*SetEntPropEnt(target, Prop_Send, "m_hObserverTarget", observer ? target:-1);
	SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1:0);
	SetEntData(target, g_oFOV, observer ? 100:GetEntData(target, g_oDefFOV, 4), 4, true);
	SetEntProp(target, Prop_Send, "m_bDrawViewmodel", viewmodel ? 1:0);*/
	
	SetVariantInt(observer ? 1 : 0);
	AcceptEntityInput(target, "SetForcedTauntCam");

	SetVariantInt(observer ? 1 : 0);
	AcceptEntityInput(target, "SetCustomModelVisibletoSelf");
}

/*
stock ForceTeamWin (team){
	new ent = FindEntityByClassname(-1, "team_control_point_master");
	if (ent == -1)
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchKeyValue(ent, "targetname", "master_control_point");
		DispatchKeyValue(ent, "StartDisabled", "0");
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(ent, "SetWinner");
}
*/

public Action:Command_jointeam(client, args)
{
	decl String:argstr[16];
	GetCmdArgString(argstr, sizeof(argstr));
	if(StrEqual(argstr, "spectatearena"))
	{
		g_Spec[client] = true;
	}
	else
	{
		g_Spec[client] = false;
	}
	return Plugin_Continue;
}

public Action:Command_ReloadConfig(client, args)
{
	loadGlobalConfig();
	ReplyToCommand(client, "PropHunt Config reloaded");
	return Plugin_Handled;
}

public Action:Command_propmenu(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	if(GetConVarInt(g_PHPropMenu) == 0)
	{
		if(GetClientTeam(client) == _:TFTeam_Red && IsPlayerAlive(client))
		{
			if (GetCmdArgs() == 1)
			{
				decl String:model[MAXMODELNAME];
				GetCmdArg(1, model, MAXMODELNAME);
				strcopy(g_PlayerModel[client], MAXMODELNAME, model); 
				Timer_DoEquip(INVALID_HANDLE, GetClientUserId(client));
			}
			else
			{
				DisplayMenu(g_PropMenu, client, MENU_TIME_FOREVER);
			}
		}
		else
		{
			PrintToChat(client, "%t", "#TF_PH_PropMenuNotRedOrAlive");
		}
	}
	else
	{
		PrintToChat(client, "%t", "#TF_PH_PropMenuNoAccess");
	}
	return Plugin_Handled;
}

public Action:Command_propreroll(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	if(GetConVarInt(g_PHReroll) == 0)
	{
		if(GetClientTeam(client) == _:TFTeam_Red && IsPlayerAlive(client))
		{
			if (!g_Rerolled[client])
			{
				g_Rerolled[client] = true;
				g_PlayerModel[client] = "";
				Timer_DoEquip(INVALID_HANDLE, GetClientUserId(client));
			}
			else
			{
				PrintToChat(client, "%t", "#TF_PH_PropRerollLimit");
			}
		}
		else
		{
			PrintToChat(client, "%t", "#TF_PH_PropRerollNotRedOrAlive");
		}
	}
	else
	{
		PrintToChat(client, "%t", "#TF_PH_PropRerollNoAccess");
	}
	return Plugin_Handled;
}

public Handler_PropMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
	case MenuAction_Select:
		{
			if(IsClientInGame(param1))
			{
				if(GetConVarInt(g_PHPropMenu) == 1 || CheckCommandAccess(param1, "propmenu", ADMFLAG_KICK))
				{
					if(GetClientTeam(param1) == _:TFTeam_Red && IsPlayerAlive(param1))
					{
						GetMenuItem(menu, param2, g_PlayerModel[param1], MAXMODELNAME);
						Timer_DoEquip(INVALID_HANDLE, GetClientUserId(param1));
					}
					else
					{
						PrintToChat(param1, "%t", "#TF_PH_PropMenuNotRedOrAlive");
					}
				}
				else
				{
					PrintToChat(param1, "%t", "#TF_PH_PropMenuNoAccess");
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if (!g_Enabled)
		return;
	
	if (!IsFakeClient(client))
	{
		SendConVarValue(client, g_hArenaRoundTime, "600");
	}
	ResetPlayer(client);
}

public ResetPlayer(client)
{
	g_Spawned[client] = false;
	g_Charge[client] = false;
	g_AllowedSpawn[client] = false;
	g_Hit[client] = false;
	g_Attacking[client] = false;
	g_RotLocked[client] = false;
	g_Spec[client] = false;
	g_TouchingCP[client] = false;
	g_First[client] = false;
	g_PlayerModel[client] = "";
	g_SetClass[client] = false;
}

public Action: Command_respawn(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	if (client < 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	TF2_RespawnPlayer(client);
	return Plugin_Handled;
}

public Action:Command_internet(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	decl String:name[255];
	for(new i = 0; i < 3; i++)
	{
		PH_EmitSoundToAll("Internet", _, _, SNDLEVEL_AIRCRAFT);
	}
	GetClientName(client, name, sizeof(name));
	return Plugin_Handled;
}

PH_EmitSoundToAll(const String:soundid[], entity = SOUND_FROM_PLAYER, channel = SNDCHAN_AUTO, level = SNDLEVEL_NORMAL, flags = SND_NOFLAGS, Float:volume = SNDVOL_NORMAL, pitch = SNDPITCH_NORMAL, speakerentity = -1, const Float:origin[3] = NULL_VECTOR, const Float:dir[3] = NULL_VECTOR, bool:updatePos = true, Float:soundtime = 0.0)
{
	decl String:sample[128];
	
	if(GetTrieString(g_BroadcastSounds, soundid, sample, sizeof(sample)))
	{
		if (!EmitGameSoundToAll(sample, entity, flags, speakerentity, origin, dir, updatePos, soundtime))
		{
			new Handle:broadcastEvent = CreateEvent("teamplay_broadcast_audio");
			SetEventInt(broadcastEvent, "team", -1); // despite documentation saying otherwise, it's team -1 for all (docs say team 0)
			SetEventString(broadcastEvent, "sound", sample);
			FireEvent(broadcastEvent);
		}
	}
	else if(GetTrieString(g_Sounds, soundid, sample, sizeof(sample)))
	{
		if(!IsSoundPrecached(sample))
		{
			PrecacheSound(sample);
		}
		EmitSoundToAll(sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	}
}

PH_EmitSoundToClient(client, const String:soundid[], entity = SOUND_FROM_PLAYER, channel = SNDCHAN_AUTO, level = SNDLEVEL_NORMAL, flags = SND_NOFLAGS, Float:volume = SNDVOL_NORMAL, pitch = SNDPITCH_NORMAL, speakerentity = -1, const Float:origin[3] = NULL_VECTOR, const Float:dir[3] = NULL_VECTOR, bool:updatePos = true, Float:soundtime = 0.0)
{
	decl String:sample[128];
	
	if(GetTrieString(g_BroadcastSounds, soundid, sample, sizeof(sample)))
	{
		EmitGameSoundToClient(client, sample, entity, flags, speakerentity, origin, dir, updatePos, soundtime);
	}
	else if(GetTrieString(g_Sounds, soundid, sample, sizeof(sample)))
	{
		if(!IsSoundPrecached(sample))
		{
			PrecacheSound(sample);
		}
		EmitSoundToClient(client, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	}
}

public Action:Command_switch(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	if (client < 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	g_AllowedSpawn[client] = true;
	ChangeClientTeam(client, _:TFTeam_Red);
	TF2_RespawnPlayer(client);
	CreateTimer(0.5, Timer_Move, client);
	return Plugin_Handled;
}

public Action:Command_pyro(client, args)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	if (client < 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	g_PlayerModel[client] = "";
	g_AllowedSpawn[client] = true;
	ChangeClientTeam(client, _:TFTeam_Blue);
	TF2_RespawnPlayer(client);
	CreateTimer(0.5, Timer_Move, client);
	CreateTimer(0.8, Timer_Unfreeze, client);
	return Plugin_Handled;
}
stock PlayersAlive (){
	new alive = 0;
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		alive++;
	}
	return alive;
}

/*
public StopPreroundTimers(bool:instant)
{
	StopTimer(g_TimerStart);
	for (new i = 0; i < sizeof(g_CountdownSoundTimers); i++)
	{
		if(g_CountdownSoundTimers[i] != INVALID_HANDLE)
		{
			StopTimer(g_CountdownSoundTimers[i]);
		}
	}
	if(instant)
	{
		StopTimer(g_RoundTimer);
	}
	else
	{
		CreateTimer(2.0, Timer_AfterWinPanel);
	}
}
*/


stock ChangeClientTeamAlive (client, team)
{
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	SetEntProp(client, Prop_Send, "m_lifeState", 0);
}

stock GetRandomPlayer (team)
{
	new client, totalclients;

	for(client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			totalclients++;
		}
	}

	new clientarray[totalclients], i;
	for(client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			clientarray[i] = client;
			i++;
		}
	}

	do
	{
		client = clientarray[GetRandomInt(0, totalclients-1)];
	}
	while( !(IsClientInGame(client) && GetClientTeam(client) == team) );
	return client;
}

stock StopTimer (Handle:timer)
{
	if(timer != INVALID_HANDLE) KillTimer(timer);
	timer = INVALID_HANDLE;
}

stock bool:IsPropHuntMap ()
{
	return ValidateMap(g_Mapname);
}


public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(!g_Enabled || g_RoundOver)
		return Plugin_Continue;
	
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Blue && IsValidEntity(weapon))
	{
		if(strcmp(weaponname, "tf_weapon_flamethrower") == 0)
			g_CurrentlyFlying[client] = true;
		else
			DoSelfDamage(client, weapon);
		
		result = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if (!g_Enabled || g_RoundOver || !g_CurrentlyFlying[client])
	{
		return Plugin_Continue;
	}
	
	if (buttons & IN_ATTACK != IN_ATTACK)
	{
		g_CurrentlyFlying[client] = false;
		return Plugin_Continue;
	}

	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Blue && IsValidEntity(weapon))
	{
		DoSelfDamage(client, weapon);

		AddVelocity(client, 1.0);
	}	
	return Plugin_Continue;
}

stock DoSelfDamage(client, weapon)
{
	new Float:damage;
	
	new String:weaponIndex[10];
	IntToString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), weaponIndex, sizeof(weaponIndex));
	
	if (!GetTrieValue(g_hWeaponSelfDamage, weaponIndex, damage))
	{
		damage = 10.0;
	}
	
	SDKHooks_TakeDamage(client, client, weapon, damage, DMG_PREVENT_PHYSICS_FORCE);
}

stock AddVelocity (client, Float:speed){
	new Float:velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	//GetEntDataVector(client, g_iVelocity, velocity);

	// fucking win
	if(velocity[0] < 200 && velocity[0] > -200)
	velocity[0] *= (1.08 * speed);
	if(velocity[1] < 200 && velocity[1] > -200)
	velocity[1] *= (1.08 * speed);
	if(velocity[2] > 0 && velocity[2] < 400)
	velocity[2] = velocity[2] * 1.15 * speed;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
}

public Action:SetTransmitHook(entity, client)
{
	if(g_First[client] && client == entity)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public PreThinkHook(client)
{
	if (!g_Enabled)
		return;
	
	if(IsClientInGame(client))
	{

		if(IsPlayerAlive(client))
		{
			if(!(TF2_IsPlayerInCondition(client, TFCond_Slowed) || TF2_IsPlayerInCondition(client, TFCond_Zoomed) || 
			TF2_IsPlayerInCondition(client, TFCond_Bonked) || TF2_IsPlayerInCondition(client, TFCond_Dazed) || 
			TF2_IsPlayerInCondition(client, TFCond_Charging) || TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly)))
			{
				ResetSpeed(client);
			}
			
			new buttons = GetClientButtons(client);
			if((buttons & IN_ATTACK) == IN_ATTACK && GetClientTeam(client) == _:TFTeam_Blue)
			{
				g_Attacking[client] = true;
			}
			else
			{
				g_Attacking[client] = false;
			}

			if(GetClientTeam(client) == _:TFTeam_Red)
			{
				// tl;dr - (LMB and not crouching OR any movement key while locked) AND not holding key
				if(((((buttons & IN_ATTACK) == IN_ATTACK && (buttons & IN_DUCK) != IN_DUCK) ||
								((buttons & IN_FORWARD) == IN_FORWARD || (buttons & IN_MOVELEFT) == IN_MOVELEFT || (buttons & IN_MOVERIGHT) == IN_MOVERIGHT ||
									(buttons & IN_BACK) == IN_BACK || (buttons & IN_JUMP) == IN_JUMP) && g_RotLocked[client])) && !g_HoldingLMB[client]
						)
				{
					g_HoldingLMB[client] = true;
					if(GetPlayerWeaponSlot(client, 0) == -1)
					{

						if(!g_RotLocked[client])
						{
							new Float:velocity[3];
							GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
							//GetEntDataVector(client, g_iVelocity, velocity);
							// if the client is moving, don't allow them to lock in place
							if(velocity[0] > -5 && velocity[1] > -5 && velocity[2] > -5 && velocity[0] < 5 && velocity[1] < 5 && velocity[2] < 5)
							{
								SetVariantInt(0);
								AcceptEntityInput(client, "SetCustomModelRotates");
								g_RotLocked[client] = true;
#if defined LOCKSOUND
								PH_EmitSoundToClient(client, "LockSound", _, _, _, _, LOCKVOL);
#endif
							}

						}
						else
						if(g_RotLocked[client])
						{
							SetVariantInt(1);
							AcceptEntityInput(client, "SetCustomModelRotates");
#if defined LOCKSOUND
							PH_EmitSoundToClient(client, "UnlockSound", _, _, _, _, LOCKVOL);
#endif
							g_RotLocked[client] = false;
						}
					}
				}
				else if((buttons & IN_ATTACK) != IN_ATTACK)
				{
					g_HoldingLMB[client] = false;
				}

				if((buttons & IN_ATTACK2) == IN_ATTACK2 && !g_HoldingRMB[client])
				{
					g_HoldingRMB[client] = true;
					if(g_First[client])
					{
						PrintHintText(client, "Third Person mode selected");
						SwitchView(client, true, false);
					}
					else
					{
						PrintHintText(client, "First Person mode selected");
						SwitchView(client, false, false);
					}

				}
				else
				if((buttons & IN_ATTACK2) != IN_ATTACK2)
				{
					g_HoldingRMB[client] = false;
				}
#if defined CHARGE
				if((buttons & IN_RELOAD) == IN_RELOAD)
				{
					if(!g_Charge[client])
					{
						g_Charge[client] = true;
						//SetEntData(client, g_offsCollisionGroup, COLLISION_GROUP_DEBRIS_TRIGGER, _, true);
						SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);
						TF2_SetPlayerClass(client, TFClass_DemoMan, false);
						TF2_AddCondition(client, TFCond_Charging, 2.5);
						CreateTimer(2.5, Timer_Charge, client);
					}
				}
#endif
			}
			else
			if(GetClientTeam(client) == _:TFTeam_Blue && TF2_GetPlayerClass(client) == TFClass_Pyro)
			{
				/*
				if(IsValidEntity(GetPlayerWeaponSlot(client, 1)) && GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex") == WEP_SHOTGUNPYRO || IsValidEntity(GetPlayerWeaponSlot(client, 1)) && GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex") == WEP_SHOTGUN_UNIQUE)
				{
					SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + 8, SHOTGUN_MAX_AMMO-GetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")));
					if(GetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")) > SHOTGUN_MAX_AMMO)
					{
						SetEntData(GetPlayerWeaponSlot(client, 1), FindSendPropInfo("CBaseCombatWeapon", "m_iClip1"), SHOTGUN_MAX_AMMO);
					}
				}
				*/
				new shotgun = GetPlayerWeaponSlot(client, 1);
				if(IsValidEntity(shotgun))
				{
					new index = GetEntProp(shotgun, Prop_Send, "m_iItemDefinitionIndex");
					if (index == WEP_SHOTGUNPYRO || index == WEP_SHOTGUN_UNIQUE)
					{
						new ammoOffset = GetEntProp(shotgun, Prop_Send, "m_iPrimaryAmmoType");
						new clip = GetEntProp(shotgun, Prop_Send, "m_iClip1");
						SetEntProp(client, Prop_Send, "m_iAmmo", SHOTGUN_MAX_AMMO - clip, _, ammoOffset);
						if (clip > SHOTGUN_MAX_AMMO)
						{
							SetEntProp(shotgun, Prop_Send, "m_iClip1", SHOTGUN_MAX_AMMO);
						}
					}
				}
				
			}

		} // alive
	} // in game
}

/*
public SetupRoundTime(time)
{
	g_RoundTimer = CreateTimer(float(time-1), Timer_TimeUp, _, TIMER_FLAG_NO_MAPCHANGE);
	SetConVarInt(g_hArenaRoundTime, time, true, false);
}
*/

public GetClassCount(TFClassType:class, team) 
{
	new classCount;
	for(new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == team && TF2_GetPlayerClass(client) == class)
		{
			classCount++;
		}
	}
	return classCount;
}


public Action:Command_motd(client, args)
{
	if (client <= 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	if(IsClientInGame(client))
	{
		ShowMOTDPanel(client, "PropHunt Stats", "http://www.gamingmasters.org/prophunt/index.php", MOTDPANEL_TYPE_URL);
	}
	return Plugin_Handled;
}


stock SetAlpha (target, alpha){
	SetWeaponsAlpha(target,alpha);
	SetEntityRenderMode(target, RENDER_TRANSCOLOR);
	SetEntityRenderColor(target, 255, 255, 255, alpha);
}

stock SetWeaponsAlpha (target, alpha){
	if(IsPlayerAlive(target))
	{
		//decl String:classname[64];
		
		/*
		// Old version
		new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
		for(new i = 0, weapon; i < 47; i += 4)
		{
			weapon = GetEntDataEnt2(target, m_hMyWeapons + i);
			if(weapon > -1 && IsValidEdict(weapon))
			{
				GetEdictClassname(weapon, classname, sizeof(classname));
				if(StrContains(classname, "tf_weapon", false) != -1)
				{
					SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
					SetEntityRenderColor(weapon, 255, 255, 255, alpha);
				}
			}
		}
		*/
	
		/*
		// "New" old version
		// There are 47 weapon slots of offsets 0 - 188, the previous code was unfortunately wrong.
		for(new i = 0, weapon; i <= 47; ++i)
		{
			weapon = GetEntPropEnt(target, Prop_Send, "m_hMyWeapons", i);
			if(weapon > -1 && IsValidEdict(weapon))
			{
				GetEdictClassname(weapon, classname, sizeof(classname));
				if(StrContains(classname, "tf_weapon", false) != -1)
				{
					SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
					SetEntityRenderColor(weapon, 255, 255, 255, alpha);
				}
			}
		}
		*/
		
		// TF2 only supports 1 weapon per slot, so save time and just check all 6 slots.
		// Engy is the only class with 6 items (3 weapons, 2 tools, and an invisible builder)
		for(new i = 0; i <= 5; ++i)
		{
			new weapon = GetPlayerWeaponSlot(target, i);
			if(weapon > -1 && IsValidEdict(weapon))
			{
				// Don't bother checking the classname, it's always tf_weapon_[something] in TF2 for GetPlayerWeaponSlot
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, alpha);
			}
		}
	}
}

public Speedup (client)
{
	new TFClassType:clientClass = TF2_GetPlayerClass(client);
	
	new Float:clientSpeed = g_currentSpeed[client] + g_classSpeeds[clientClass][2];
	
	if(clientSpeed < g_classSpeeds[clientClass][0])
	{
		clientSpeed = g_classSpeeds[clientClass][0];
	}
	else if(clientSpeed > g_classSpeeds[clientClass][1])
	{
		clientSpeed = g_classSpeeds[clientClass][1];
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", clientSpeed);
	
	g_currentSpeed[client]  = clientSpeed;
}

ResetSpeed (client)
{	
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_currentSpeed[client]);
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return entity != data;
}

public Action:Event_teamplay_broadcast_audio(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	decl String:sound[64];
	GetEventString(event, "sound", sound, sizeof(sound));
	
	if (StrEqual(sound, "Announcer.AM_RoundStartRandom", false))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetEventInt(event, "team") > 1)
	{
		g_Spec[client] = false;
	}
}

public Event_arena_win_panel(Handle:event, const String:name[], bool:dontBroadcast)
{
	StopTimers();
#if defined LOG
	LogMessage("[PH] round end");
#endif

	g_RoundOver = true;
	//g_inPreRound = true;
	g_LastProp = false;
	
	if (!g_Enabled)
		return;

#if defined STATS
	new winner = GetEventInt(event, "winning_team");
	DbRound(winner);
#endif

	CreateTimer(GetConVarInt(g_hBonusRoundTime) - 0.1, Timer_ChangeTeam, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	
	SetConVarInt(g_hTeamsUnbalanceLimit, 0, true);

//	new team, client;
	new client;
	for(client=1; client <= MaxClients; client++)
	{
		g_CurrentlyFlying[client] = false;
		
		if(IsClientInGame(client))
		{
#if defined STATS
			if(GetClientTeam(client) == winner)
			{
				AlterScore(client, 3, ScReason_TeamWin, 0);
			}
			else
			if(GetClientTeam(client) != TEAM_SPEC)
			{
				AlterScore(client, -1, ScReason_TeamLose, 0);
			}
#endif
			// bit annoying when testing the plugin and/or maps on a listen server
			/*
			if(IsDedicatedServer())
			{
				team = GetClientTeam(client);
				if(team == _:TFTeam_Red || team == _:TFTeam_Blue)
				{
					team = team == _:TFTeam_Red ? _:TFTeam_Blue:_:TFTeam_Red;
					ChangeClientTeamAlive(client, team);
				}
			}
			*/
		}
		ResetPlayer(client);
	}
/*
#if defined LOG
	LogMessage("Team balancing...");
#endif
	decl String:cname[64];
	while(GetTeamClientCount(_:TFTeam_Red) > GetTeamClientCount(_:TFTeam_Blue) + 1 )
	{
		client = GetRandomPlayer(_:TFTeam_Red);
		GetClientName(client, cname, sizeof(cname));
		PrintToChatAll("%t", "#TF_PH_BalanceBlu", cname);
		ChangeClientTeamAlive(client, _:TFTeam_Blue);
	}
	while(GetTeamClientCount(_:TFTeam_Blue) > GetTeamClientCount(_:TFTeam_Red) +1 )
	{
		client = GetRandomPlayer(_:TFTeam_Blue);
		GetClientName(client, cname, sizeof(cname));
		PrintToChatAll("%t", "#TF_PH_BalanceRed", cname);
		ChangeClientTeamAlive(client, _:TFTeam_Red);
	}
#if defined LOG
	LogMessage("Complete");
#endif
*/

	SetConVarFlags(g_hTeamsUnbalanceLimit, GetConVarFlags(g_hTeamsUnbalanceLimit) & ~(FCVAR_NOTIFY));
	SetConVarInt(g_hTeamsUnbalanceLimit, UNBALANCE_LIMIT, true);

	//StopPreroundTimers(false);
}

public Action:Timer_ChangeTeam(Handle:timer)
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (GetClientTeam(i) == _:TFTeam_Blue)
		{
			ChangeClientTeamAlive(i, _:TFTeam_Red);
		}
		else
		if (GetClientTeam(i) == _:TFTeam_Red)
		{
			SetVariantString("");
			AcceptEntityInput(i, "SetCustomModel");
			ChangeClientTeamAlive(i, _:TFTeam_Blue);
		}
		
	}
	
	return Plugin_Continue;
}

/*
public Action:Event_teamplay_round_start_pre(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled)
		return;
	
	new bool:reset = GetEventBool(event, "full_reset");
#if defined LOG
	LogMessage("[PH] teamplay round start: %i, %i", reset, g_RoundOver);
#endif
	// checking for the first time this calls (pre-setup), i think
	if(reset && g_RoundOver)
	{
		new team, zteam=_:TFTeam_Blue;
		for(new client=1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{

				team = GetClientTeam(client);

				// prevent sitting out
				if(team == TEAM_SPEC && !g_Spec[client])
				{
					ChangeClientTeam(client, zteam);
					zteam = zteam == _:TFTeam_Blue ? _:TFTeam_Red:_:TFTeam_Blue;
				}

			}
		}
	}
}
*/

public Event_post_inventory_application(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_ReplacementCount[client] > 0)
	{
	
		for (new i = 0; i < g_ReplacementCount[client]; ++i)
		{
			// DON'T require FORCE_GENERATION here, since they could pass back tf_weapon_shotgun 
			new Handle:weapon = TF2Items_CreateItem(OVERRIDE_ALL);
			
			new String:defIndex[7];
			IntToString(g_Replacements[client][i], defIndex, sizeof(defIndex));
			
			new String:replacement[140];
			if (!GetTrieString(g_hWeaponReplacements, defIndex, replacement, sizeof(replacement)))
			{
				continue;
			}
			new String:pieces[5][128];
			
			ExplodeString(replacement, ":", pieces, sizeof(pieces), sizeof(pieces[]));

			TrimString(pieces[Item_Classname]);
			TrimString(pieces[Item_Index]);
			TrimString(pieces[Item_Quality]);
			TrimString(pieces[Item_Level]);
			TrimString(pieces[Item_Attributes]);
			
			new index = StringToInt(pieces[Item_Index]);
			new quality = StringToInt(pieces[Item_Quality]);
			new level = StringToInt(pieces[Item_Level]);
			TF2Items_SetClassname(weapon, pieces[Item_Classname]);
			TF2Items_SetItemIndex(weapon, index);
			TF2Items_SetQuality(weapon, quality);
			TF2Items_SetLevel(weapon, level);
			
			new attribCount = 0;
			if (strlen(pieces[Item_Attributes]) > 0)
			{
				new String:newAttribs[32][6];
				new count = ExplodeString(pieces[Item_Attributes], ";", newAttribs, sizeof(newAttribs), sizeof(newAttribs[]));
				if (count % 2 > 0)
				{
					LogError("Error parsing replacement attributes for item definition index %d", g_Replacements[client][i]);
					return;
				}
				
				for (new j = 0; j < count && attribCount < 16; j += 2)
				{
					new attrib = StringToInt(newAttribs[i]);
					new Float:value = StringToFloat(newAttribs[i+1]);
					TF2Items_SetAttribute(weapon, attribCount++, attrib, value);
				}
			}
			
			TF2Items_SetNumAttributes(weapon, attribCount);
			
			new item = TF2Items_GiveNamedItem(client, weapon);
			EquipPlayerWeapon(client, item);
			g_Replacements[client][i] = -1;
			CloseHandle(weapon);
		}
		
		g_ReplacementCount[client] = 0;
	}

}

public Event_teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	StopTimers();

	switch (g_RoundChange)
	{
		case RoundChange_Enable:
		{
			g_Enabled = true;
			SetCVars();
			UpdateGameDescription();
			g_RoundChange = RoundChange_NoChange;
		}
		
		case RoundChange_Disable:
		{
			g_Enabled = false;
			ResetCVars();
			UpdateGameDescription();
			g_RoundChange = RoundChange_NoChange;			
		}
	}
	
	if (!g_Enabled)
		return;

	g_inPreRound = true;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			// For some reason, this has to be set every round or the player GUI messes up
			SendConVarValue(i, FindConVar("tf_arena_round_time"), "600");
		}
		g_Rerolled[i] = false;
	}
	// Delay freeze by a frame
	CreateTimer(0.0, Timer_teamplay_round_start);
	
	// Arena maps should have a team_control_point_master already, but just in case...
	new ent = FindEntityByClassname(-1, "team_control_point_master");
	if (ent == -1)
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchKeyValue(ent, "targetname", "master_control_point");
		DispatchKeyValue(ent, "StartDisabled", "0");
		DispatchSpawn(ent);
	}

	//GameMode Explanation
	decl String:message[256];
	ent=FindEntityByClassname(-1, "tf_gamerules");

	//BLU
	Format(message, sizeof(message), "%T", "#TF_PH_BluHelp", LANG_SERVER);
	SetVariantString(message);
	AcceptEntityInput(ent, "SetBlueTeamGoalString");
	SetVariantString("2");
	AcceptEntityInput(ent, "SetBlueTeamRole");

	//RED
	Format(message, sizeof(message), "%T", "#TF_PH_RedHelp", LANG_SERVER);
	SetVariantString(message);
	AcceptEntityInput(ent, "SetRedTeamGoalString");
	SetVariantString("1");
	AcceptEntityInput(ent, "SetRedTeamRole");

}

public Action:Timer_teamplay_round_start(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsClientObserver(i))
		{
			SetEntityMoveType(i, MOVETYPE_NONE);
		}
	}
}

public Event_arena_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	
#if defined LOG
	LogMessage("[PH] round start - %i", g_RoundOver );
#endif
	g_inPreRound = false;
	
	if (!g_Enabled)
		return;
	
	StartTimers(true);
	
	if(g_RoundOver)
	{
		// bl4nk mentions arena_round_start, but I think he meant teamplay_round_start
		CreateTimer(0.0, Timer_arena_round_start);
		
		//SetupRoundTime(g_RoundTime);
		
		CreateTimer(0.1, Timer_Info);

#if defined STATS
		g_StartTime = GetTime();
#endif
	}
}

public Action:Timer_arena_round_start(Handle:timer)
{
	for(new client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(GetClientTeam(client) == _:TFTeam_Red)
			{
				Timer_DoEquip(INVALID_HANDLE, GetClientUserId(client));
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
			else
			{
				Timer_DoEquipBlu(INVALID_HANDLE, GetClientUserId(client));
				if (!g_Freeze)
				{
					SetEntityMoveType(client, MOVETYPE_WALK);
				}
			}
			g_currentSpeed[client] = g_classSpeeds[TF2_GetPlayerClass(client)][0]; // Reset to default speed.
		}
	}
}

stock bool:IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

public Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled)
		return;
	
	new red = _:TFTeam_Red - 2;
	new blue = _:TFTeam_Blue - 2;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client, false)){
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
	}
	
	g_currentSpeed[client] = g_classSpeeds[TF2_GetPlayerClass(client)][0]; // Reset to default speed.
	
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		// stupid glitch fix
		if(!g_RoundOver && !g_AllowedSpawn[client])
		{
			ForcePlayerSuicide(client);
			return;
		}
		RemoveAnimeModel(client);
		SDKHook(client, SDKHook_OnTakeDamage, TakeDamageHook);
		SDKHook(client, SDKHook_PreThink, PreThinkHook);
#if defined LOG
		LogMessage("[PH] Player spawn %N", client);
#endif
		g_Hit[client] = false;

		if(GetClientTeam(client) == _:TFTeam_Blue)
		{

			PrintToChat(client, "%t", "#TF_PH_WaitingPeriodStarted");
#if defined SHINX

			new TFClassType:clientClass = TF2_GetPlayerClass(client);
			if (g_classLimits[blue][clientClass] != -1 && GetClassCount(clientClass, _:TFTeam_Blue) > g_classLimits[blue][clientClass])
			{
				if(g_classLimits[blue][clientClass] == 0)
				{
					//PrintToChat(client, "%t", "#TF_PH_ClassBlocked");
				}
				else
				{
					PrintToChat(client, "%t", "#TF_PH_ClassFull");
				}
				
				TF2_SetPlayerClass(client, g_defaultClass[blue]);
				TF2_RespawnPlayer(client);
				
				return;
			}
			
#else
			if(TF2_GetPlayerClass(client) != g_defaultClass[blue])
			{
				TF2_SetPlayerClass(client, g_defaultClass[blue]);
				TF2_RespawnPlayer(client);
				return;
			}
#endif
			CreateTimer(0.1, Timer_DoEquipBlu, GetClientUserId(client));

		}
		else
		if(GetClientTeam(client) == _:TFTeam_Red)
		{
			if(g_RoundOver)
			{
				SetEntityMoveType(client, MOVETYPE_NONE);
			}
			
			SetVariantString("");
			AcceptEntityInput(client, "DisableShadow");
			
			if(TF2_GetPlayerClass(client) != g_defaultClass[red])
			{
				TF2_SetPlayerClass(client, TFClassType:g_defaultClass[red]);
				TF2_RespawnPlayer(client);
			}
			CreateTimer(0.1, Timer_DoEquip, GetClientUserId(client));
		}
		
		if (g_inPreRound)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
	}
}

public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled)
		return Plugin_Continue;
	
	if (GetEventInt(event, "weaponid") == TF_WEAPON_BAT_FISH && GetEventInt(event, "customkill") == TF_CUSTOM_FISH_KILL)
	{
		return Plugin_Continue;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_CurrentlyFlying[client] = false;

	if(IsClientInGame(client) && GetClientTeam(client) == _:TFTeam_Red)
	{
#if defined LOG
		LogMessage("[PH] Player death %N", client);
#endif
		//RemoveAnimeModel(client);

		CreateTimer(0.1, Timer_Ragdoll, client);

		SDKUnhook(client, SDKHook_OnTakeDamage, TakeDamageHook);
		SDKUnhook(client, SDKHook_PreThink, PreThinkHook);
	}

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
#if defined STATS
	decl String:weapon[64];
	new assisterID = GetEventInt(event, "assister");
	new attackerID = GetEventInt(event, "attacker");
	new clientID = GetEventInt(event, "userid");
	new weaponid = GetEventInt(event, "weaponid");
	GetEventString(event, "weapon", weapon, sizeof(weapon));
#endif

	if(!g_RoundOver)
	g_Spawned[client] = false;

	g_Hit[client] = false;

	new playas = 0;
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) /*&& !IsFakeClient(i)*/ && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
		{
			playas++;
		}
	}


	if(!g_RoundOver && GetClientTeam(client) == _:TFTeam_Red)
	{

		PH_EmitSoundToClient(client, "PropDeath");
	}

	if(!g_RoundOver)
	{
		if(client > 0 && attacker > 0 && IsClientInGame(client) && IsClientInGame(attacker) && client != attacker)
		{
#if defined STATS
			PlayerKilled(clientID, attackerID, assisterID, weaponid, weapon);
#endif
			if(IsPlayerAlive(attacker))
			{
				Speedup(attacker);
				FillHealth(attacker);
			}
			
			if(assister > 0 && IsClientInGame(assister))
			{
				if(IsPlayerAlive(assister))
				{
					Speedup(assister);
					FillHealth(assister);
				}
			}
			
		}
	}

	if(playas == 2 && !g_RoundOver && GetClientTeam(client) == _:TFTeam_Red)
	{
		g_LastProp = true;
		PH_EmitSoundToAll("OneAndOnly", _, _, SNDLEVEL_AIRCRAFT);
#if defined SCATTERGUN
		for(new client2=1; client2 <= MaxClients; client2++)
		{
			if(IsClientInGame(client2) && !IsFakeClient(client2) && IsPlayerAlive(client2))
			{
				if(GetClientTeam(client2) == _:TFTeam_Red)
				{
					TF2_RegeneratePlayer(client2);
					CreateTimer(0.1, Timer_WeaponAlpha, client2);
				}
				else
				if(GetClientTeam(client2) == _:TFTeam_Blue)
				{
					TF2_AddCondition(client2, TFCond_Jarated, 15.0);
				}
			}
		}
#endif
	}
	// This is to kill the particle effects from the Harvest Ghost prop and the like
	SetVariantString("ParticleEffectStop");
	AcceptEntityInput(client, "DispatchEffect");
	return Plugin_Continue;
}

//////////////////////////////////////////////////////
///////////////////  TIMERS  ////////////////////////
////////////////////////////////////////////////////


public Action:Timer_WeaponAlpha(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	SetWeaponsAlpha(client, 0);
}

public Action:Timer_Info(Handle:timer, any:client)
{
	g_Message_bit++;

	if(g_Message_bit == 2)
	{
		SetHudTextParamsEx(-1.0, 0.22, 5.0, {0,204,255,255}, {0,0,0,255}, 2, 1.0, 0.05, 0.5);
		for(new i=1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				ShowSyncHudText(i, g_Text1, "PropHunt %s", g_Version);
			}
		}
	}
	else if(g_Message_bit == 3)
	{
		SetHudTextParamsEx(-1.0, 0.25, 4.0, {255,128,0,255}, {0,0,0,255}, 2, 1.0, 0.05, 0.5);
		for(new i=1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				ShowSyncHudText(i, g_Text2, "By Darkimmortal, Geit, and Powerlord");
			}
		}
	}
	else if(g_Message_bit == 4 && strlen(g_AdText) > 0)
	{
		SetHudTextParamsEx(-1.0, 0.3, 3.0, {0,220,0,255}, {0,0,0,255}, 2, 1.0, 0.05, 0.5);
		for(new i=1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				ShowSyncHudText(i, g_Text3, g_AdText);
			}
		}
	}
	
	if(g_Message_bit < 10 && IsValidEntity(g_Message_red) && IsValidEntity(g_Message_blue))
	{
		AcceptEntityInput(g_Message_red, "Display");
		AcceptEntityInput(g_Message_blue, "Display");
		CreateTimer(1.0, Timer_Info);
	}
}

public Action:Timer_DoEquipBlu(Handle:timer, any:UserId)
{
	new client = GetClientOfUserId(UserId);
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(g_inPreRound)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}

		SwitchView(client, false, true);
		SetAlpha(client, 255);
		
		new validWeapons;
		
		for (new i = 0; i < 3; i++)
		{
			new playerItemSlot = GetPlayerWeaponSlot(client, i);
			
			if(playerItemSlot > MaxClients && IsValidEntity(playerItemSlot))
			{
				validWeapons++;
			}
		}
		
		if(validWeapons == 0)
		{
			TF2_SetPlayerClass(client, TFClass_Pyro);
			g_AllowedSpawn[client] = true;
			TF2_RespawnPlayer(client);
		}
	}
	return Plugin_Handled;
}

public Action:Timer_DoEquip(Handle:timer, any:UserId)
{
	new client = GetClientOfUserId(UserId);
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		//TF2_RegeneratePlayer(client);
		
		#if defined LOG
				LogMessage("[PH] do equip %N", client);
		#endif
		// Lets comment this out since we don't block RED weapons with TF2Items
		// slot commands fix "remember last weapon" glitch, despite their client console spam
		/*
		FakeClientCommand(client, "slot0");
		FakeClientCommand(client, "slot3");
		TF2_RemoveAllWeapons(client);
		FakeClientCommand(client, "slot3");
		FakeClientCommand(client, "slot0");
		*/
		decl String:pname[32];
		Format(pname, sizeof(pname), "ph_player_%i", client);
		DispatchKeyValue(client, "targetname", pname);
		#if defined LOG
				LogMessage("[PH] do equip_2 %N", client);
		#endif
		
		new propData[PropData];
		
		// fire in a nice random model
		decl String:model[MAXMODELNAME];
		new String:offset[32] = "0 0 0";
		new String:rotation[32] = "0 0 0";
		new modelIndex = -1;
		if(strlen(g_PlayerModel[client]) > 1)
		{
			model = g_PlayerModel[client];
			modelIndex = FindStringInArray(g_ModelName, model);
		}
		else
		{
			modelIndex = GetRandomInt(0, GetArraySize(g_ModelName)-1);
			GetArrayString(g_ModelName, modelIndex, model, sizeof(model));
		}
		
		// This wackiness with [0] is required when dealing with enums containing strings
		if (GetTrieArray(g_PropData, model, propData[0], sizeof(propData)))
		{
			strcopy(offset, sizeof(offset), propData[PropData_Offset]);
			strcopy(rotation, sizeof(rotation), propData[PropData_Rotation]);
			PrintToChat(client, "%t", "#TF_PH_NowDisguised", propData[PropData_Name]);
		}
		
		if (modelIndex > -1)
		{
			new String:tempOffset[32];
			new String:tempRotation[32];
			GetArrayString(g_ModelOffset, modelIndex, tempOffset, sizeof(tempOffset));
			GetArrayString(g_ModelRotation, modelIndex, tempRotation, sizeof(tempRotation));
			TrimString(tempOffset);
			TrimString(tempRotation);
			// We don't want to override the default value unless it's set to something other than "0 0 0"
			if (!StrEqual(tempOffset, "0 0 0"))
			{
				strcopy(offset, sizeof(offset), tempOffset);
			}
			if (!StrEqual(tempRotation, "0 0 0"))
			{
				strcopy(rotation, sizeof(rotation), tempRotation);
			}
		}
		
		#if defined LOG
				LogMessage("[PH] do equip_3 %N", client);
		#endif

		#if defined LOG
				LogMessage("[PH] do equip_4 %N", client);
		#endif
		// This is to kill the particle effects from the Harvest Ghost prop and the like
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(client, "DispatchEffect");
		
		g_PlayerModel[client] = model;
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetVariantString(offset);
		AcceptEntityInput(client, "SetCustomModelOffset");
		if (StrEqual(rotation, "0 0 0"))
		{
			AcceptEntityInput(client, "ClearCustomModelRotation");
		}
		else
		{
			SetVariantString(rotation);
			AcceptEntityInput(client, "SetCustomModelRotation");
		}
		SetVariantInt(1);
		AcceptEntityInput(client, "SetCustomModelRotates");
		SwitchView(client, true, false);
		#if defined LOG
				LogMessage("[PH] do equip_5 %N", client);
		#endif
		
		if(!g_inPreRound)
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
	return Plugin_Handled;
}

public Action:Timer_Locked(Handle:timer, any:entity)
{
	for(new client=1; client <= MaxClients; client++)
	{
		if(g_RotLocked[client] && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Red)
		{
			SetHudTextParamsEx(0.05, 0.05, 0.7, { /*0,204,255*/ 220, 90, 0, 255}, {0,0,0,0}, 1, 0.2, 0.2, 0.2);
			ShowSyncHudText(client, g_Text4, "PropLock Engaged");
		}
	}
}

public Action:Timer_AntiHack(Handle:timer, any:entity)
{
	new red = _:TFTeam_Red - 2;
	if(!g_RoundOver && !g_LastProp)
	{
		decl String:name[64];
		for(new client=1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				if (GetConVarBool(g_PHStaticPropInfo) && !IsFakeClient(client))
				{
					QueryClientConVar(client, "r_staticpropinfo", QueryStaticProp);
				}
				
				if(GetConVarBool(g_PHAntiHack) && GetClientTeam(client) == _:TFTeam_Red && TF2_GetPlayerClass(client) == g_defaultClass[red])
				{
					if(GetPlayerWeaponSlot(client, 1) != -1 || GetPlayerWeaponSlot(client, 0) != -1 || GetPlayerWeaponSlot(client, 2) != -1)
					{
						GetClientName(client, name, sizeof(name));
						PrintToChatAll("\x04%t", "#TF_PH_WeaponPunish", name);
						SwitchView(client, false, true);
						//ForcePlayerSuicide(client);
						g_PlayerModel[client] = "";
						Timer_DoEquip(INVALID_HANDLE, GetClientUserId(client));
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public QueryStaticProp(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (result == ConVarQuery_Okay)
	{
		new value = StringToInt(cvarValue);
		if (value == 0)
		{
			return;
		}
		KickClient(client, "r_staticpropinfo was enabled");
		return;
	}
	KickClient(client, "r_staticpropinfo detection was blocked");
}

public Action:Timer_Ragdoll(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(rag > MaxClients && IsValidEntity(rag))
		AcceptEntityInput(rag, "Kill");
	}
	RemoveAnimeModel(client);
	
	return Plugin_Handled;
}

public Action:Timer_Score(Handle:timer, any:entity)
{
	for(new client=1; client <= MaxClients; client++)
	{
#if defined STATS
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == _:TFTeam_Red)
		{
			AlterScore(client, 2, ScReason_Time, 0);
		}
#endif
		g_TouchingCP[client] = false;
	}
	PrintToChatAll("\x03%t", "#TF_PH_CPBonusRefreshed");
}

// This used to hook the teamplay_setup_finished event, but ph_kakariko messes with that
//public Action:Event_teamplay_setup_finished(Handle:event, const String:name[], bool:dontBroadcast)
public OnSetupFinished(const String:output[], caller, activator, Float:delay)
{
	if (g_hScore != INVALID_HANDLE)
	{
		CloseHandle(g_hScore);
	}
	g_hScore = CreateTimer(55.0, Timer_Score, 0, TIMER_REPEAT);
	TriggerTimer(g_hScore);
	
#if defined LOG
	LogMessage("[PH] Timer_Start");
#endif
	g_RoundOver = false;

	for(new client2=1; client2 <= MaxClients; client2++)
	{
		if(IsClientInGame(client2) && IsPlayerAlive(client2))
		{
			SetEntityMoveType(client2, MOVETYPE_WALK);
		}
	}
	PrintToChatAll("%t", "#TF_PH_PyrosReleased");
	PH_EmitSoundToAll("RoundStart", _, _, SNDLEVEL_AIRCRAFT);

	new ent;
	if(g_Doors)
	{
		while ((ent = FindEntityByClassname(ent, "func_door")) != -1)
		{
			AcceptEntityInput(ent, "Open");
		}
	}

	if(g_Relay)
	{
		decl String:relayName[128];
		while ((ent = FindEntityByClassname(ent, "logic_relay")) != -1)
		{
			GetEntPropString(ent, Prop_Data, "m_iName", relayName, sizeof(relayName));
			if(strcmp(relayName, "hidingover", false) == 0)
			AcceptEntityInput(ent, "Trigger");
		}
	}
//	g_TimerStart = INVALID_HANDLE;
	//return Plugin_Handled;

}

#if defined CHARGE
public Action:Timer_Charge(Handle:timer, any:client)
{
	new red = _:TFTeam_Red-2;
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		//SetEntData(client, g_offsCollisionGroup, COLLISION_GROUP_PLAYER, _, true);
		SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
		TF2_SetPlayerClass(client, g_defaultClass[red], false);
	}
	return Plugin_Handled;
}
#endif

/*
public TimeEnd(const String:output[], caller, activator, Float:delay)
{
#if defined LOG
	LogMessage("[PH] Time Up");
#endif
	if(!g_RoundOver)
	{
		ForceTeamWin(_:TFTeam_Red);
		g_RoundOver = true;
		g_inPreRound = true;
	}
}
*/

/*
public Action:Timer_TimeUp(Handle:timer, any:lol)
{
#if defined LOG
	LogMessage("[PH] Time Up");
#endif
	if(!g_RoundOver)
	{
		ForceTeamWin(_:TFTeam_Red);
		g_RoundOver = true;
		g_inPreRound = true;
	}
	g_RoundTimer = INVALID_HANDLE;
	return Plugin_Handled;
}
*/

/*
public Action:Timer_AfterWinPanel(Handle:timer, any:lol)
{
#if defined LOG
	LogMessage("[PH] After Win Panel");
#endif
	StopTimer(g_RoundTimer);
}
*/

public Action:Timer_Unfreeze(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
		SetEntityMoveType(client, MOVETYPE_WALK);
	return Plugin_Handled;
}

public Action:Timer_Move(Handle:timer, any:client)
{
	g_AllowedSpawn[client] = false;
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		new rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEntity(rag))
		AcceptEntityInput(rag, "Kill");
		SetEntityMoveType(client, MOVETYPE_WALK);
		if(GetClientTeam(client) == _:TFTeam_Blue)
		{
			CreateTimer(0.1, Timer_DoEquipBlu, GetClientUserId(client));
		}
		else
		{
			CreateTimer(0.1, Timer_DoEquip, GetClientUserId(client));
		}
	}
	return Plugin_Handled;
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	// This section is to prevent Handle leaks
	static Handle:weapon = INVALID_HANDLE;
	if (weapon != INVALID_HANDLE)
	{
		CloseHandle(weapon);
		weapon = INVALID_HANDLE;
	}
	
	if (!g_Enabled)
		return Plugin_Continue;
	
	// Spectators shouldn't have their items
	if (IsClientObserver(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	if (GetClientTeam(client) == _:TFTeam_Red)
	{
		// If they're not the last prop, don't give them anything
		if (!g_LastProp)
		{
			return Plugin_Stop;
		}
		
		// Block wearables, action items, and canteens for Props
		// From testing, Action items still work even if you block them
		if (StrEqual(classname, "tf_wearable", false) || StrEqual(classname, "tf_powerup_bottle", false) || StrEqual(classname, "tf_weapon_spellbook", false))
		{
			return Plugin_Stop;
		}
	}

	new String:defIndex[7];
	IntToString(iItemDefinitionIndex, defIndex, sizeof(defIndex));
	
	new flags;	
	
	new String:replacement[140];
	new String:addAttributes[128];
	new bool:replace = GetTrieString(g_hWeaponReplacements, defIndex, replacement, sizeof(replacement));
	new bool:stripattribs = FindValueInArray(g_hWeaponStripAttribs , iItemDefinitionIndex) >= 0;
	new bool:addattribs = GetTrieString(g_hWeaponAddAttribs, defIndex, addAttributes, sizeof(addAttributes));
	new bool:removeAirblast = !GetConVarBool(g_PHAirblast) && StrEqual(classname, "tf_weapon_flamethrower");
	new String:pieces[5][128];

	if (replace)
	{
//		ExplodeString(replacement, ":", pieces, sizeof(pieces), sizeof(pieces[]));
//		if (!StrEqual(classname, pieces[Item_Classname], false))
//		{
			g_Replacements[client][g_ReplacementCount[client]++] = iItemDefinitionIndex;
			return Plugin_Stop;
//		}
		
//		flags |= OVERRIDE_ALL;
//		flags &= ~OVERRIDE_CLASSNAME; // This hasn't worked for a while
	}

	// If we're supposed to remove it, just block it here
	if (FindValueInArray(g_hWeaponRemovals, iItemDefinitionIndex) >= 0)
	{
		return Plugin_Stop;
	}
	
	if (!replace && !stripattribs && !addattribs && !removeAirblast)
	{
		return Plugin_Continue;
	}
	
	new bool:weaponChanged = false;
	
	if (stripattribs)
	{
		weaponChanged = true;
	}
	else
	{
		flags |= PRESERVE_ATTRIBUTES;
	}
	
	flags |= OVERRIDE_ATTRIBUTES;
	
	weapon = TF2Items_CreateItem(flags);

	new attribCount = 0;
	// 594 is Phlogistinator and already has airblast disabled
	if (removeAirblast && (iItemDefinitionIndex != WEP_PHLOGISTINATOR || stripattribs))
	{
		TF2Items_SetAttribute(weapon, attribCount++, 356, 1.0); // "airblast disabled"
		weaponChanged = true;
	}
	
	if (replace)
	{
		TrimString(pieces[Item_Index]);
		TrimString(pieces[Item_Quality]);
		TrimString(pieces[Item_Level]);
		TrimString(pieces[Item_Attributes]);

		new index = StringToInt(pieces[Item_Index]);
		new quality = StringToInt(pieces[Item_Quality]);
		new level = StringToInt(pieces[Item_Level]);
		TF2Items_SetItemIndex(weapon, index);
		TF2Items_SetQuality(weapon, quality);
		TF2Items_SetLevel(weapon, level);
		
		if (strlen(pieces[Item_Attributes]) > 0)
		{
			new String:newAttribs[32][6];
			new count = ExplodeString(pieces[Item_Attributes], ";", newAttribs, sizeof(newAttribs), sizeof(newAttribs[]));
			if (count % 2 > 0)
			{
				LogError("Error parsing replacement attributes for item definition index %d", iItemDefinitionIndex);
				return Plugin_Continue;
			}
			
			for (new i = 0; i < count && attribCount < 16; i += 2)
			{
				new attrib = StringToInt(newAttribs[i]);
				new Float:value = StringToFloat(newAttribs[i+1]);
				TF2Items_SetAttribute(weapon, attribCount++, attrib, value);
			}
		}
		weaponChanged = true;
	}
	
	if (addattribs)
	{
		// Pawn is dumb and this "shadows" a preceding variable despite being at a different block level
		new String:newAttribs2[32][6];
		new count = ExplodeString(addAttributes, ";", newAttribs2, sizeof(newAttribs2), sizeof(newAttribs2[]));
		if (count % 2 > 0)
		{
			LogError("Error parsing additional attributes for item definition index %d", iItemDefinitionIndex);
			return Plugin_Continue;
		}
		
		for (new i = 0; i < count && attribCount < 16; i += 2)
		{
			new attrib = StringToInt(newAttribs2[i]);
			new Float:value = StringToFloat(newAttribs2[i+1]);
			TF2Items_SetAttribute(weapon, attribCount++, attrib, value);
		}
	}
	
	if (attribCount > 0)
	{
		TF2Items_SetNumAttributes(weapon, attribCount);
		weaponChanged = true;
	}
		
	if (weaponChanged)
	{
		hItem = weapon;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

#if defined OIMM
public MultiMod_Status(bool:enabled)
{
	SetConVarBool(g_PHEnable, enabled);
}
#endif

public bool:ValidateMap(const String:map[])
{
	// As per SourceMod standard, anything dealing with map names should now be PLATFORM_MAX_PATH long
	new String:confil[PLATFORM_MAX_PATH], String:tidyname[2][PLATFORM_MAX_PATH], String:maptidyname[PLATFORM_MAX_PATH];
	ExplodeString(map, "_", tidyname, sizeof(tidyname), sizeof(tidyname[]));
	Format(maptidyname, sizeof(maptidyname), "%s_%s", tidyname[0], tidyname[1]);
	BuildPath(Path_SM, confil, sizeof(confil), "data/prophunt/maps/%s.cfg", maptidyname);

	return FileExists(confil, true);
}