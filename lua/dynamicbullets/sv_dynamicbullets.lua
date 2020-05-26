local _hook_Run = hook.Run
local _util_TableToJSON = util.TableToJSON
local _math_randomseed = math.randomseed
local _bit_bor = bit.bor
local _net_Broadcast = (SERVER and net.Broadcast or nil)
local _util_TraceLine = util.TraceLine
local _net_WriteUInt = net.WriteUInt
local _net_WriteData = net.WriteData
local _net_WriteEntity = net.WriteEntity
local _net_Start = net.Start
local _util_AddNetworkString = (SERVER and util.AddNetworkString or nil)
local _CurTime = CurTime
local _net_WriteString = net.WriteString
local _pairs = pairs
local _IsValid = IsValid
local _util_Compress = util.Compress
local _hook_Add = hook.Add
local _table_Copy = table.Copy
local _math_Round = math.Round
local _Vector = Vector
local _net_SendOmit = (SERVER and net.SendOmit or nil)
local _math_random = math.random
local _DamageInfo = DamageInfo
local _math_sqrt = math.sqrt
local _net_WriteBool = net.WriteBool
local _table_remove = table.remove
local entries = DynamicBullets.BulletEntries
local Vec0 = _Vector()

_util_AddNetworkString('DynamicBullets.Fired')

local trace_normal = _bit_bor(CONTENTS_SOLID, CONTENTS_OPAQUE, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX)

local BulletStruct = DynamicBullets.BulletStruct
BulletStruct.distancetraveledsqr = 0

local BulletAttributes = _table_Copy(BulletStruct.weaponattributes)

BulletStruct.weaponattributes.dmgmax = 1
BulletStruct.weaponattributes.dmgmin = 0
BulletStruct.weaponattributes.rangemax = 1
BulletStruct.weaponattributes.rangemin = 0
BulletStruct.weaponattributes.dmgmul = 1
BulletStruct.weaponattributes.force = 1

