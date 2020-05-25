--[[
	Dynamic bullets - Created by WholeCream

    Dynamic bullets do not use the game engine for calulations,
    instead it uses imanginary lua particles for calculation.

    When i mean imaginary i mean they aren't actually particles.
    but still interact with the physical world with force.
	This is what happens when a developer get's bored
]]

DynamicBullets = {}

-- I still don't fully understand converstions from meters to hammer units
-- So please bare with me in this shitty config
DynamicBullets.Mass = 4 -- grams, supposed to be kilograms but I told physics to fuck off

-- 9.8 m/s^2 is the acceleration of gravity on earth.
-- 9.8 * AnyMass = Force applied, ya know, Fg
DynamicBullets.Fg = Vector(0, 0, -(DynamicBullets.Mass * 514.43569553806)) -- This is newtons not velocity.

-- Distributes curtime into multiple calculation instances.
-- This allows more accurate calculations for when hitting objects and etc.
-- I suggest doing this when at a low tick like 33 - 11
DynamicBullets.MultiCalc = 17

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
--]]

local function Fprint(s)
	print('[Dynamic Bullets] -> ' .. s)
end

-- Stuff from the original weapon base of CW 2.0, Sleek Weapon Base
-- Love your stuff, Spy
local trace_normal = bit.bor(CONTENTS_SOLID, CONTENTS_OPAQUE, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX)
local trace_walls = bit.bor(CONTENTS_TESTFOGVOLUME, CONTENTS_EMPTY, CONTENTS_MONSTER, CONTENTS_HITBOX)

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
	[MAT_FLESH] = 0.95
}

local nearmiss = {
	"weapons/fx/nearmiss/bulletltor03.wav",
	"weapons/fx/nearmiss/bulletltor04.wav",
	"weapons/fx/nearmiss/bulletltor05.wav",
	"weapons/fx/nearmiss/bulletltor06.wav",
	"weapons/fx/nearmiss/bulletltor07.wav",
	"weapons/fx/nearmiss/bulletltor08.wav",
	"weapons/fx/nearmiss/bulletltor09.wav",
	"weapons/fx/nearmiss/bulletltor10.wav",
	"weapons/fx/nearmiss/bulletltor11.wav",
	"weapons/fx/nearmiss/bulletltor12.wav",
	"weapons/fx/nearmiss/bulletltor13.wav",
	"weapons/fx/nearmiss/bulletltor14.wav",
}

local ricochet = {
	"weapons/fx/rics/ric1.wav",
	"weapons/fx/rics/ric2.wav",
	"weapons/fx/rics/ric3.wav",
	"weapons/fx/rics/ric4.wav",
	"weapons/fx/rics/ric5.wav",
}

local Vec0 = Vector()

DynamicBullets.DebugTable = {}

local BulletStruct = {}
BulletStruct.time = 0
BulletStruct.lasttime = 0
BulletStruct.curtime = 0
BulletStruct.distancetraveled = 0
BulletStruct.life = 1.5
BulletStruct.LayersPenetrated = 0 -- If we need to limit out penetrations which we should.

BulletStruct.render = { -- simple rendering stuff, make bullets fancy :D
	lerpvec = false,
	lerplastvec = false,
}

BulletStruct.weaponattributes = {
	dmgmax = 1,
	dmgmin = 0,
	rangemax = 1,
	rangemin = 0,
	dmgmul = 1,
	force = 1,

	CanPenetrate = false,
	PenetrationRange = 0,
	PenetrationStrength = 0,
	PenetrationSurfaces = PenetrationSurfaces,
	NoPenetration = NoPenetration,

	CanRicochet = false,
	NoRicochet = NoRicochet
}

DynamicBullets.BulletStruct = BulletStruct


