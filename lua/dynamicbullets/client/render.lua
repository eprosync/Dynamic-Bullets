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

        if not v.render.lerpvec then
            v.render.lerpvec = v.pos
            v.render.lerplastvec = v.lastpos
            v.render.approachvec = Vec0
        end
        v.render.lerpvec = LerpVector(FrameTime() * 18, v.render.lerpvec, v.pos)
        v.render.lerplastvec = LerpVector(FrameTime() * 40, v.render.lerplastvec, v.render.lerpvec)
        v.render.approachvec = LerpVector(FrameTime() * 5, v.render.approachvec, Vec0)

        if v.pos ~= v.lastpos then
			render.SetMaterial(trail)
			render.StartBeam( 2 )
			render.AddBeam(v.render.lerpvec + v.render.approachvec, 2, 0, Color(200, 145, 0))
			render.AddBeam(v.render.lerplastvec + v.render.approachvec, 2, 1, Color(200, 145, 0))
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

        if not v.render.lerpvec then
            v.render.lerpvec = v.pos
            v.render.lerplastvec = v.lastpos
            v.render.approachvec = Vec0
        end
        v.render.lerpvec = LerpVector(FrameTime() * 14, v.render.lerpvec, v.pos)
        v.render.lerplastvec = LerpVector(FrameTime() * 50, v.render.lerplastvec, v.render.lerpvec)
        v.render.approachvec = LerpVector(FrameTime() * 2, v.render.approachvec, Vec0)

        if v.pos ~= v.lastpos then
			render.SetMaterial(trail)
			render.StartBeam( 2 )
			render.AddBeam(v.render.lerplastvec + v.render.approachvec, 2, 0, Color(200, 145, 0))
			render.AddBeam(v.render.lerpvec + v.render.approachvec, 2, 1, Color(200, 145, 0))
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