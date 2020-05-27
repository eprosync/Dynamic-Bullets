-- Simple renderer for bullets, make things look nice :)
local trail = Material('effects/laser_tracer')
local head = Material('sprites/light_ignorez')
local enginetick = engine.TickInterval()
local Vec0 = Vector()
hook.Add('PreDrawTranslucentRenderables', 'DynamicBullets.Render', function()
    local entries = DynamicBullets.BulletEntries
    local max_renderdistance = DynamicBullets.RenderDistance
    local max_renders = DynamicBullets.MaxRenders

    for k = 1, #entries do
        local v = entries[k]
        if v.curtime < enginetick/6 then continue end
		if k > max_renders or v.pos:DistToSqr(EyePos()) > max_renderdistance then continue end
        if v.renderer then
            v.renderer()
            return
        end

        local renderdata = v.render

        if not renderdata.lerpvec then
            renderdata.lerpvec = v.pos
            renderdata.lerplastvec = v.lastpos
            renderdata.approachvec = Vec0
        end
        renderdata.lerpvec = LerpVector(FrameTime() * 20, renderdata.lerpvec, v.pos)
        renderdata.lerplastvec = LerpVector(FrameTime() * 20, renderdata.lerplastvec, renderdata.lerpvec)
        renderdata.approachvec = LerpVector(FrameTime() * 5, renderdata.approachvec, Vec0)

        if v.pos ~= v.lastpos then
			render.SetMaterial(trail)
			render.StartBeam( 2 )
			render.AddBeam(renderdata.lerpvec + renderdata.approachvec, 3, 0, v.bulletcolor)
			render.AddBeam(renderdata.lerplastvec + renderdata.approachvec, 3, 1, v.bulletcolor)
			render.EndBeam()
        end
    end

    local Local_BulletEntries = DynamicBullets.Local_BulletEntries
    for k = 1, #Local_BulletEntries do
        local v = Local_BulletEntries[k]
        if v.curtime < enginetick/6 then continue end
		if k > max_renders or v.pos:DistToSqr(EyePos()) > max_renderdistance then continue end
        if v.renderer then
            v.renderer()
            return
        end

        local renderdata = v.render

        if not renderdata.lerpvec then
            renderdata.lerpvec = v.pos
            renderdata.lerplastvec = v.lastpos
            renderdata.approachvec = Vec0
        end
        renderdata.lerpvec = LerpVector(FrameTime() * 20, renderdata.lerpvec, v.pos)
        renderdata.lerplastvec = LerpVector(FrameTime() * 20, renderdata.lerplastvec, renderdata.lerpvec)
        renderdata.approachvec = LerpVector(FrameTime() * 2, renderdata.approachvec, Vec0)

        if v.pos ~= v.lastpos then
			render.SetMaterial(trail)
			render.StartBeam( 2 )
			render.AddBeam(renderdata.lerplastvec + renderdata.approachvec, 3, 0, v.bulletcolor)
			render.AddBeam(renderdata.lerpvec + renderdata.approachvec, 3, 1, v.bulletcolor)
			render.EndBeam()
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