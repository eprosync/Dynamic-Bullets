local _Vector = Vector
--[[
    Eqn,
    vf = final velocity
    vi = initial velocity
    a = acceleration
    t = time
    d = displacement

    vf = vi + a(t) - missing d
    vf^2 = vi^2 + 2(a)(d) - missing t
    d = vi(t) + 1/2(a)(t)^2 -- mising vf
    d = 1/2(vi + vf)(t) -- mising a
    d = vf(t) - 1/2(a)(t)^2 -- mising vi

	Use these for your modifications also,
	they are VERY important for this entire system to work.
	Ty GR 11/12 physics teacher :)
--]]

-- 9.8 m/s^2 is the acceleration of gravity on earth.
-- In hammer it's about 514 units/s^2
DynamicBullets.Gravity = _Vector(0, 0, -(4 * 514.43569553806)) -- This is acceleration not velocity.

-- Distributes curtime into multiple calculation instances.
-- This allows more accurate calculations for when hitting objects and etc.
-- I suggest doing this when at a low tick like 33 - 11 as this will increase the need for more resources
DynamicBullets.MultiCalc = 4

-- Rendering habbits, ya know for FPS
DynamicBullets.RenderDistance = 15000*15000
DynamicBullets.MaxRenders = 60

-- For debugging bullet travel and velocity
DynamicBullets.Debug = true