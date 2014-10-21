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
local searchLocation = true

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

local locationHandler = function( event )
	-- Check for error (user may have turned off Location Services)
	if event.errorCode then
        sprRed:setSequence("no-red")
		native.showAlert( "GPS Location Error", event.errorMessage, {"OK"} )
		Runtime:removeEventListener( "location", locationHandler )
	elseif searchLocation then
        searchLocation = false
        sprRed:setSequence("si-red")
        -- Current location data was received.
        myMap:setRegion( event.latitude, event.longitude, 0.01, 0.01, true )
        Runtime:removeEventListener( "location", locationHandler )
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
    background:setFillColor(0)
    screenMap:insert(background)
    
    -- Height status bar
    local h = display.topStatusBarContentHeight
    
    -- Creamos toolbar
    local titleBar = display.newRect( display.contentCenterX, h, display.contentWidth, 65 )
    titleBar.anchorY = 0;
    titleBar:setFillColor( 0 ) 
    screenMap:insert(titleBar)
    
    local lineBar = display.newRect( display.contentCenterX, 63 + h, display.contentWidth, 5 )
    lineBar:setFillColor( {
            type = 'gradient',
            color1 = { 0, .7, 0, 1 }, 
            color2 = { 0, .7, 0, .5 },
            direction = "bottom"
        } ) 
    screenMap:insert(lineBar)

    local btnReturn = display.newImage("img/btn/left.png", true) 
    btnReturn.x = 35
    btnReturn.y = 35 + h
    screenMap:insert(btnReturn)
    btnReturn:addEventListener( "tap", gotoMain )
    
    local title = display.newText( "Lugares cercanos a ti", 250, 35 + h, "Chivo", 22)
    title:setFillColor( .8, .8, .8 )
    screenMap:insert(title)
    
    -- red sprite
    local sheet = graphics.newImageSheet(Sprites.red.source, Sprites.red.frames)
    sprRed = display.newSprite(sheet, Sprites.red.sequences)
    sprRed.x = intW - 40
    sprRed.y = 30 + h 
    screenMap:insert(sprRed)
    
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
     -- Height status bar
    local h = display.topStatusBarContentHeight
    
    -- Cocinar el mapa
    myMap = native.newMapView( midW, (midH + ((65 + h) / 2)), intW, (intH - (65 + h)) )
    myMap:setCenter( 21.154425, -86.820303, 0.02, 0.02 )
    screenMap:insert(myMap)
    
    -- Mostrar iconos
    RestManager.getServices()
    
    -- Get Position
    sprRed:setSequence("search")
    sprRed:play()
    
    -- Activate location listener
    searchLocation = true
    Runtime:addEventListener( "location", locationHandler )
end

-- Remove Listener
function scene:exitScene( event )
    if myMap then
        myMap:removeSelf()
        myMap = nil
    end
    Runtime:removeEventListener( "location", locationHandler )
end

scene:addEventListener("createScene", scene )
scene:addEventListener("enterScene", scene )
scene:addEventListener("exitScene", scene )

return scene


