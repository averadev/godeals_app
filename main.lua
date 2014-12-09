---------------------------------------------------------------------------------
-- Birdz Videogame
-- Alberto Vera
-- GeekBucket Software Factory
---------------------------------------------------------------------------------

local launchArgs = ...      -- at the top of your program code
local storyboard = require "storyboard"
local DBManager = require('src.resources.DBManager')

local isUser = DBManager.setupSquema()
local isNotification = false

if launchArgs then
    if launchArgs.androidIntent then
        if launchArgs.androidIntent.extras then
            if launchArgs.androidIntent.extras.type then
                isNotification = true
            end
        end
    end
end

if not (isNotification) then
    if isUser then
        storyboard.gotoScene("src.Home")
    else
        storyboard.gotoScene("src.Login")
    end
else
    
end




-- Create and change scene

--DBManager.updateUser(1, "mrfeto@gmail.com", '', 'Alberto Vera', '10152713865899218', '') -- Temporal



