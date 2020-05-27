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

-- This structure may feel familiar to some people
-- Got the idea from roblox's particle system
-- So yea basically physical bullets are particles that can interact with the world
-- Even with high ping since lag compensation is neato
local function CreateStruct()
	DynamicBullets.Print('Creating the bullet structure...')
	local BulletStruct = DynamicBullets.BulletStruct or {}

	BulletStruct.time = 0
	BulletStruct.lasttime = 0
	BulletStruct.curtime = 0
	BulletStruct.life = 1.5
	BulletStruct.LayersPenetrated = 0

	BulletStruct.weaponattributes = {
		CanPenetrate = false,
		PenetrationRange = 0,
		PenetrationStrength = 0,
		PenetrationSurfaces = PenetrationSurfaces,
		NoPenetration = NoPenetration,

		CanRicochet = false,
		NoRicochet = NoRicochet
	}

	DynamicBullets.SHStruct(BulletStruct)
	
	hook.Run('DynamicBullets.CreateStruct', BulletStruct)

	DynamicBullets.BulletStruct = BulletStruct
	DynamicBullets.Print('Oki Doki')
end
hook.Add('DynamicBullets.Init', 'DynamicBullets.CreateStruct', CreateStruct)

function DynamicBullets:DynamicBullet(owner, SWEP, pos, vel)
	local struct = table.Copy(self.BulletStruct)
	struct.inflictor = SWEP
	struct.weaponclass = SWEP:GetClass()
	struct.originpos = pos
	struct.inittime = CurTime()
	struct.pos = pos
	struct.lastpos = pos
	struct.owner = owner
	struct.vel = vel * 40000
	struct.originvel = struct.vel
	return struct
end

-- Contains bullets that still need calculations until their life ends.
DynamicBullets.BulletEntries = {} -- Contains all fired bullets

if DynamicBullets.BulletStruct then
	DynamicBullets.Print('Reloading the struct!')
	CreateStruct()
end