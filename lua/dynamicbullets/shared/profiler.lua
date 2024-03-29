local function math_Round( num, idp )
	local mult = 10 ^ ( idp or 0 )
	return math.floor( num * mult + 0.5 ) / mult
end

local Profiling_Clock = {}
function DynamicBullets.Profiling_Start(profile)
    if not DynamicBullets.Debug then return end
    local profileclock = Profiling_Clock[profile]
    if profileclock then
        profileclock[#profileclock + 1] = SysTime()
        return
    end
    Profiling_Clock[profile] = {SysTime()}
end

function DynamicBullets.Profiling_End(profile)
    if not DynamicBullets.Debug then return end
    local profileclock = Profiling_Clock[profile]
    if profileclock then
        local profilelen = #profileclock
        local result = 0
        for i=1, profilelen do
            result = result + profileclock[i]
        end
        result = result / profilelen
        Profiling_Clock[profile] = nil
        return math_Round(result, 6)
    end
    return 0
end

function DynamicBullets.Profiling_Push(profile)
    if not DynamicBullets.Debug then return end
    local profileclock = Profiling_Clock[profile]
    if profileclock then
        local profilelen = #profileclock
        local curprofile = profileclock[profilelen]
        local result = SysTime() - curprofile
        profileclock[profilelen] = result
        return math_Round(result, 6)
    end
    return 0
end

function DynamicBullets.Profiling_GetLength(profile)
    if not DynamicBullets.Debug then return end
    local profileclock = Profiling_Clock[profile]
    if profileclock then
        return #profileclock
    end
    return 0
end