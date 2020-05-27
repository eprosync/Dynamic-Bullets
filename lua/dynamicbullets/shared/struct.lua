function DynamicBullets.SHStruct(BulletStruct)
	function BulletStruct:SetVelocity(vel)
		self.vel = self.vel:GetNormalized() * vel
	end

	function BulletStruct:SetVelocityRaw(vel)
		self.vel = vel
	end

	function BulletStruct:EnablePenetration(bool)
		self.weaponattributes.CanPenetrate = bool
	end

	function BulletStruct:SetPenetration(PenetrationRange, PenetrationStrength, PenetrationSurfaces)
		self.weaponattributes.PenetrationRange = PenetrationRange
		self.weaponattributes.PenetrationStrength = PenetrationStrength
		self.weaponattributes.PenetrationSurfaces = PenetrationSurfaces
	end

	function BulletStruct:EnableRicochet(bool)
		self.weaponattributes.CanRicochet = bool
	end

	function BulletStruct:PhysicCalc()
		local fg, time, curvel = DynamicBullets.Gravity, self.time, self.vel
		return (curvel * time) + (.5 * fg * (time * time)), curvel + (fg * time)
	end

	function BulletStruct:RandSeed()
		return math.Round(self.originpos.x + self.originpos.y + self.originpos.z + self.originvel.x + self.originvel.y + self.originvel.z)
	end

	function BulletStruct:CanPenetrate(trace, dot)
		local weaponattributes = self.weaponattributes
		return (weaponattributes.CanPenetrate and not weaponattributes.NoPenetration[trace.MatType] and dot > 0.26 and self.LayersPenetrated < 4)
	end

	function BulletStruct:PenetrateSurface(trace, dot)
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
			self.pos = trace.HitPos

			local penDist = (penlen - trace.HitPos:Distance(hit_pos))
			if SERVER then
				weaponattributes.force = weaponattributes.force * (penDist / penlen) * 0.75
				weaponattributes.dmgmul = weaponattributes.dmgmul * (penDist / penlen) * 0.75
			end
			self.vel = self.vel * (penDist / penlen) * 0.85

			self.LayersPenetrated = self.LayersPenetrated + 1
		else
			return true 
		end
	end

	function BulletStruct:CanRicochet(trace, dot)
		local weaponattributes = self.weaponattributes
		return (weaponattributes.CanRicochet and not weaponattributes.NoRicochet[trace.MatType] and weaponattributes.PenetrationRange * trace.Fraction < weaponattributes.PenetrationRange and dot < 0.26)
	end
	
	function BulletStruct:RicochetSurface(trace, dot)
		local dir = self.vel:GetNormalized()
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
		if CLIENT then
			self:RicochetSound()
		end
	end

	function BulletStruct:Calculate(tick)
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

		local displace, newvel = self:PhysicCalc()

		self.lasttime = self.curtime
		self.lastpos = self.pos
		self.dir = displace:GetNormalized()

        -- We need to trace so that we know if we hit anything, duh
		local trace = util.TraceLine({
			start = self.pos,
			endpos = self.pos + displace,
			filter = self.owner,
			mask = MASK_SHOT
		})

		if CLIENT then
			self:NearMissSound()
		end

		self.pos = (self.pos + displace)
		self.vel = newvel

        -- In theory all this penetration calculations i made should work aswell.
		if trace.Hit and trace.HitPos ~= self.lastpos then
			if trace.HitSky then
				return true
			end

            local dir = self.vel:GetNormalized()

			if CLIENT then
				self:EffectSurface(self.lastpos, dir, displace:Length())
			end

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

	function BulletStruct:SetDamage(Min, Max)
	end
	function BulletStruct:SetRange(Min, Max)
	end
	function BulletStruct:CalculateDamage(dist)
	end
	function BulletStruct:DamageEntity(trace)
	end
	function BulletStruct:Sync(override)
	end
end