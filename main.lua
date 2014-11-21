---------------------------------------------------------------------------------
-- Birdz Videogame
-- Alberto Vera
-- GeekBucket Software Factory
---------------------------------------------------------------------------------

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
local idComer = 10
--DBManager.updateUser(1, "mrfeto@gmail.com", '', 'Alberto Vera', '10152713865899218', '') -- Temporal


if isUser then
    storyboard.gotoScene("src.Home", {params = { idComer = idComer }})
else
    storyboard.gotoScene("src.Login")
end



-- Listen for notifications.
local onNotification = function( event )
    print( event.name ) -- ==> "notification"
    if event.custom then
        print( event.custom.foo ) -- ==> "bar"
    end
end 
Runtime:addEventListener( "notification", onNotification )