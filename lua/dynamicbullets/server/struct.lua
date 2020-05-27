hook.Add('DynamicBullets.CreateStruct', 'SVStruct', function(BulletStruct)
    local BulletAttributes = table.Copy(BulletStruct.weaponattributes)

    BulletStruct.weaponattributes.dmgmax = 1
    BulletStruct.weaponattributes.dmgmin = 0
    BulletStruct.weaponattributes.rangemax = 1
    BulletStruct.weaponattributes.rangemin = 0
    BulletStruct.weaponattributes.dmgmul = 1
    BulletStruct.weaponattributes.force = 1

	function BulletStruct:SetDamage(Min, Max)
		self.weaponattributes.dmgmax = Max
		self.weaponattributes.dmgmin = Min
	end

	function BulletStruct:SetRange(Min, Max)
		self.weaponattributes.rangemax = Max
		self.weaponattributes.rangemin = Min
	end

	function BulletStruct:CalculateDamage(dist)
		local weaponattributes = self.weaponattributes
		local dmgMax, dmgMin = weaponattributes.dmgmax, weaponattributes.dmgmin
		local rangeMin, rangeMax = weaponattributes.rangemin, weaponattributes.rangemax
		dmg = dist < rangeMin and dmgMax or dist < rangeMax and (dmgMin - dmgMax) / (rangeMax - rangeMin) * (dist - rangeMin) + dmgMax or dmgMin
		dmg = dmg * weaponattributes.dmgmul
		return dmg
	end

	function BulletStruct:DamageEntity(trace)
		local dmg = self:CalculateDamage((self.pos - self.originpos):Length())

		local dmginfo = DamageInfo()
		local magnitude, dir = self.vel:Length(), self.vel:GetNormalized()
		dmginfo:SetAttacker( self.owner )
		dmginfo:SetInflictor( self.inflictor )
		dmginfo:SetDamage( dmg )
		dmginfo:SetDamageType( DMG_BULLET )
		dmginfo:SetDamageForce( dir * (magnitude * (1/dmg)) )
		dmginfo:SetDamagePosition( trace.HitPos )

		if trace.Entity:IsPlayer() then
			hook.Run( "ScalePlayerDamage", trace.Entity, trace.HitGroup, dmginfo)
			if GAMEMODE.ScalePlayerDamage then GAMEMODE:ScalePlayerDamage(trace.Entity, trace.HitGroup, dmginfo) end
		elseif trace.Entity:IsNPC() then
			hook.Run( "ScaleNPCDamage", trace.Entity, trace.HitGroup, dmginfo)
			if GAMEMODE.ScaleNPCDamage then GAMEMODE:ScaleNPCDamage(trace.Entity, trace.HitGroup, dmginfo) end
		end

		trace.Entity:TakeDamageInfo( dmginfo )
	end

	function BulletStruct:WriteAttributes()
		local attribs = {}
		for k, v in pairs(BulletAttributes) do
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

	function BulletStruct:Sync(override)
        net.Start('DynamicBullets.Fired', true)
        net.WriteEntity(self.owner)
        net.WriteEntity(self.inflictor)
        net.WriteString(self.originpos.x .. '|' .. self.originpos.y .. '|' .. self.originpos.z)
        net.WriteString(self.originvel.x .. '|' .. self.originvel.y .. '|' .. self.originvel.z)
        if not override then
            if self:WriteAttributes() == false then
                override = true
            end
        end
        net.WriteBool(override)
        if self.owner:IsPlayer() then
            net.SendOmit(self.owner)
        else
            net.Broadcast()
        end
	end
end)