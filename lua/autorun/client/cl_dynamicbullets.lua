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

local BulletStruct = DynamicBullets.BulletStruct
local max_renderdistance = 5000*5000
local max_renders = 60

BulletStruct.Sounds = {
	NearMiss = nearmiss,
	Ricochet = ricochet,
}

BulletStruct.render = { -- simple rendering stuff, make bullets fancy :D
	lerpvec = false,
	lerplastvec = false,
}

local entries = DynamicBullets.BulletEntries
local Vec0 = Vector()

local trace_normal = bit.bor(CONTENTS_SOLID, CONTENTS_OPAQUE, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX)

-- Create functions and information for a specific bullet.
function DynamicBullets:DynamicBullets(owner, SWEP, pos, vel)
	local DynamicBul = table.Copy(DynamicBullets.BulletStruct)

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
	end

    --[[
        Set the damage range of the bullet
    ]]
	function DynamicBul:SetRange(Min, Max)
	end

	-- Dangerous stuff, you probably don't want to touch this

    --[[
        Calculates damage based on distance.
    ]]
	function DynamicBul:CalculateDamage(dist)
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
			self:EffectSurface(trace.HitPos + dir * 0.01, -dir, 1)

			-- Set position to out point, calculate our new velocity based on the distance we penetrated through
			self.pos = trace.HitPos

			local penDist = (penlen - trace.HitPos:Distance(hit_pos))
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
		Ping!
	]]
	function DynamicBul:RicochetSound()	
		local pos = EyePos()
		if GetViewEntity() ~= LocalPlayer() then
			pos = GetViewEntity():GetPos()
		end
		if pos:DistToSqr(self.pos) < 60000 then
			local tbl = self.Sounds.Ricochet
			EmitSound( tbl[math.random(#tbl)], self.pos, -1, CHAN_AUTO, 1, 45, 0, 100 )
		end
	end

    --[[
        Ricochet the surface
    ]]
	function DynamicBul:RicochetSurface(trace, dot)
		dir = dir + (trace.HitNormal * dot) * 2
		local vec = Vector()
		math.randomseed(self:RandSeed())
		vec.x = math.random(-1000, 1000) * .001
		math.randomseed(self:RandSeed()+1)
		vec.y = math.random(-1000, 1000) * .001
		math.randomseed(self:RandSeed()+2)
		vec.z = math.random(-1000, 1000) * .001
		dir = dir + vec * 0.03
		local magnitude = self.vel:Length()
		self.pos = trace.HitPos + dir
		self.vel = (dir * magnitude) * 0.75
		self:RicochetSound()
	end

    --[[
        Entity take damage,
		Modify this to however you feel,
		nobody is stopping you :D
    ]]
	function DynamicBul:DamageEntity(trace)
	end

    --[[
        Decals and effects for when the bullet hits something...
		I've put zero effort into this one boys
    ]]
	function DynamicBul:EffectSurface(src, dir, dist)
		local bul = {}
		bul.Num = 1
		bul.Src = src
		bul.Dir = dir
		bul.Spread 	= Vec0
		bul.Distance = dist
		bul.Tracer	= 0
		bul.Force	= 0
		bul.Damage = 0

		self.owner:FireBullets(bul, true) -- Damage effect on walls n shit.
	end

	--[[
		Swish!
	]]
	function DynamicBul:NearMissSound()	
		if not self.swish and (self.owner ~= LocalPlayer() or GetViewEntity() ~= LocalPlayer()) then
			local pos = EyePos()
			if GetViewEntity() ~= LocalPlayer() then
				pos = GetViewEntity():GetPos()
			end
			if pos:DistToSqr(self.pos) < 5000 then
				self.swish = true
				local tbl = self.Sounds.NearMiss
				EmitSound( tbl[math.random(#tbl)], self.pos, -1, CHAN_AUTO, 1, 45, 0, 100 )
			end
		end
	end

    --[[
        Calculates what to damage and where the bullet will be,
        as well as any other forces applied to it.

		Mess with this, and I swear to god, I'll put you into a fucking lua file for eternity.
		*But in all seriousness, please do as you please, not even I can stop you :)
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
		self.dir = dir

        -- We need to trace so that we know if we hit anything, duh
		local trace = util.TraceLine({
			start = self.pos,
			endpos = self.pos + displace,
			filter = self.owner,
			mask = MASK_SHOT
		})

		self:NearMissSound()

		self.pos = (self.pos + displace)
		self.vel = newvel

        -- In theory all this penetration calculations i made should work aswell.
		if trace.Hit and trace.HitPos ~= self.lastpos then
			if trace.HitSky then
				return true
			end

			--Effects n stuff, neato
			self:EffectSurface(self.lastpos, dir, displace:Length())

            -- Well we hit something, let's fuck it up yea?
			if trace.Entity && IsValid(trace.Entity) && trace.Entity.TakeDamageInfo then
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
	function DynamicBul:ReadAttributes()
		local attribs = util.JSONToTable(util.Decompress(net.ReadData(net.ReadUInt(16))))
		for k=1, #attribs do
			local v = attribs[k]
			self.weaponattributes[v[1]] = v[2]
		end
	end

	-- This is because when you fire, firebullet does not get called for anyone else.
	function DynamicBul:Sync(override)
	end
	
	return DynamicBul
end


function DynamicBullets:FireBullet(owner, SWEP, pos, vel, cb)
	local bul = self:DynamicBullets(owner, SWEP, pos, vel)
	local entries = self.BulletEntries

	-- Mimic the bullet to come out of the muzzle of the gun for you
	-- If your muzzle attachment is not 1, I hope you fucking burn in hell
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
local enginetick = engine.TickInterval()
hook.Add('PreDrawTranslucentRenderables', 'DynamicBullets.Render', function()
    local entries = DynamicBullets.BulletEntries
    for k = 1, #entries do
        local v = entries[k]
        if v.curtime < enginetick/6 then continue end
		if k > max_renders or v.pos:DistToSqr(EyePos()) > max_renderdistance then continue end
        if v.renderer then
            v.renderer()
            return
        end

        if not v.render.lerpvec then
            v.render.lerpvec = v.pos
            v.render.lerplastvec = v.lastpos
            v.render.approachvec = Vec0
        end
        v.render.lerpvec = LerpVector(FrameTime() * 18, v.render.lerpvec, v.pos)
        v.render.lerplastvec = LerpVector(FrameTime() * 40, v.render.lerplastvec, v.render.lerpvec)
        v.render.approachvec = LerpVector(FrameTime() * 5, v.render.approachvec, Vec0)

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