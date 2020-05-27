util.AddNetworkString('DynamicBullets.Fired')

function DynamicBullets:FireBullet(owner, SWEP, pos, vel, cb)
	local bul = self:DynamicBullet(owner, SWEP, pos, vel)
	local entries = self.BulletEntries
	if cb then
		cb(bul)
	end

	local override = hook.Run('DynamicBullets.Fired', bul)
	if not override then
		bul:Sync()
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
	local entires_len = #entries
	if entires_len < 1 then return end

    local ct = CurTime()
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
                table.remove(entries, k)
                removals = removals + 1
                break
            end
        end
    end
	pl:LagCompensation(false)
end)

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