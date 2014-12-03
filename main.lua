---------------------------------------------------------------------------------
-- Birdz Videogame
-- Alberto Vera
-- GeekBucket Software Factory
---------------------------------------------------------------------------------

local launchArgs = ...      -- at the top of your program code
-- On Open
local onNotification = function( event )
    if event.custom then
        native.showAlert( "Go Deals", "Open", { "OK"})
    end
end 
-- On Closed
if launchArgs and launchArgs.notification then
     native.showAlert( "Go Deals", "Closed", { "OK"})
 end


os.execute('cls')
if display.topStatusBarContentHeight > 15 then
    display.setStatusBar( display.TranslucentStatusBar )
else
    display.setStatusBar( display.HiddenStatusBar )
end

-- Requeridos
local DBManager = require('src.resources.DBManager')
storyboard = require "storyboard"


-- Create and change scene
local isUser = DBManager.setupSquema()
--DBManager.updateUser(1, "mrfeto@gmail.com", '', 'Alberto Vera', '10152713865899218', '') -- Temporal


if isUser then
    storyboard.gotoScene("src.Home")
else
    storyboard.gotoScene("src.Login")
end



-- Listen for notifications.
Runtime:addEventListener( "notification", onNotification )