-- Create functions and information for a specific bullet.
function DynamicBullets:DynamicBullets(owner, SWEP, pos, vel)
	local DynamicBul = _table_Copy(DynamicBullets.BulletStruct)

	DynamicBul.inflictor = SWEP
	DynamicBul.weaponclass = SWEP:GetClass()
	DynamicBul.originpos = pos
	DynamicBul.inittime = _CurTime()
	DynamicBul.pos = pos
	DynamicBul.lastpos = pos
	DynamicBul.owner = owner
	DynamicBul.vel = vel * 40000
	local originvel = vel * 40000
	local dir = vel:GetNormalized()

	-- Methods
	-- I would add more, but... just fucking modify the values raw instead, it's better than calling a function :D

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

		If your planning on making things like homing bullets and etc,
		do a lot of testing with debug mode on, you may hit some lag compensation/prediction errors
		as this entire system is very delicate with it.
    ]]
	function DynamicBul:PhysicCalc()
		local fg = DynamicBullets.Fg
		return (self.vel * self.time) + (.5 * fg * (self.time * self.time)), self.vel + (fg * self.time)
	end

    --[[
        Creates a seed for randomizers
		Set to curtime for now till I find a better solution
    ]]
	function DynamicBul:RandSeed()
		return _math_Round(self.originpos.x + self.originpos.y + self.originpos.z + originvel.x + originvel.y + originvel.z)
	end

    --[[
        can we penetrate?
    ]]
	function DynamicBul:CanPenetrate(trace, dot)
		local weaponattributes = self.weaponattributes
		return (weaponattributes.CanPenetrate and not weaponattributes.NoPenetration[trace.MatType] and dot > 0.26 and self.LayersPenetrated < 4)
	end

    --[[
        Penetrate a surface
    ]]
	function DynamicBul:PenetrateSurface(trace, dot)
		local weaponattributes = self.weaponattributes
		local dir = self.dir
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

		trace = _util_TraceLine(tr)

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

		trace = _util_TraceLine(tr)
		
		if trace.Hit and trace.HitPos != tr.endpos and trace.HitPos != tr.start then
			-- Set position to out point, calculate our new velocity based on the distance we penetrated through
			self.pos = trace.HitPos

			local penDist = (penlen - trace.HitPos:Distance(hit_pos))
			weaponattributes.force = weaponattributes.force * (penDist / penlen) * 0.75
			weaponattributes.dmgmul = weaponattributes.dmgmul * (penDist / penlen) * 0.75
			self.vel = self.vel * (penDist / penlen) * 0.85

			self.LayersPenetrated = self.LayersPenetrated + 1
		else
			return true 
		end
	end

    --[[
        Can we ricochet on a surface?
    ]]
	function DynamicBul:CanRicochet(trace, dot)
		local weaponattributes = self.weaponattributes
		return (weaponattributes.CanRicochet and not weaponattributes.NoRicochet[trace.MatType] and weaponattributes.PenetrationRange * trace.Fraction < weaponattributes.PenetrationRange and dot < 0.26)
	end

    --[[
        Ricochet the surface
    ]]
	function DynamicBul:RicochetSurface(trace, dot)
		local weaponattributes = self.weaponattributes
		dir = dir + (trace.HitNormal * dot) * 2
		local vec = _Vector()
		_math_randomseed(self:RandSeed())
		vec.x = _math_random(-1000, 1000) * .001
		_math_randomseed(self:RandSeed()+1)
		vec.y = _math_random(-1000, 1000) * .001
		_math_randomseed(self:RandSeed()+2)
		vec.z = _math_random(-1000, 1000) * .001
		dir = dir + vec * 0.03
		local magnitude = self.vel:Length()
		self.pos = trace.HitPos + dir
		weaponattributes.force = weaponattributes.force * 0.225
		weaponattributes.dmgmul = weaponattributes.dmgmul * 0.75
		self.vel = (dir * magnitude) * 0.75
	end

    --[[
        Entity take damage,
		Modify this to however you feel,
		nobody is stopping you :D
    ]]
	function DynamicBul:DamageEntity(trace)
		-- Calculate the bullet damage based on the distance travelled
		local dmg = self:CalculateDamage(_math_sqrt(self.distancetraveledsqr))

		-- Mimics damage taken from engine bullets
		local dmginfo = _DamageInfo()
		local magnitude = self.vel:Length()
		dmginfo:SetAttacker( self.owner )
		dmginfo:SetInflictor( self.inflictor )
		dmginfo:SetDamage( dmg )
		dmginfo:SetDamageType( DMG_BULLET )
		dmginfo:SetDamageForce( dir * (magnitude * (1/dmg)) )
		dmginfo:SetDamagePosition( trace.HitPos )

		if trace.Entity:IsPlayer() then
			_hook_Run( "ScalePlayerDamage", trace.Entity, trace.HitGroup, dmginfo)
			if GAMEMODE.ScalePlayerDamage then GAMEMODE:ScalePlayerDamage(trace.Entity, trace.HitGroup, dmginfo) end
		elseif trace.Entity:IsNPC() then
			_hook_Run( "ScaleNPCDamage", trace.Entity, trace.HitGroup, dmginfo)
			if GAMEMODE.ScaleNPCDamage then GAMEMODE:ScaleNPCDamage(trace.Entity, trace.HitGroup, dmginfo) end
		end

		trace.Entity:TakeDamageInfo( dmginfo )
	end

    --[[
        Calculates what to damage and where the bullet will be,
        as well as any other forces applied to it.

		Mess with this, and I swear to god, I'll put you into a fucking lua file for eternity.
		*But in all seriousness, please do as you please, not even I can stop you :)
    ]]
	local bul, tr = {}, {}
	function DynamicBul:Calculate(tick)
		if !_IsValid(self.owner) then
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

		local displace, newvel = self:PhysicCalc()

		self.lasttime = self.curtime
		self.lastpos = self.pos
		self.dir = displace:GetNormalized()

        -- We need to trace so that we know if we hit anything, duh
		local trace = _util_TraceLine({
			start = self.pos,
			endpos = self.pos + displace,
			filter = self.owner,
			mask = MASK_SHOT
		})

		local _dist = displace:LengthSqr()

		self.pos = (self.pos + displace)
		self.vel = newvel
		self.distancetraveledsqr = self.distancetraveledsqr + _dist

        -- In theory all this penetration calculations i made should work aswell.
		if trace.Hit and trace.HitPos ~= self.lastpos then
			if trace.HitSky then
				return true
			end

            -- Well we hit something, let's fuck it up yea?
			if trace.Entity && _IsValid(trace.Entity) && trace.Entity.TakeDamageInfo then
				self:DamageEntity(trace)
			end

            -- Simple penetration and surface ricochet
			local dot = -dir:DotProduct(trace.HitNormal)
			if self:CanPenetrate(trace, dot) then
				local died = self:PenetrateSurface(trace, dot)
				if died ~= nil then return died end
			elseif self:CanRicochet(trace, dot) then
				local died = self:RicochetSurface(trace, dot)
				if died ~= nil then return died end
			end
		end
		if self.curtime >= self.life then
			return true
		end
		return false
	end

	-- Networking stuff

	-- Since generally changes won't be synced when firing from the server
	-- This solves the attributes syncing
	-- We also only want to send attributes we changed
	function DynamicBul:WriteAttributes()
		local attribs = {}
		for k, v in _pairs(BulletAttributes) do
			if self.weaponattributes[k] ~= v then
				attribs[#attribs+1] = {k, self.weaponattributes[k]}
			end
		end
		if #attribs < 1 then return false end
		attribs = _util_Compress(_util_TableToJSON(attribs))
		local len = #attribs
		_net_WriteUInt(len, 16)
		_net_WriteData(attribs, len)
		return true
	end

	-- This is because when you fire, firebullet does not get called for anyone else.
	function DynamicBul:Sync(override)
        _net_Start('DynamicBullets.Fired', true)
        _net_WriteEntity(self.owner)
        _net_WriteEntity(self.inflictor)
        _net_WriteString(pos.x .. '|' .. pos.y .. '|' .. pos.z)
        _net_WriteString(vel.x .. '|' .. vel.y .. '|' .. vel.z)
        if not override then
            if self:WriteAttributes() == false then
                override = true
            end
        end
        _net_WriteBool(override)
        if self.owner:IsPlayer() then
            _net_SendOmit(owner)
        else
            _net_Broadcast()
        end
	end
	
	return DynamicBul
end

function DynamicBullets:FireBullet(owner, SWEP, pos, vel, cb)
	local bul = self:DynamicBullets(owner, SWEP, pos, vel)
	local entries = self.BulletEntries
	if cb then
		cb(bul)
	end

	-- If you are not lazy, please update the bullet stats through the hook instead of a network based override
	-- This will use less networking and generally make it easier for the server and client to handle
	-- Also will allow more access to things like rendering overrides
	local override = _hook_Run('DynamicBullets.Fired', bul) -- You can modify them further from here on out
	if not override then
		-- This is for modifications that did not go through "DynamicBullets.Fired" as an override
		bul:Sync()
	end

	-- Store for calculations
	if not owner.dbulletentires then
		owner.dbulletentires = {}
	end

	if owner:IsPlayer() then
		owner.dbulletentires[#owner.dbulletentires + 1] = bul
	else
		entries[#entries + 1] = bul
	end
end

-- Pretty self explanitory, calculates the bullets server-side.
-- We CANNOT trust the client for any of this.
-- Or else we end up with a game like Phantom Forces from roblox
-- Which by the ways, has wayyyy too many cheaters
_hook_Add('FinishMove', 'DynamicBullets.Calc', function(pl, mv)
    local entries = pl.dbulletentires
	if not entries then return end
	local entires_len = #entries
	if entires_len < 1 then return end

    local ct = _CurTime()
    local calcs, ticks = 1, engine.TickInterval()
    if DynamicBullets.MultiCalc then
        calcs = DynamicBullets.MultiCalc
        ticks = ticks / calcs
    end

    local removals = 0
	pl:LagCompensation(true)
    for k = 1, #entries do
        k = k - removals
        local v = entries[k]
        if not v or v.owner ~= pl then continue end
        for c=1, calcs do
            local died = v:Calculate(ct - (ticks * calcs) + (c * ticks))
            if died then
                _table_remove(entries, k)
                removals = removals + 1
                break
            end
        end
    end
	pl:LagCompensation(false)
end)

-- Non players do not need prediction, ever...
_hook_Add('Tick', 'DynamicBullets.Calc', function()
    local entries = DynamicBullets.BulletEntries
    local ct = _CurTime()
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
                _table_remove(entries, k)
                removals = removals + 1
                break
            end
        end
    end
end)