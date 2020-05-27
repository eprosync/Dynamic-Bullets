local _LerpVector = LerpVector
local _FrameTime = FrameTime
local _Material = Material
local _render_SetMaterial = (CLIENT and render.SetMaterial or nil)
local _render_StartBeam = (CLIENT and render.StartBeam or nil)
local _Vector = Vector
local _render_AddBeam = (CLIENT and render.AddBeam or nil)
local _render_EndBeam = (CLIENT and render.EndBeam or nil)
local _render_DrawLine = (CLIENT and render.DrawLine or nil)
local _EyePos = (CLIENT and EyePos or nil)
local _CurTime = CurTime
local _Color = Color
local _hook_Add = hook.Add
local _table_remove = table.remove
-- Simple renderer for bullets, make things look nice :)
local trail = _Material('effects/laser_tracer')
local head = _Material('sprites/light_ignorez')
local enginetick = engine.TickInterval()
local Vec0 = _Vector()
_hook_Add('PreDrawTranslucentRenderables', 'DynamicBullets.Render', function()
    local entries = DynamicBullets.BulletEntries
    local max_renderdistance = DynamicBullets.RenderDistance
    local max_renders = DynamicBullets.MaxRenders

    for k = 1, #entries do
        local v = entries[k]
        if v.curtime < enginetick/6 then continue end
		if k > max_renders or v.pos:DistToSqr(_EyePos()) > max_renderdistance then continue end
        if v.renderer then
            v.renderer()
            return
        end

        if not v.render.lerpvec then
            v.render.lerpvec = v.pos
            v.render.lerplastvec = v.lastpos
            v.render.approachvec = Vec0
        end
        v.render.lerpvec = _LerpVector(_FrameTime() * 20, v.render.lerpvec, v.pos)
        v.render.lerplastvec = _LerpVector(_FrameTime() * 20, v.render.lerplastvec, v.render.lerpvec)
        v.render.approachvec = _LerpVector(_FrameTime() * 5, v.render.approachvec, Vec0)

        if v.pos ~= v.lastpos then
			_render_SetMaterial(trail)
			_render_StartBeam( 2 )
			_render_AddBeam(v.render.lerpvec + v.render.approachvec, 3, 0, _Color(200, 145, 0))
			_render_AddBeam(v.render.lerplastvec + v.render.approachvec, 3, 1, _Color(200, 145, 0))
			_render_EndBeam()
        end
    end

    local Local_BulletEntries = DynamicBullets.Local_BulletEntries
    for k = 1, #Local_BulletEntries do
        local v = Local_BulletEntries[k]
        if v.curtime < enginetick/6 then continue end
		if k > max_renders or v.pos:DistToSqr(_EyePos()) > max_renderdistance then continue end
        if v.renderer then
            v.renderer()
            return
        end

        if not v.render.lerpvec then
            v.render.lerpvec = v.pos
            v.render.lerplastvec = v.lastpos
            v.render.approachvec = Vec0
        end
        v.render.lerpvec = _LerpVector(_FrameTime() * 20, v.render.lerpvec, v.pos)
        v.render.lerplastvec = _LerpVector(_FrameTime() * 20, v.render.lerplastvec, v.render.lerpvec)
        v.render.approachvec = _LerpVector(_FrameTime() * 2, v.render.approachvec, Vec0)

        if v.pos ~= v.lastpos then
			_render_SetMaterial(trail)
			_render_StartBeam( 2 )
			_render_AddBeam(v.render.lerplastvec + v.render.approachvec, 3, 0, _Color(200, 145, 0))
			_render_AddBeam(v.render.lerpvec + v.render.approachvec, 3, 1, _Color(200, 145, 0))
			_render_EndBeam()
        end
    end
end)

-- Simply debugger for bullet trajectories
_hook_Add( "PostDrawOpaqueRenderables", "DynamicBullets.Debug", function()
    if not DynamicBullets.Debug then return end
    local debugtable = DynamicBullets.DebugTable
    local removes = 0
    for k=1, #debugtable do
        k = k - removes
        local v = debugtable[k]
        _render_DrawLine( v["start"], v["end"], (v["color"] and v["color"] or _Color(255,255,255)) )
        if v["time"]  < _CurTime() then
            removes = removes + 1
            _table_remove(debugtable, k)
        end
    end
end)