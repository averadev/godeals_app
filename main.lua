---------------------------------------------------------------------------------
-- Birdz Videogame
-- Alberto Vera
-- GeekBucket Software Factory
---------------------------------------------------------------------------------

os.execute('cls')
-- display.setStatusBar( display.DarkStatusBar )
display.setStatusBar( display.DefaultStatusBar )
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

