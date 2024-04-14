function IsAdmin(src)
    if wx.Framework:lower() == "standalone" then
        return IsPlayerAceAllowed(src, 'weathersync.allow') == 1 and true
    elseif wx.Framework:lower() == "esx" then
        ESX = exports["es_extended"]:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(src)
        return wx.ESXGroups[xPlayer.getGroup()]
    elseif wx.Framework:lower() == "custom" then
        -- implement your own permission checking system
        return true
    end
end

lib.callback.register('wx_timesync:server:requestSync', function(source, data)
    if not IsAdmin(source) then return end
    if data then
        TriggerClientEvent('wx_timesync:client:syncTime', -1, data)
        return true
    end
    return false
end)

lib.callback.register('wx_timesync:server:requestWeatherSync', function(source, weatherType)
    if not IsAdmin(source) then return end

    if weatherType then
        TriggerClientEvent('wx_timesync:client:syncWeather', -1, weatherType)
        return true
    end
    return false
end)

lib.callback.register('wx_timesync:server:requestFreezeTime', function(source, data)
    if not IsAdmin(source) then return end
    if not data then return false end
    TriggerClientEvent('wx_timesync:client:freezeTime', -1, data)
    return true
end)


---@TODO somehow prevent clients to have different time than others
-- CreateThread(function()
--     while true do
--         Wait(1000)
--         local hours = GetClockHours()
--         local minutes = GetClockMinutes()
--         TriggerClientEvent('wx_timesync:client:syncTime', -1, { h = hours, m = minutes })
--     end
-- end)
