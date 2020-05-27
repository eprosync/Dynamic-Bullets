DynamicBullets.Local_BulletEntries = {}
local Local_BulletEntries = DynamicBullets.Local_BulletEntries

function DynamicBullets:FireBullet(owner, SWEP, pos, vel, cb)
	local bul = self:DynamicBullet(owner, SWEP, pos, vel)
	local entries = self.BulletEntries

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

	local override = hook.Run('DynamicBullets.Fired', bul)
	if not override then
		bul:Sync()
	end

	if owner == LocalPlayer() then
		Local_BulletEntries[#Local_BulletEntries + 1] = bul
	else
		entries[#entries + 1] = bul
	end
end

net.Receive('DynamicBullets.Fired', function()
	local owner, SWEP, pos, vel = net.ReadEntity(), net.ReadEntity(), net.ReadString(), net.ReadString()
	if IsValid(SWEP) and IsValid(owner) then
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

hook.Add('FinishMove', 'DynamicBullets.CalcPredicted', function(pl, mv)
    if pl ~= LocalPlayer() then return end
    local entries = Local_BulletEntries
	local entries_len = #entries
	if entries_len < 1 then return end

    local ct = CurTime()
    local removals = 0

    local calcs, tickseng, ticks = 1, engine.TickInterval(), 1
    if DynamicBullets.MultiCalc then
        calcs = DynamicBullets.MultiCalc
        ticks = tickseng / calcs
    end
	
	DynamicBullets.Profiling_Start('BulletCalc_Player')
	pl:LagCompensation(true)
    for k = 1, entries_len do
        k = k - removals
        local v = entries[k]
        if not v or v.owner ~= pl then continue end
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
                    ["time"] = (ct - (ticks * calcs) + (c * ticks)) + 1
                }
            end
        end
    end
	pl:LagCompensation(false)
    DynamicBullets.Profiling_Push('BulletCalc_Player')
	if entries_len - removals < 1 and DynamicBullets.Debug then
		local traces = DynamicBullets.Profiling_GetLength('BulletCalc_Player')
		DynamicBullets.DBGPrint('Avg Player Calc Time: ' .. DynamicBullets.Profiling_End('BulletCalc_Player') .. ' (' .. traces .. ' Traces, ' .. ((1/tickseng) + DynamicBullets.MultiCalc - 1) .. ' Calcs/s)')
	end
end)

hook.Add('Tick', 'DynamicBullets.Calc', function()
    local entries = DynamicBullets.BulletEntries
	local entries_len = #entries
	if entries_len < 1 then return end
	local LP = LocalPlayer()
    local removals = 0

    local calcs, tickseng, ticks = 1, engine.TickInterval(), 1
    if DynamicBullets.MultiCalc then
        calcs = DynamicBullets.MultiCalc
        ticks = tickseng / calcs
    end

	DynamicBullets.Profiling_Start('BulletCalc_NonPlayer')
    for k = 1, entries_len do
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
                    ["time"] = (ct - (ticks * calcs) + (c * ticks)) + 1
                }
            end
        end
    end
    DynamicBullets.Profiling_Push('BulletCalc_NonPlayer')
	if entries_len - removals < 1 and DynamicBullets.Debug then
		local traces = DynamicBullets.Profiling_GetLength('BulletCalc_NonPlayer')
		DynamicBullets.DBGPrint('Avg Non-Player Calc Time: ' .. DynamicBullets.Profiling_End('BulletCalc_NonPlayer') .. ' (' .. traces .. ' Traces, ' .. ((1/tickseng) + DynamicBullets.MultiCalc - 1) .. ' Calcs/s)')
	end
end)