local _file_Find = file.Find
local _ipairs = ipairs
local _AddCSLuaFile = AddCSLuaFile
local _Color = Color
local _MsgC = MsgC
local _hook_Run = hook.Run
local _include = include
--[[
	Dynamic bullets - Created by WholeCream

    Dynamic bullets do not use the game engine for calulations,
    instead it uses imanginary lua particles for calculation.

    When i mean imaginary i mean they aren't actually particles.
    but still interact with the physical world with force.
	This is what happens when a developer get's bored
]]

DynamicBullets = DynamicBullets or {
    DebugTable = {}
}

-- I am, FUCKING LAZY!
DynamicBullets.IncludeSV = (SERVER) and _include or function() end
DynamicBullets.IncludeCL = (SERVER) and _AddCSLuaFile or _include
DynamicBullets.IncludeSH = function(path) DynamicBullets.IncludeSV(path) DynamicBullets.IncludeCL(path) end

-- Here we go!
local White = _Color(255,255,255)
local Green = _Color(0,240,0)
local Red = _Color(240,0,0)

function DynamicBullets.Print(str)
    _MsgC(Green, 'Dynamic Bullets', White, ' | ' .. str .. '\n')
end

function DynamicBullets.DBGPrint(str)
    if not DynamicBullets.Debug then return end
    _MsgC(Green, 'Dynamic Bullets', White, ' | ', Red, 'Debug', White, ' -> ' .. str .. '\n')
end

DynamicBullets.Print('Loading crap...')

DynamicBullets.IncludeSH('dynamicbullets/config.lua')

local Files, Folders
Files, Folders = _file_Find('dynamicbullets/shared/*.lua', 'LUA')
for k, v in _ipairs(Files) do
	DynamicBullets.IncludeSH('dynamicbullets/shared/' .. v)
end

if (SERVER) then
	Files, Folders = _file_Find('dynamicbullets/server/*.lua', 'LUA')
	for k, v in _ipairs(Files) do
		DynamicBullets.IncludeSV('dynamicbullets/server/' .. v)
	end
end

Files, Folders = _file_Find('dynamicbullets/client/*.lua', 'LUA')
for k, v in _ipairs(Files) do
	DynamicBullets.IncludeCL('dynamicbullets/client/' .. v)
end

_hook_Run('DynamicBullets.Init')

DynamicBullets.Print('All set!')