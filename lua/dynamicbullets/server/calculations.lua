util.AddNetworkString('DynamicBullets.Fired')

function DynamicBullets:FireBullet(owner, SWEP, pos, vel, cb)
	local bul = self:DynamicBullet(owner, SWEP, pos, vel)
	local entries = self.BulletEntries
    local override

	if cb then
		override = cb(bul)
	end

	if hook.Run('DynamicBullets.Fired', bul) and not override then
        override = true
    end

	if not owner.dbulletentires then
		owner.dbulletentires = {}
	end

	if owner:IsPlayer() then
		owner.dbulletentires[#owner.dbulletentires + 1] = bul
	else
		entries[#entries + 1] = bul
	end
end

hook.Add('FinishMove', 'DynamicBullets.Calc', function(pl, mv)
    local entries = pl.dbulletentires
	if not entries then return end
	local entries_len = #entries
	if entries_len < 1 then return end

    local ct = CurTime()
    local calcs, tickseng, ticks = 1, engine.TickInterval(), 1
    if DynamicBullets.MultiCalc then
        calcs = DynamicBullets.MultiCalc
        ticks = tickseng / calcs
    end

    local removals = 0
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
    local ct = CurTime()
    local calcs, tickseng, ticks = 1, engine.TickInterval(), 1
    if DynamicBullets.MultiCalc then
        calcs = DynamicBullets.MultiCalc
        ticks = tickseng / calcs
    end
    local removals = 0
	DynamicBullets.Profiling_Start('BulletCalc_NonPlayer')
    for k = 1, entries_len do
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
    DynamicBullets.Profiling_Push('BulletCalc_NonPlayer')
	if entries_len - removals < 1 and DynamicBullets.Debug then
		local traces = DynamicBullets.Profiling_GetLength('BulletCalc_NonPlayer')
        
		DynamicBullets.DBGPrint('Avg Non-Player Calc Time: ' .. DynamicBullets.Profiling_End('BulletCalc_NonPlayer') .. ' (' .. traces .. ' Traces, ' .. ((1/tickseng) + DynamicBullets.MultiCalc - 1) .. ' Calcs/s)')
	end
end)