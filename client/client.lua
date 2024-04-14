function FormatDigit(d)
    if not d then return 0 end
    if string.len(d) == 1 then
        return ("0" .. d)
    end
    return d
end

local savedsettings = {
    ["ft"] = false,
    ["fw"] = false
}

local timeToFreeze = {}
local weatherToFreeze = ""

local weathertypes = {
    ["Blizzard"] = { type = "BLIZZARD", icon = "snowflake", color = "#4682B4" },
    ["Clear"] = { type = "CLEAR", icon = "sun", color = "#FFD700" },
    ["Clearing"] = { type = "CLEARING", icon = "sun", color = "#FFA07A" },
    ["Cloudy"] = { type = "CLOUDS", icon = "cloud", color = "#808080" },
    ["Extra Sunny"] = { type = "EXTRASUNNY", icon = "sun", color = "#FFA500" },
    ["Festive"] = { type = "XMAS", icon = "snowflake", color = "#FF6347" },
    ["Foggy"] = { type = "FOGGY", icon = "smog", color = "#B0C4DE" },
    ["Neutral"] = { type = "NEUTRAL", icon = "adjust", color = "#D3D3D3" },
    ["Overcast"] = { type = "OVERCAST", icon = "cloud", color = "#A9A9A9" },
    ["Rain"] = { type = "RAIN", icon = "cloud-rain", color = "#6495ED" },
    ["Smog"] = { type = "SMOG", icon = "smog", color = "#C0C0C0" },
    ["Snowing"] = { type = "SNOW", icon = "snowflake", color = "#FFFFFF" },
    ["Snowlight"] = { type = "SNOWLIGHT", icon = "snowflake", color = "#87CEEB" },
    ["Thunder"] = { type = "THUNDER", icon = "bolt", color = "#708090" },
}




local opt = {}

local function sortWeatherTypes(wtypes)
    local sortedLabels = {}
    for label, _ in pairs(wtypes) do
        table.insert(sortedLabels, label)
    end
    table.sort(sortedLabels)
    return sortedLabels
end

local sortedLabels = sortWeatherTypes(weathertypes)

for _, label in ipairs(sortedLabels) do
    local data = weathertypes[label]
    table.insert(opt, {
        title = label,
        icon = data.icon,
        iconColor = data.color,
        onSelect = function()
            local success = lib.callback.await('wx_timesync:server:requestWeatherSync', false, data.type)
            if success then
                lib.notify({ title = "Time Sync", description = "Weather has been changed to " .. label })
            end
        end
    })
end


function SyncMenu()
    lib.registerContext({
        id = 'timesync',
        title = 'Time Sync Settings',
        options = {
            {
                title = 'Change Time',
                icon = "clock",
                onSelect = function()
                    local time = lib.inputDialog('Time Sync', {
                        { type = 'slider', label = 'Hour',   default = GetClockHours(),   required = true, min = 0, max = 24 },
                        { type = 'slider', label = 'Minute', default = GetClockMinutes(), required = true, min = 0, max = 59 },
                    })
                    if time then
                        local success = lib.callback.await('wx_timesync:server:requestSync', false,
                            { h = time[1], m = time[2] })
                        if savedsettings["ft"] then
                            lib.callback.await('wx_timesync:server:requestFreezeTime', false,
                                { h = time[1], m = time[2] })
                        end
                        if success then
                            lib.notify({
                                title = "Time Sync",
                                description = ("Time has been changed to %s:%s"):format(FormatDigit(time[1]),
                                    FormatDigit(time[2]))
                            })
                        end
                    end
                end
            },
            {
                title = 'Change Weather',
                icon = "cloud-sun",
                onSelect = function()
                    lib.registerContext({
                        id = 'weather',
                        title = 'Weather Sync',
                        options = opt
                    })

                    lib.showContext('weather')
                end
            },
            {
                title = 'Settings',
                icon = "cog",
                onSelect = function()
                    local settings = lib.inputDialog('Sync Settings', {
                        { type = 'checkbox', label = 'Freeze Time', checked = (savedsettings["ft"]) },
                        ---@TODO Freeze Weather
                        -- { type = 'checkbox', label = 'Freeze Weather', checked = (savedsettings["fw"]) },
                    }, { allowCancel = false })

                    if settings[1] then
                        local currentTime = {
                            h = GetClockHours(),
                            m = GetClockMinutes()
                        }
                        local success = lib.callback.await('wx_timesync:server:requestFreezeTime', false,
                            currentTime)
                        if success then
                            savedsettings["ft"] = true
                            lib.notify({
                                title = "Time Sync",
                                description = "Time has been frozen"
                            })
                        end
                    elseif not settings[1] then
                        savedsettings["ft"] = false
                    end
                end
            },
        }
    })
    lib.showContext('timesync')
end

RegisterNetEvent('wx_timesync:client:syncTime', function(data)
    -- print(json.encode(data))
    if not data.h or not data.m then return end
    NetworkOverrideClockTime(data.h, data.m, 00)
end)

RegisterNetEvent('wx_timesync:client:freezeTime', function(data)
    if not data.h or not data.m then return end
    timeToFreeze = data
    while savedsettings["ft"] do
        Wait(1000)
        NetworkOverrideClockTime(timeToFreeze.h, timeToFreeze.m, 00)
    end
end)

RegisterNetEvent('wx_timesync:client:freezeWeather', function(weather)
    if not weather then return end
    weatherToFreeze = weather
    CreateThread(function()
        while savedsettings["fw"] do
            Wait(10000)
            ClearOverrideWeather()
            ClearWeatherTypePersist()
            SetWeatherTypePersist(weatherToFreeze)
            SetWeatherTypeNow(weatherToFreeze)
            SetWeatherTypeNowPersist(weatherToFreeze)
        end
    end)
end)

RegisterNetEvent('wx_timesync:client:syncWeather', function(weather)
    if not weather then return end
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)
end)

RegisterCommand(wx.Command or 'timesync', function()
    local admin = lib.callback.await('wx_timesync:server:checkPerms', false)
    if admin then
        SyncMenu()
    else
        lib.notify({ title = "Time Sync", description = "You are not allowed to use this command!", type = "error" })
    end
end, false)
