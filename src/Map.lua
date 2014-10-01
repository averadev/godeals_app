---------------------------------------------------------------------------------
-- Godeals App
-- Alberto Vera
-- GeekBucket Software Factory
---------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- REQUIRE & VARIABLES
---------------------------------------------------------------------------------
local widget = require( "widget" )
local storyboard = require( "storyboard" )
local Globals = require('src.resources.Globals')
local Sprites = require('src.resources.Sprites')
local RestManager = require('src.resources.RestManager')
local scene = storyboard.newScene()

-- Variables
local intW = display.contentWidth
local intH = display.contentHeight
local midW = display.contentCenterX
local midH = display.contentCenterY
local screenMap, group, sprRed, myMap

---------------------------------------------------------------------------------
-- LISTENERS
---------------------------------------------------------------------------------
function gotoMain(event)
    storyboard.gotoScene( "src.Home", {
        time = 400,
        effect = "crossFade"
    })
end


---------------------------------------------------------------------------------
-- FUNCTIONS
---------------------------------------------------------------------------------

-- Mostrar los iconos
function loadMapIcons(items)
    -- Set elements
    for z = 1, #items, 1 do 
        -- Options
        local options = { 
            title = items[z].category, 
            subtitle = items[z].name, 
            listener = markerListener, 
            imageFile = "img/btn/pinMap".. items[z].categoryId ..".png"
        }
        -- Add Maker
        myMap:addMarker( tonumber(items[z].latitude), tonumber(items[z].longitude), options )
    end
end

-- Get Position by GPS or Wifi
function getPosition(checks)
    local currentLocation = myMap:getUserLocation()
    if currentLocation.errorCode then
        if checks < 15 then
            checks = checks + 1
            timer.performWithDelay( 5000, function()
                getPosition(checks)
            end, 1 )
        else
            sprRed:setSequence("no-red")
        end
    else
        sprRed:setSequence("si-red")
        -- Current location data was received.
        currentLatitude = currentLocation.latitude
        currentLongitude = currentLocation.longitude
        myMap:setRegion( currentLatitude, currentLongitude, 0.01, 0.01, true )
    end
end
---------------------------------------------------------------------------------
-- OVERRIDING SCENES METHODS
---------------------------------------------------------------------------------
-- Called when the scene's view does not exist:
function scene:createScene( event )
    -- Agregamos el home
	screenMap = self.view
    
    -- Background
    local background = display.newRect(midW, midH, intW , intH)
    background:setFillColor(0.8, 0.8, 0.8)
    screenMap:insert(background)
    
    -- Creamos toolbar
    local titleBar = display.newRect( display.contentCenterX, 0, display.contentWidth, 105 )
    titleBar:setFillColor( titleGradient ) 
    titleBar.y = display.screenOriginY + titleBar.contentHeight * 0.5
    screenMap:insert(titleBar)

    local btnReturn = display.newImage("img/btn/left.png", true) 
    btnReturn.x = 35
    btnReturn.y = 70
    screenMap:insert(btnReturn)
    btnReturn:addEventListener( "tap", gotoMain )
    
    local title = display.newText( "Lugares cercanos a ti", 250, 72, "Chivo", 22)
    title:setFillColor( .8, .8, .8 )
    screenMap:insert(title)
    
    -- red sprite
    local sheet = graphics.newImageSheet(Sprites.red.source, Sprites.red.frames)
    sprRed = display.newSprite(sheet, Sprites.red.sequences)
    sprRed.x = intW - 40
    sprRed.y = 72 
    screenMap:insert(sprRed)
    
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    -- Cocinar el mapa
    myMap = native.newMapView( midW, (midH + 53), intW, (intH - 104) )
    myMap:setCenter( 21.154425, -86.820303, 0.02, 0.02 )
    screenMap:insert(myMap)
    
    -- Mostrar iconos
    RestManager.getServices()
    
    -- Get Position
    sprRed:setSequence("search")
    sprRed:play()
    getPosition(1)
end

-- Remove Listener
function scene:exitScene( event )
    if myMap then
        myMap:removeSelf()
        myMap = nil
    end
end

scene:addEventListener("createScene", scene )
scene:addEventListener("enterScene", scene )
scene:addEventListener("exitScene", scene )

return scene


