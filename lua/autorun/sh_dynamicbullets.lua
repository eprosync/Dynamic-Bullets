--[[
	Dynamic bullets - Created by WholeCream

    Dynamic bullets do not use the game engine for calulations,
    instead it uses imanginary lua particles for calculation.

    When i mean imaginary i mean they aren't actually particles.
    but still interact with the physical world with force.
	This is what happens when a developer get's bored

	If you would want to support this, please refer to my github 
	https://github.com/eprosync/Dynamic-Bullets
	You may make forks, issues, and suggestions there.
	Keep in mind however I am not as active as you may think on github.
]]

DynamicBullets = DynamicBullets or {}

-- 9.8 m/s^2 is the acceleration of gravity on earth.
-- In hammer it's about 514 units/s^2
DynamicBullets.Fg = Vector(0, 0, -(4 * 514.43569553806)) -- This is acceleration not velocity.

-- Distributes curtime into multiple calculation instances.
-- This allows more accurate calculations for when hitting objects and etc.
-- I suggest doing this when at a low tick like 33 - 11 as this will increase the need for more resources
DynamicBullets.MultiCalc = 8

-- For debugging bullet travel and velocity
DynamicBullets.Debug = false

--[[
    Eqn,
    vf = final velocity
    vi = initial velocity
    a = acceleration
    t = time
    d = displacement

    vf = vi + a(t) - missing d
    vf^2 = vi^2 + 2(a)(d) - missing t
    d = vi(t) + 1/2(a)(t)^2 -- mising vf
    d = 1/2(vi + vf)(t) -- mising a
    d = vf(t) - 1/2(a)(t)^2 -- mising vi

	Use these for your modifications also,
	they are VERY important for this entire system to work.
	Ty GR 11/12 physics teacher :)
--]]

local function Fprint(s)
	print('[Dynamic Bullets] -> ' .. s)
end

-- Stuff from the original weapon base of CW 2.0, Sleek Weapon Base
-- Love your stuff, Spy
local NoPenetration = {
	[MAT_SLOSH] = true
}

local NoRicochet = {
	[MAT_FLESH] = true,
	[MAT_ANTLION] = true,
	[MAT_BLOODYFLESH] = true,
	[MAT_DIRT] = true,
	[MAT_SAND] = true,
	[MAT_GLASS] = true,
	[MAT_ALIENFLESH] = true
}

local PenetrationSurfaces = {
	[MAT_CONCRETE] = 0.8,
	[MAT_SAND] = 0.5,
	[MAT_DIRT] = 0.8,
	[MAT_METAL] = 0.6,
	[MAT_TILE] = 0.9,
	[MAT_WOOD] = 0.9,
	[MAT_FLESH] = 1.1
}

DynamicBullets.DebugTable = {}

-- This structure may feel familiar to some people
-- Got the idea from roblox's particle system
-- So yea basically physical bullets are particles that can interact with the world
-- Even with high ping since lag compensation is neato
local BulletStruct = DynamicBullets.BulletStruct or {}
BulletStruct.time = 0
BulletStruct.lasttime = 0
BulletStruct.curtime = 0
BulletStruct.life = 1.5
BulletStruct.LayersPenetrated = 0 -- If we need to limit out penetrations which we should.

BulletStruct.weaponattributes = {
	CanPenetrate = false,
	PenetrationRange = 0,
	PenetrationStrength = 0,
	PenetrationSurfaces = PenetrationSurfaces,
	NoPenetration = NoPenetration,

	CanRicochet = false,
	NoRicochet = NoRicochet
}

DynamicBullets.BulletStruct = BulletStruct

-- Contains bullets that still need calculations until their life ends.
DynamicBullets.BulletEntries = {} -- Contains all fired bullets

if CLIENT then
	include('dynamicbullets/cl_dynamicbullets.lua')
else
	AddCSLuaFile('dynamicbullets/cl_dynamicbullets.lua')
	include('dynamicbullets/sv_dynamicbullets.lua')
end

print('Dynamic Bullets 1.0 - Created by WholeCream')
Fprint('More dynamic than those "Physical Bullets" on the workshop :)')