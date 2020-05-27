local _net_WriteData = net.WriteData
local _util_TableToJSON = util.TableToJSON
local _table_Copy = table.Copy
local _net_WriteEntity = net.WriteEntity
local _net_Broadcast = (SERVER and net.Broadcast or nil)
local _util_Compress = util.Compress
local _net_WriteString = net.WriteString
local _net_SendOmit = (SERVER and net.SendOmit or nil)
local _hook_Run = hook.Run
local _DamageInfo = DamageInfo
local _net_Start = net.Start
local _net_WriteBool = net.WriteBool
local _pairs = pairs
local _net_WriteUInt = net.WriteUInt
function DynamicBullets.SVStruct(BulletStruct)
    local BulletAttributes = _table_Copy(BulletStruct.weaponattributes)

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

		local dmginfo = _DamageInfo()
		local magnitude, dir = self.vel:Length(), self.vel:GetNormalized()
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

	function BulletStruct:WriteAttributes()
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

	function BulletStruct:Sync(override)
        _net_Start('DynamicBullets.Fired', true)
        _net_WriteEntity(self.owner)
        _net_WriteEntity(self.inflictor)
        _net_WriteString(self.originpos.x .. '|' .. self.originpos.y .. '|' .. self.originpos.z)
        _net_WriteString(self.originvel.x .. '|' .. self.originvel.y .. '|' .. self.originvel.z)
        if not override then
            if self:WriteAttributes() == false then
                override = true
            end
        end
        _net_WriteBool(override)
        if self.owner:IsPlayer() then
            _net_SendOmit(self.owner)
        else
            _net_Broadcast()
        end
	end
end