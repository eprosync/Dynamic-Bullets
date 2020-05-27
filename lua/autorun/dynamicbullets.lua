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
DynamicBullets.IncludeSV = (SERVER) and include or function() end
DynamicBullets.IncludeCL = (SERVER) and AddCSLuaFile or include
DynamicBullets.IncludeSH = function(path) DynamicBullets.IncludeSV(path) DynamicBullets.IncludeCL(path) end

-- Here we go!
local White = Color(255,255,255)
local Green = Color(0,240,0)
local Red = Color(240,0,0)

function DynamicBullets.Print(str)
    MsgC(Green, 'Dynamic Bullets', White, ' | ' .. str .. '\n')
end

function DynamicBullets.DBGPrint(str)
    if not DynamicBullets.Debug then return end
    MsgC(Green, 'Dynamic Bullets', White, ' | ', Red, 'Debug', White, ' -> ' .. str .. '\n')
end

DynamicBullets.Print('Loading crap...')

DynamicBullets.IncludeSH('dynamicbullets/config.lua')

local Files, Folders
Files, Folders = file.Find('dynamicbullets/shared/*.lua', 'LUA')
for k, v in ipairs(Files) do
	DynamicBullets.IncludeSH('dynamicbullets/shared/' .. v)
end

if (SERVER) then
	Files, Folders = file.Find('dynamicbullets/server/*.lua', 'LUA')
	for k, v in ipairs(Files) do
		DynamicBullets.IncludeSV('dynamicbullets/server/' .. v)
	end
end

Files, Folders = file.Find('dynamicbullets/client/*.lua', 'LUA')
for k, v in ipairs(Files) do
	DynamicBullets.IncludeCL('dynamicbullets/client/' .. v)
end

hook.Run('DynamicBullets.Init')

DynamicBullets.Print('All set!')