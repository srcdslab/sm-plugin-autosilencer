/*  SM Autosilencer
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
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

bool primary[2048];
bool g_bIsAutoSEnabled[MAXPLAYERS + 1] = {false, ...};
Handle g_hCookie = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "SM Autosilencer",
	author = "Franc1sco franug, Dolly, .Rushaway",
	description = "AutoSilence m4a1 and usp",
	version = "1.3.1",
	url = "https://github.com/srcdslab/sm-plugin-autosilencer"
};

public void OnPluginStart()
{
	/* TRANSLATIONS */
	LoadTranslations("autosilencer.phrases.txt");
	LoadTranslations("common.phrases.txt"); // Yes - No
	LoadTranslations("clientprefs.phrases.txt"); // Clients Settings

	/* PUBLIC COMMANDS */
	RegConsoleCmd("sm_autosilencer", Command_AutoSilencer);

	/* COOKIES */
	g_hCookie = RegClientCookie("Autosilencer On/Off", "", CookieAccess_Public);
	SetCookieMenuItem(AutoSilencerCookieHandler, 0, "AutoSilencer Settings");
	
	/* LATE LOAD */
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
			if (AreClientCookiesCached(i))
				OnClientCookiesCached(i);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{    
	if (StrContains(classname, "weapon_") == 0) 
	{
		primary[entity] = false;
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client) || IsClientSourceTV(client))
		return;

	SDKHook(client, SDKHook_WeaponEquip, Hook_OnWeaponEquip);
}

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client) || IsClientSourceTV(client))
		return;

	char sValue[6];
	GetClientCookie(client, g_hCookie, sValue, sizeof(sValue));
	g_bIsAutoSEnabled[client] = (sValue[0] != '\0') ? view_as<bool>(StringToInt(sValue)) : false;
}

public Action Hook_OnWeaponEquip(int client, int weapon)
{
	if (!g_bIsAutoSEnabled[client])
		return Plugin_Continue;

	if (primary[weapon])
		return Plugin_Continue;
	else
		primary[weapon] = true;

	char sClassName[20];

	sClassName[0] = '\0';
	GetEdictClassname(weapon, sClassName, sizeof(sClassName));

	if (strcmp(sClassName, "weapon_m4a1", false) == 0 || strcmp(sClassName, "weapon_usp", false) == 0)
	{
		SetEntProp(weapon, Prop_Send, "m_bSilencerOn", 1);
		SetEntProp(weapon, Prop_Send, "m_weaponMode", 1);
	}

	return Plugin_Continue;
}

public Action Command_AutoSilencer(int client, int args)
{
	if (!client)
	{
		CReplyToCommand(client, "[SM] This command can only be used in-game!");
		return Plugin_Handled;
	}

	UpdateSilencerStatus(client);
	return Plugin_Handled;
}

public void AutoSilencerCookieHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case CookieMenuAction_SelectOption:
			AutoSilencerSetting(client);
	}
}

public void AutoSilencerSetting(int client)
{
	Menu menu = new Menu(AutoSilencerSettingHandler, MENU_ACTIONS_ALL);
	menu.SetTitle("[AutoSilencer] %T", "Client Settings", client);

	char status[64], sEnabled[32], sDisabled[32];
	FormatEx(sEnabled, sizeof(sEnabled), "%T", "On", client);
	FormatEx(sDisabled, sizeof(sDisabled), "%T", "Off", client);
	FormatEx(status, 64, "%T: %s", "Toggle AutoSilencer", client, g_bIsAutoSEnabled[client] ? sEnabled : sDisabled);
	menu.AddItem("status", status);

	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int AutoSilencerSettingHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			if (strcmp(info, "status", false) == 0)
				UpdateSilencerStatus(param1);

			AutoSilencerSetting(param1);
		}
		case MenuAction_Cancel:
			ShowCookieMenu(param1);
		case MenuAction_End: 
			delete menu;
	}
	return 0;
}

stock void UpdateSilencerStatus(int client)
{
	char sEnabled[32], sDisabled[32];
	FormatEx(sEnabled, sizeof(sEnabled), "{green}%T", "On", client);
	FormatEx(sDisabled, sizeof(sDisabled), "{red}%T", "Off", client);

	g_bIsAutoSEnabled[client] = !g_bIsAutoSEnabled[client];
	CReplyToCommand(client, "{green}[SM]{default} %T %s", "Auto Silencer Status Reply", client, g_bIsAutoSEnabled[client] ? sEnabled : sDisabled, client);

	char sValue[6];
	FormatEx(sValue, sizeof(sValue), "%i", g_bIsAutoSEnabled[client]);
	SetClientCookie(client, g_hCookie, sValue);
}