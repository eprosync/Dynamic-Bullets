local _math_random = math.random
local _util_JSONToTable = util.JSONToTable
local _util_Decompress = util.Decompress
local _GetViewEntity = (CLIENT and GetViewEntity or nil)
local _EyePos = (CLIENT and EyePos or nil)
local _EmitSound = EmitSound
local _net_ReadData = net.ReadData
local _LocalPlayer = (CLIENT and LocalPlayer or nil)
local _net_ReadUInt = net.ReadUInt
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

function DynamicBullets.CLStruct(BulletStruct)
    BulletStruct.Sounds = {
        NearMiss = nearmiss,
        Ricochet = ricochet,
    }

    BulletStruct.render = { -- simple rendering stuff, make bullets fancy :D
        lerpvec = false,
        lerplastvec = false,
    }

	function BulletStruct:RicochetSound()	
		local pos = _EyePos()
		if _GetViewEntity() ~= _LocalPlayer() then
			pos = _GetViewEntity():GetPos()
		end
		if pos:DistToSqr(self.pos) < 60000 then
			local tbl = self.Sounds.Ricochet
			_EmitSound( tbl[_math_random(#tbl)], self.pos, -1, CHAN_AUTO, 1, 45, 0, 100 )
		end
	end

	function BulletStruct:EffectSurface(src, dir, dist)
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

	function BulletStruct:NearMissSound()	
		if not self.swish and (self.owner ~= _LocalPlayer() or _GetViewEntity() ~= _LocalPlayer()) then
			local pos = _EyePos()
			if _GetViewEntity() ~= _LocalPlayer() then
				pos = _GetViewEntity():GetPos()
			end
			if pos:DistToSqr(self.pos) < 5000 then
				self.swish = true
				local tbl = self.Sounds.NearMiss
				_EmitSound( tbl[_math_random(#tbl)], self.pos, -1, CHAN_AUTO, 1, 45, 0, 100 )
			end
		end
	end

	function BulletStruct:ReadAttributes()
		local attribs = _util_JSONToTable(_util_Decompress(_net_ReadData(_net_ReadUInt(16))))
		for k=1, #attribs do
			local v = attribs[k]
			self.weaponattributes[v[1]] = v[2]
		end
	end
end