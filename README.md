Prop Hunt Redux
==================

### OpenSourceLAN Prop Hunt Read Me

This is a small fork of [powerlord/sourcemod-prophunt](https://github.com/powerlord/sourcemod-prophunt).

Based off the 3.4 branch, it adds at least one small hack to make the weapons properly disappear.

I'd like to make hats disappear too, but at this point I'm not quite familiar enough with Sourcemod
to know how to do that.

The 4.0 branch in the original repo crashes TF2. Maybe that would fix everything if it didn't crash?
But here we are. :)

#### Compatibility

I tested this with TF2 and Source mod details below:

```
version
Build Label:           4725564   # Uniquely identifies each build
Network PatchVersion:  4725564   # Determines client and server compatibility
Protocol version:           24   # High level network protocol version
Server version:        4725564
Server AppID:           232250

sm plugins list
[SM] Listing 19 plugins:
  01 "PropHunt Redux" (3.4.0.0 beta 2223) by Darkimmortal, Geit, and Powerlord
  02 "Observer Point" (1.0.100) by <eVa>Dog
  03 "Anti-Flood" (1.9.0.6256) by AlliedModders LLC
  04 "Client Preferences" (1.9.0.6256) by AlliedModders LLC
  05 "Fun Votes" (1.9.0.6256) by AlliedModders LLC
  06 "Basic Info Triggers" (1.9.0.6256) by AlliedModders LLC
  07 "Basic Votes" (1.9.0.6256) by AlliedModders LLC
  08 "Admin Menu" (1.9.0.6256) by AlliedModders LLC
  09 "Basic Commands" (1.9.0.6256) by AlliedModders LLC
  10 "Admin Help" (1.9.0.6256) by AlliedModders LLC
  11 "Basic Ban Commands" (1.9.0.6256) by AlliedModders LLC
  12 "Player Commands" (1.9.0.6256) by AlliedModders LLC
  13 "Basic Comm Control" (1.9.0.6256) by AlliedModders LLC
  14 "Fun Commands" (1.9.0.6256) by AlliedModders LLC
  15 "Sound Commands" (1.9.0.6256) by AlliedModders LLC
  16 "Nextmap" (1.9.0.6256) by AlliedModders LLC
  17 "Reserved Slots" (1.9.0.6256) by AlliedModders LLC
  18 "Basic Chat" (1.9.0.6256) by AlliedModders LLC
  19 "Admin File Reader" (1.9.0.6256) by AlliedModders LLC

sm exts list
[SM] Displaying 13 extensions:
[01] Automatic Updater (1.9.0.6256): Updates SourceMod gamedata files
[02] Webternet (1.9.0.6256): Extension for interacting with URLs
[03] TF2Items (1.6.4): TF2 Item Modifier
[04] TF2 Tools (1.9.0.6256): TF2 extended functionality
[05] BinTools (1.9.0.6256): Low-level C/C++ Calling API
[06] SDK Hooks (1.9.0.6256): Source SDK Hooks
[07] SDK Tools (1.9.0.6256): Source SDK Tools
[08] <OPTIONAL> file "steamtools.ext.so": /steam/tf2/tf/addons/sourcemod/extensions/steamtools.ext.so: cannot open shared object file: No such file or directory
[09] <OPTIONAL> file "SteamWorks.ext.so": /steam/tf2/tf/addons/sourcemod/extensions/SteamWorks.ext.so: cannot open shared object file: No such file or directory
[10] Regex (1.9.0.6256): Provides regex natives for plugins
[11] Client Preferences (1.9.0.6256): Saves client preference settings
[12] SQLite (1.9.0.6256): SQLite Driver
[13] Top Menus (1.9.0.6256): Creates sorted nested menus
```

#### Building

Everything you need to build the plugin is available in this repo and a standard download of Sourcemod.

Given a copy of sourcemod in `sm/` and a copy of this repo in `ph/`:

```
sm/addons/sourcemod/scripting/spcomp ph/addons/sourcemod/scripting/prophunt.sp -i ph/addons/sourcemod/scripting/include/
mkdir ph/addons/sourcemod/plugins/
cp -R prophunt.smx ph/addons/sourcemod/scripting/include/ ph/addons/sourcemod/plugins/
tar -czf prophunt.tar.gz ph/
```
You can now take `prophunt.tar.gz` and deploy it to a TF2 server somewhere!


### Help it's busted!

I can't promise answers or any real help - this isn't my code! But say hi in [the OpenSourceLAN discord](https://discord.gg/0149LEvYPSzmnItKb)
and maybe we can sort something out?

### Original readme below

![Build Status](https://travis-ci.org/powerlord/sourcemod-prophunt.svg?branch=master)

Prop Hunt Redux is an effort to fix various issues with Prop Hunt and also to add some new features to the game mode.

The major changes in Prop Hunt Redux over Prop Hunt 1.93 are:

1. Major work has been done to fix issues with the prop list, such as props that were stuck in the floor.
2. Hunter self-damage has been fixed for newer Flamethrowers... you won't instant-kill yourself with the Phlogistinator or Rainblower any more.
3. The weapon list has been adjusted and some new options enabled.
4. New maps and their configurations have been added to the [map list](https://forums.alliedmods.net/showthread.php?p=2048443#post2048443).
5. Prop Hunt has had a lot of work done to make it more multi-mod friendly.
