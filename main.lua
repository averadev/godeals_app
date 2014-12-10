---------------------------------------------------------------------------------
-- Birdz Videogame
-- Alberto Vera
-- GeekBucket Software Factory
---------------------------------------------------------------------------------

local launchArgs = ...      -- at the top of your program code
local storyboard = require "storyboard"
local DBManager = require('src.resources.DBManager')
local Globals = require('src.resources.Globals')

local isUser = DBManager.setupSquema()
local isNotification = false

if launchArgs then
    if launchArgs.androidIntent then
        if launchArgs.androidIntent.extras then
            if launchArgs.androidIntent.extras.type then
                Globals.idDisplay = launchArgs.androidIntent.extras.beaconId
            end
        end
    end
end

if isUser then
    storyboard.gotoScene("src.Home")
else
    storyboard.gotoScene("src.Login")
end


--[[
protected GirlBean[] girls = { 
			new GirlBean("1a4f5be7-6683-44a6-b559-b8bf6efd9ad7", "Lala", 0),
			new GirlBean("f7826da6-4fa2-4e98-8024-bc5b71e0893e", "Lili", 0),
			new GirlBean("a1ea8136-0e1b-d4a1-b840-63f88c8da1ea", "Lulu", 0),
			new GirlBean("1acbad6e-e1a5-4838-a62a-22d35d00c35b", "Kontac", 0)};
]]--
-- Create and change scene

--DBManager.updateUser(1, "mrfeto@gmail.com", '', 'Alberto Vera', '10152713865899218', '') -- Temporal