-- Create functions and information for a specific bullet.
function DynamicBullets:DynamicBullets(owner, SWEP, pos, vel)
	local DynamicBul = table.Copy(BulletStruct)

	DynamicBul.inflictor = SWEP
	DynamicBul.weaponclass = SWEP:GetClass()
	DynamicBul.originpos = pos
	DynamicBul.inittime = CurTime()
	DynamicBul.pos = pos
	DynamicBul.lastpos = pos
	DynamicBul.owner = owner
	DynamicBul.vel = vel * 40000
	local dir = vel:GetNormalized()

	-- Methods

    --[[
        Set's the velocity
    ]]
	function DynamicBul:SetVelocity(vel)
		self.vel = dir * vel
	end

    --[[
        Set's the velocity, but with full intent of an override
    ]]
	function DynamicBul:SetVelocityRaw(vel)
		self.vel = vel
	end

    --[[
        Set penetration
    ]]
	function DynamicBul:EnablePenetration(bool)
		self.weaponattributes.CanPenetrate = bool
	end

    --[[
        Set penetration
    ]]
	function DynamicBul:SetPenetration(PenetrationRange, PenetrationStrength, PenetrationSurfaces)
		self.weaponattributes.PenetrationRange = PenetrationRange
		self.weaponattributes.PenetrationStrength = PenetrationStrength
		self.weaponattributes.PenetrationSurfaces = PenetrationSurfaces
	end

    --[[
        Set penetration
    ]]
	function DynamicBul:EnableRicochet(bool)
		self.weaponattributes.CanRicochet = bool
	end

    --[[
        Set the damage of the bullet
    ]]
	function DynamicBul:SetDamage(Min, Max)
		self.weaponattributes.dmgmax = Max
		self.weaponattributes.dmgmin = Min
	end

    --[[
        Set the damage range of the bullet
    ]]
	function DynamicBul:SetRange(Min, Max)
		self.weaponattributes.rangemax = Max
		self.weaponattributes.rangemin = Min
	end

	-- Dangerous stuff, you probably don't want to touch this

    --[[
        Calculates damage based on distance.
    ]]
	function DynamicBul:CalculateDamage(dist)
		local weaponattributes = self.weaponattributes
		local dmgMax, dmgMin = weaponattributes.dmgmax, weaponattributes.dmgmin
		local rangeMin, rangeMax = weaponattributes.rangemin, weaponattributes.rangemax
		dist = (dist or urpos:Distance( theirpos ))
		dmg = dist < rangeMin and dmgMax or dist < rangeMax and (dmgMin - dmgMax) / (rangeMax - rangeMin) * (dist - rangeMin) + dmgMax or dmgMin
		dmg = dmg * weaponattributes.dmgmul
		return dmg
	end

    --[[
        If you ever want to override how the bullet travels and etc,
		you can do so through here.

		This is the core of dynamic bullets essentially
    ]]
	function DynamicBul:PhysicCalc()
		local acc = .5 * DynamicBullets.Fg * (self.time * self.time)
		local displace = (self.vel * self.time) + (acc)
		local newvel = self.vel + (DynamicBullets.Fg * self.time)
        local dir = displace:GetNormalized()
		return acc, displace, newvel, dir
	end

    --[[
        Creates a seed for randomizers
		Set to curtime for now till I find a better solution
    ]]
	function DynamicBul:RandSeed()
		return math.Round(CurTime())
	end

    --[[
        Calculates what to damage and where the bullet will be,
        as well as any other forces applied to it.

		Mess with this, and I swear to god, I'll put you into a fucking lua file for eternity
    ]]
	local bul, tr = {}, {}
	function DynamicBul:Calculate(tick)
		if !IsValid(self.owner) then
			return true
		end

		local myct = tick - self.inittime
		if myct < 0 then return false end
		if self.curtime ~= 0 and myct < self.curtime then
			return false
		else
			self.curtime = tick - self.inittime
		end

		self.time = self.curtime - self.lasttime
		if self.time == 0 then return false end

		local acc, displace, newvel, dir = self:PhysicCalc()

		self.lasttime = self.curtime
		self.lastpos = self.pos

        -- We need to trace so that we know if we hit anything, duh
		local trace = util.TraceLine({
			start = self.pos,
			endpos = self.pos + displace,
			filter = self.owner,
			mask = MASK_SHOT
		})

		local _dist = displace:Length()

		if CLIENT then
			if not self.swish and (self.owner ~= LocalPlayer() or GetViewEntity() ~= LocalPlayer()) then
				local pos = EyePos()
				if GetViewEntity() ~= LocalPlayer() then
					pos = GetViewEntity():GetPos()
				end
				if pos:DistToSqr(self.pos) < 5000 then
					self.swish = true
					EmitSound( nearmiss[math.random(#nearmiss)], self.pos, -1, CHAN_AUTO, 1, 45, 0, 100 )
				end
			end

			bul.Num = 1
			bul.Src = self.pos
			bul.Dir = dir
			bul.Spread 	= Vec0
			bul.Distance = _dist
			bul.Tracer	= 0
			bul.Force	= 0
			bul.Damage = 0

			self.owner:FireBullets(bul, true) -- Damage effect on walls n shit.

			bul.Distance = nil
		end

		self.pos = (self.pos + displace)
		self.vel = newvel
		self.distancetraveled = self.distancetraveled + _dist

        -- In theory all this penetration calculations i made should work aswell.
		if trace.Hit and trace.HitPos ~= self.lastpos then
			if trace.HitSky then
				return true
			end
            -- Well we hit something, let's fuck it up yea?
			if trace.Entity && IsValid(trace.Entity) && trace.Entity.TakeDamageInfo then
				-- Calculate the bullet damage based on the distance travelled
				local dmg = self:CalculateDamage(self.distancetraveled)

				-- Mimics damage taken from engine bullets
				local dmginfo = DamageInfo()
				local magnitude = newvel:Length()
				dmginfo:SetAttacker( self.owner )
				dmginfo:SetInflictor( self.inflictor )
				dmginfo:SetDamage( dmg )
				dmginfo:SetDamageType( DMG_BULLET )
				dmginfo:SetDamageForce( dir * (magnitude * (1/dmg)) )
				dmginfo:SetDamagePosition( trace.HitPos )
				trace.Entity:TakeDamageInfo( dmginfo )
			end

            -- check if the surface we hit can be penetrated at an angle.
			local dot = -dir:DotProduct(trace.HitNormal)
			if not self.weaponattributes.NoPenetration[trace.MatType] then
				local weaponattributes = self.weaponattributes
				if dot > 0.26 then
					if weaponattributes.CanPenetrate then
						if self.LayersPenetrated > 4 then return true end
						local penlen, hit_pos = weaponattributes.PenetrationStrength * (weaponattributes.PenetrationSurfaces[trace.MatType] and weaponattributes.PenetrationSurfaces[trace.MatType] or 1), trace.HitPos
						local tr = {}
						tr.start = hit_pos
						tr.endpos = tr.start + dir * penlen
						tr.filter = {
							self.owner,
							(trace.Entity or nil)
						}
						tr.mask = trace_normal
						tr.ignoreworld = true

						trace = util.TraceLine(tr)

						--Check the surface if it's actually there
						--Also check on where the bullet should come out.

						tr.start = trace.HitPos
						tr.endpos = tr.start - dir * penlen * 1.1
						tr.filter = {
							self.owner,
							(trace.Entity or nil)
						}
						tr.mask = trace_normal
						tr.ignoreworld = false

						trace = util.TraceLine(tr)
						
						if trace.Hit and trace.HitPos != tr.endpos and trace.HitPos != tr.start then

							local penDist = (penlen - trace.HitPos:Distance(hit_pos))

							bul.Num = 1
							bul.Src = trace.HitPos + dir * 0.01
							bul.Dir = -dir
							bul.Spread 	= Vec0
							bul.Tracer	= 0
							bul.Force	= 0
							bul.Damage = 0

							self.owner:FireBullets(bul, true) -- Damage effect on walls n shit.

							-- Set position to out point, calculate our new velocity based on the distance we penetrated through
							self.pos = trace.HitPos
							weaponattributes.force = weaponattributes.force * (penDist / penlen) * 0.75
							weaponattributes.dmgmul = weaponattributes.dmgmul * (penDist / penlen) * 0.75
							self.vel = newvel * (penDist / penlen) * 0.85
							self.LayersPenetrated = self.LayersPenetrated + 1
						else
							return true 
						end
					else
						return true
					end
				else
					if weaponattributes.CanRicochet then
						if not NoRicochet[trace.MatType] and weaponattributes.PenetrationRange * trace.Fraction < weaponattributes.PenetrationRange then
							dir = dir + (trace.HitNormal * dot) * 2
							local vec = Vector()
							math.randomseed(self:RandSeed())
							vec.x = math.random(-1, 1)
							math.randomseed(self:RandSeed()+1)
							vec.y = math.random(-1, 1)
							math.randomseed(self:RandSeed()+2)
							vec.z = math.random(-1, 1)
							dir = dir + vec * 0.03
                            local magnitude = newvel:Length()
							self.pos = trace.HitPos + dir
							weaponattributes.force = weaponattributes.force * 0.225
							weaponattributes.dmgmul = weaponattributes.dmgmul * 0.75
							self.vel = (dir * magnitude) * 0.75

							if CLIENT then
								local pos = EyePos()
								if GetViewEntity() ~= LocalPlayer() then
									pos = GetViewEntity():GetPos()
								end
								if pos:DistToSqr(self.pos) < 60000 then
									EmitSound( ricochet[math.random(#ricochet)], self.pos, -1, CHAN_AUTO, 1, 45, 0, 100 )
								end
							end
						else
							return true 
						end
					else
						return true 
					end
				end
			end
		end
		if self.time >= self.life then
			return true
		end
		if self.weaponattributes.dmgmul < 0.01 then
			return true
		end -- decimals do nothing lmao (or are at a point where damage is debatable.)
		return false
	end

	-- Networking stuff

	-- Since generally changes won't be synced when firing from the server
	-- This solves the attributes syncing
	-- We also only want to send attributes we changed
	function DynamicBul:WriteAttributes()
		local attribs = {}
		for k, v in pairs(BulletStruct.weaponattributes) do
			if self.weaponattributes[k] ~= v then
				attribs[#attribs+1] = {k, self.weaponattributes[k]}
			end
		end
		if #attribs < 1 then return false end
		attribs = util.Compress(util.TableToJSON(attribs))
		local len = #attribs
		net.WriteUInt(len, 16)
		net.WriteData(attribs, len)
		return true
	end

	function DynamicBul:ReadAttributes()
		local attribs = util.JSONToTable(util.Decompress(net.ReadData(net.ReadUInt(16))))
		for k=1, #attribs do
			local v = attribs[k]
			self.weaponattributes[v[1]] = v[2]
		end
	end

	-- This is because when you fire, firebullet does not get called for anyone else.
	function DynamicBul:Sync(override)
		if SERVER then
			net.Start('DynamicBullets.Fired', true)
			net.WriteEntity(self.owner)
			net.WriteEntity(self.inflictor)
			net.WriteString(pos.x .. '|' .. pos.y .. '|' .. pos.z)
			net.WriteString(vel.x .. '|' .. vel.y .. '|' .. vel.z)
			if not override then
				if self:WriteAttributes() == false then
					override = true
				end
			end
			net.WriteBool(override)
			if self.owner:IsPlayer() then
				net.SendOmit(owner)
			else
				net.Broadcast()
			end
		end
	end
	
	return DynamicBul
end

if SERVER then
	util.AddNetworkString('DynamicBullets.Fired')
end

-- Contains bullets that still need calculations until their life ends.
DynamicBullets.BulletEntries = {} -- Contains all fired bullets

function DynamicBullets:FireBullet(owner, SWEP, pos, vel, cb)
	local bul = self:DynamicBullets(owner, SWEP, pos, vel)
	local entries = self.BulletEntries

	-- Mimic the bullet to come out of the muzzle of the gun for you
	-- If your muzzle attachment is not 1, I hope you fucking burn in hell
	if CLIENT then
		if LocalPlayer() == owner and not owner:ShouldDrawLocalPlayer() then
			local vm = owner:GetViewModel()
			local _pos = pos
			__pos = vm:GetAttachment(1)
			if __pos then
				_pos = __pos.Pos
				if (_pos - bul.pos):Length() > 10000 then
					_pos = bul.pos
				end
				bul.render.lerplastvec = bul.pos
				bul.render.lerpvec = bul.pos
				bul.render.approachvec = _pos - bul.pos
			end
		else
			local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
			if bone then
				local vec = owner:GetBonePosition(bone)
				bul.render.lerplastvec = bul.pos
				bul.render.lerpvec = bul.pos
				bul.render.approachvec = vec - bul.pos
			end
		end
	end

	if cb then
		cb(bul)
	end

	-- If you are not lazy, please update the bullet stats through the hook instead of a network based override
	-- This will use less networking and generally make it easier for the server and client to handle
	-- Also will allow more access to things like rendering overrides
	local override = hook.Run('DynamicBullets.Fired', bul) -- You can modify them further from here on out
	if not override then
		-- This is for modifications that did not go through "DynamicBullets.Fired" as an override
		bul:Sync()
	end

	-- Store for calculations
	entries[#entries + 1] = bul
end

if SERVER then
	-- Later on i'll make it override hl2 weapons and etc, right now I'm too lazy
	--[[
	hook.Add('EntityFireBullets', 'DynamicBullets.Override', function(ent, data)
		-- Weapon bases can decide their own.
		if not ent.GetActiveWeapon then return end -- Why would you do this.
		local SWEP = ent:GetActiveWeapon()
		if ent:GetActiveWeapon():IsScripted() then return end
		DynamicBullets:FireBullet(ent, SWEP, data.src, data.dir, function(bullet)
			bullet:SetDamage(data.Damage, data.Damage)
		end)
		return false
	end)
	]]
end

net.Receive('DynamicBullets.Fired', function()
	local owner, SWEP, pos, vel = net.ReadEntity(), net.ReadEntity(), net.ReadString(), net.ReadString()
	if IsValid(SWEP) and IsValid(owner) then
		-- Note for facepunch, net.ReadVector and net.WriteVector are VERY inaccurate
		pos = string.Explode('|', pos)
		pos = Vector(pos[1], pos[2], pos[3])

		vel = string.Explode('|', vel)
		vel = Vector(vel[1], vel[2], vel[3])
		DynamicBullets:FireBullet(owner, SWEP, pos, vel, function(bullet)
			if not net.ReadBool() then
				bullet:ReadAttributes()
			end
		end)
	end
end)

if SERVER then
	-- Pretty self explanitory, calculates the bullets server-side.
	-- We CANNOT trust the client for any of this.
	-- Or else we end up with a game like Phantom Forces from roblox
	-- Which by the ways, has wayyyy too many cheaters
	hook.Add('FinishMove', 'DynamicBullets.Calc', function(pl, mv)
		local entries = DynamicBullets.BulletEntries
		local ct = CurTime()
		local calcs, ticks = 1, engine.TickInterval()
		if DynamicBullets.MultiCalc then
			calcs = DynamicBullets.MultiCalc
			ticks = ticks / calcs
		end

		local removals = 0
		for k = 1, #entries do
			k = k - removals
			local v = entries[k]
			if not v or v.owner ~= pl then continue end
			pl:LagCompensation(true)
			for c=1, calcs do
				local died = v:Calculate(ct - (ticks * calcs) + (c * ticks))
				if died then
					table.remove(entries, k)
					removals = removals + 1
					break
				end
			end
			pl:LagCompensation(false)
		end
	end)

	-- Non players do not need prediction, ever...
	hook.Add('Tick', 'DynamicBullets.Calc', function()
		local entries = DynamicBullets.BulletEntries
		local ct = CurTime()
		local calcs, ticks = 1, engine.TickInterval()
		if DynamicBullets.MultiCalc then
			calcs = DynamicBullets.MultiCalc
			ticks = ticks / calcs
		end

		local removals = 0
		for k = 1, #entries do
			k = k - removals
			local v = entries[k]
			if not v or v.owner:IsPlayer() then continue end
			for c=1, calcs do
				local died = v:Calculate(ct - (ticks * calcs) + (c * ticks))
				if died then
					table.remove(entries, k)
					removals = removals + 1
					break
				end
			end
		end
	end)
else
	-- For the engine to use predictions systems with the bullets.
	-- Cause we don't want players raging that their bullets didn't hit
	hook.Add('FinishMove', 'DynamicBullets.CalcPredicted', function(pl, mv)
		if pl ~= LocalPlayer() then return end
		local ct = CurTime()
		local entries = DynamicBullets.BulletEntries
		local removals = 0

		local calcs, tickseng, ticks = 1, engine.TickInterval(), 1
		if DynamicBullets.MultiCalc then
			calcs = DynamicBullets.MultiCalc
			ticks = tickseng
			ticks = ticks / calcs
		end

		for k = 1, #entries do
			k = k - removals
			local v = entries[k]
			if not v or v.owner ~= pl then continue end
			pl:LagCompensation(true)
			for c=1, calcs do
				local died = v:Calculate(ct - (ticks * calcs) + (c * ticks))
				if died then
					table.remove(entries, k)
					removals = removals + 1
					break
				end

				if DynamicBullets.Debug then
					DynamicBullets.DebugTable[#DynamicBullets.DebugTable + 1] = {
						["start"] = v.lastpos,
						["end"] = v.pos,
						["color"] = Color(255,255,255),
						["time"] = (ct - (ticks * calcs) + (c * ticks)) + 4
					}
				end
			end
			pl:LagCompensation(false)
		end
	end)

	-- For other players, this does not require predictions since the server is sending this to us
	-- I hate myself for mimicing predicted curtime in here.
	hook.Add('Tick', 'DynamicBullets.Calc', function()
		local LP = LocalPlayer()
		local entries = DynamicBullets.BulletEntries
		local removals = 0

		local calcs, tickseng, ticks = 1, engine.TickInterval(), 1
		if DynamicBullets.MultiCalc then
			calcs = DynamicBullets.MultiCalc
			ticks = tickseng
			ticks = ticks / calcs
		end

		for k = 1, #entries do
			k = k - removals
			local v = entries[k]
			if not v or v.owner == LP then continue end
			if not v.mimic_curtime then
				v.mimic_curtime = v.inittime + tickseng
			else
				v.mimic_curtime = v.mimic_curtime + tickseng
			end
			local ct = v.mimic_curtime
			for c=1, calcs do
				local died = v:Calculate(ct - (ticks * calcs) + (c * ticks))
				if died then
					table.remove(entries, k)
					removals = removals + 1
					break
				end
				if DynamicBullets.Debug then
					DynamicBullets.DebugTable[#DynamicBullets.DebugTable + 1] = {
						["start"] = v.lastpos,
						["end"] = v.pos,
						["color"] = Color(255,0,0),
						["time"] = (ct - (ticks * calcs) + (c * ticks)) + 4
					}
				end
			end
		end
	end)

	-- Simple renderer for bullets, make things look nice :)
	local mat = Material('sprites/light_ignorez')
	local lasermat1 = Material('effects/sw_laser_purple_main')
	local lasermat2 = Material('effects/sw_laser_purple_front')
	local enginetick = engine.TickInterval()
	hook.Add('PreDrawTranslucentRenderables', 'DynamicBullets.Render', function()
		local entries = DynamicBullets.BulletEntries
		for k = 1, #entries do
			local v = entries[k]
			if v.curtime < enginetick/4 then continue end
			if not v.render.lerpvec then
				v.render.lerpvec = v.pos
				v.render.lerplastvec = v.lastpos
				v.render.approachvec = Vec0
			end
			v.render.lerpvec = LerpVector(FrameTime() * 18, v.render.lerpvec, v.pos)
			v.render.lerplastvec = LerpVector(FrameTime() * 40, v.render.lerplastvec, v.render.lerpvec)
			v.render.approachvec = LerpVector(FrameTime() * 5, v.render.approachvec, Vec0)

			--if v.isdead then continue end
			if v.renderer then
				v.renderer()
				return
			end

			if v.pos ~= v.lastpos then
				render.DrawLine( v.render.lerplastvec + v.render.approachvec, v.render.lerpvec + v.render.approachvec, Color( 200, 145, 0 ) )
				render.SetMaterial(mat)
				render.DrawSprite( v.render.lerpvec + v.render.approachvec, 25, 25, Color( 200, 145, 0 ) )
			end
		end
	end)

	-- Simply debugger for bullet trajectories
	hook.Add( "PostDrawOpaqueRenderables", "DynamicBullets.Debug", function()
		if not DynamicBullets.Debug then return end
		local debugtable = DynamicBullets.DebugTable
		local removes = 0
		for k=1, #debugtable do
			k = k - removes
			local v = debugtable[k]
			render.DrawLine( v["start"], v["end"], (v["color"] and v["color"] or Color(255,255,255)) )
			if v["time"]  < CurTime() then
				removes = removes + 1
				table.remove(debugtable, k)
			end
		end
	end)
end

print('Dynamic Bullets 1.0 - Created by WholeCream')
Fprint('More dynamic than those "Physical Bullets" on the workshop :)')