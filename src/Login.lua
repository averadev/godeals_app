---------------------------------------------------------------------------------
-- Godeals App
-- Alberto Vera
-- GeekBucket Software Factory
---------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- REQUIRE & VARIABLES
---------------------------------------------------------------------------------
local json = require("json")
local widget = require( "widget" )
local facebook = require( "facebook" )
local Globals = require('src.resources.Globals')
local RestManager = require('src.resources.RestManager')
local Sprites = require('src.resources.Sprites')
local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

-- Variables
local intW = display.contentWidth
local intH = display.contentHeight
local midW = display.contentCenterX
local midH = display.contentCenterY
local currentShow = 0
local fbCommand = 0
local GET_USER_INFO = 1
local fbAppID = "750089858383563" 
local txtSignEmail, txtSignPass, txtCreateEmail, txtCreatePass, txtCreateRePass
local imgLogo, groupBtn, groupSign, groupCreate, loadingGrp, loadingL
local hBar = display.topStatusBarContentHeight

---------------------------------------------------------------------------------
-- LISTENERS
---------------------------------------------------------------------------------

function showCreate()
    transition.to( groupBtn, { x = -480, time = 400, transition = easing.outExpo } )
    transition.to( groupCreate, { x = 0, time = 400, transition = easing.outExpo } )
end

function showSignIn()
    transition.to( groupBtn, { x = -480, time = 400, transition = easing.outExpo } )
    transition.to( groupSign, { x = 0, time = 400, transition = easing.outExpo } )
end

function getReturnButtons()
    backTxtPositions()
    if groupSign.x == 0 then
        transition.to( groupBtn, { x = 0, time = 400, transition = easing.outExpo } )
        transition.to( groupSign, { x = 480, time = 400, transition = easing.outExpo } )
    else
        transition.to( groupBtn, { x = 0, time = 400, transition = easing.outExpo } )
        transition.to( groupCreate, { x = 480, time = 400, transition = easing.outExpo } )
    end
end

-- Ajusta el contenido al mostrarse el teclado 
function onTxtFocus(event)
    if ( "began" == event.phase ) then
        -- Interfaz Sign In
        if groupSign.x == 0 and groupSign.y == 0 then
            transition.to( imgLogo, { y = 60 + hBar, time = 400, transition = easing.outExpo } )
            transition.to( groupSign, { y = (-midH + 200) + hBar, time = 400, transition = easing.outExpo } )
        -- Interfaz Create
        elseif groupCreate.x == 0 and groupCreate.y == 0 then
            transition.to( imgLogo, { y = 60 + hBar, time = 400, transition = easing.outExpo } )
            transition.to( groupCreate, { y = (-midH + 225) + hBar, time = 400, transition = easing.outExpo } )
        end
    elseif ( "submitted" == event.phase ) then
        -- Hide Keyboard
        native.setKeyboardFocus(nil)
        if event.target.method == "create" then
            doCreate()
        else
            doSignIn()
        end
    end
end

function backTxtPositions()
    -- Hide Keyboard
    native.setKeyboardFocus(nil)
    -- Interfaz Sign In
    if groupSign.x == 0 and groupSign.y < 0 then
        transition.to( imgLogo, { y = midH / 2, time = 400, transition = easing.outExpo } )
        transition.to( groupSign, { y = 0, time = 400, transition = easing.outExpo } )
    -- Interfaz Create
    elseif groupCreate.x == 0 and groupCreate.y < 0 then
        transition.to( imgLogo, { y = midH / 2, time = 400, transition = easing.outExpo } )
        transition.to( groupCreate, { y = 0, time = 400, transition = easing.outExpo } )
    end
end



---------------------------------------------------------------------------------
-- FUNCTIONS
---------------------------------------------------------------------------------
function gotoHome()
    storyboard.gotoScene( "src.Home", { time = 400, effect = "crossFade" })
end

local function printTable( t, label, level )
	if label then print( label ) end
	level = level or 1

	if t then
		for k,v in pairs( t ) do
			local prefix = ""
			for i=1,level do
				prefix = prefix .. "\t"
			end

			print( prefix .. "[" .. tostring(k) .. "] = " .. tostring(v) )
			if type( v ) == "table" then
				print( prefix .. "{" )
				printTable( v, nil, level + 1 )
				print( prefix .. "}" )
			end
		end
	end
end

function showLoadLogin()
    -- Show Login
    loadingL:setSequence("play")
    loadingL:play()
    loadingGrp.alpha = 1
end

function hideLoadLogin()
    loadingL:setSequence("stop")
    loadingGrp.alpha = 0
end

function networkConnectionL()
    local netConn = require('socket').connect('www.google.com', 80)
    if netConn == nil then
        native.showAlert( "Go Deals", "No se detecto conexión a internet.", { "OK"})
        return false
    end
    netConn:close()
    return true
end

function doCreate()
    if txtCreateEmail.text == '' or txtCreatePass.text == '' or txtCreateRePass.text == '' then
        native.showAlert( "Go Deals", "El email y password son necesarios.", { "OK"})
    elseif not (txtCreatePass.text == txtCreateRePass.text) then
        native.showAlert( "Go Deals", "Los paswords no coinciden.", { "OK"})
    elseif networkConnectionL() then
        showLoadLogin()
        backTxtPositions()
        RestManager.createUser(txtCreateEmail.text, txtCreatePass.text, '', '')
    end 
end

function doSignIn()
    if txtSignEmail.text == '' or txtSignPass.text == '' then
        native.showAlert( "Go Deals", "El email y password son necesarios.", { "OK"})
    elseif networkConnectionL() then
        showLoadLogin()
        backTxtPositions()
        RestManager.validateUser(txtSignEmail.text, txtSignPass.text)
    end 
end

function facebookListener( event )
    if ( "session" == event.type ) then
        if ( "login" == event.phase ) then
            local params = { fields = "email,name,id" }
            facebook.request( "me", "GET", params )
        end
    elseif ( "request" == event.type ) then
        if ( not event.isError ) then
            local response = json.decode( event.response )
            -- printTable( response, "User Info", 3 )
            if not (response.email == nil) then
                RestManager.createUser(response.email, '', response.name, response.id)
            end
        end
    end
end
function loginFaceBook()
    if networkConnectionL() then
        fbCommand = 1
        facebook.login( fbAppID, facebookListener, {"public_profile", "email"} )
    end
end

---------------------------------------------------------------------------------
-- OVERRIDING SCENES METHODS
---------------------------------------------------------------------------------
-- Called when the scene's view does not exist:
function scene:createScene( event )
    -- Agregamos el home
	screen = self.view
    
    -- Background
    local background = display.newImage("img/bgk/login.jpg", true) 
	background.x = midW
	background.y = midH
    screen:insert(background)
    
    imgLogo = display.newImage("img/btn/logoGo.png", true) 
	imgLogo.x = midW
	imgLogo.y = midH / 2
	screen:insert(imgLogo)  
    
    -- Groups
    groupBtn = display.newGroup()
	screen:insert(groupBtn)
    groupSign = display.newGroup()
	screen:insert(groupSign)
    groupCreate = display.newGroup()
	screen:insert(groupCreate)

    -- Bg TextFields
    local bgSignEmail = display.newImage("img/btn/bgTxtEmail.png", true) 
    bgSignEmail.x = midW
    bgSignEmail.y = midH - 45
    groupSign:insert(bgSignEmail)
    local bgSignPass = display.newImage("img/btn/bgTxtPass.png", true) 
    bgSignPass.x = midW
    bgSignPass.y = midH + 45
    groupSign:insert(bgSignPass)
    
    -- TextFields Sign In
    txtSignEmail = native.newTextField( midW + 35, midH - 45, 270, 60 )
    txtSignEmail.method = "signin"
    txtSignEmail.inputType = "email"
    txtSignEmail.hasBackground = false
    txtSignEmail:addEventListener( "userInput", onTxtFocus )
	groupSign:insert(txtSignEmail)
    txtSignPass = native.newTextField( midW + 35, midH + 45, 270, 60 )
    txtSignPass.method = "signin"
    txtSignPass.isSecure = true
    txtSignPass.hasBackground = false
    txtSignPass:addEventListener( "userInput", onTxtFocus )
	groupSign:insert(txtSignPass)
    
    local btnReturn1 = display.newImage("img/btn/btnLoginRegresar.png", true) 
	btnReturn1.x = midW - 122
	btnReturn1.y = midH + 130
    btnReturn1.height = 58
    btnReturn1.width = 215
	groupSign:insert(btnReturn1)
    btnReturn1:addEventListener( "tap", getReturnButtons )
    
    local btnDoSignIn = display.newImage("img/btn/btnLoginSignIn.png", true) 
	btnDoSignIn.x = midW + 122
	btnDoSignIn.y = midH + 130
    btnDoSignIn.height = 58
    btnDoSignIn.width = 215
	groupSign:insert(btnDoSignIn)
    btnDoSignIn:addEventListener( "tap", doSignIn )
    
    groupSign.x = 480
        
    -- Bg TextFields
    local bgCreateEmail = display.newImage("img/btn/bgTxtEmail.png", true) 
    bgCreateEmail.x = midW
    bgCreateEmail.y = midH - 75
    groupCreate:insert(bgCreateEmail)
    local bgCreatePass = display.newImage("img/btn/bgTxtPass.png", true) 
    bgCreatePass.x = midW
    bgCreatePass.y = midH + 05
    groupCreate:insert(bgCreatePass)
    local bgCreateRePass = display.newImage("img/btn/bgTxtPass.png", true) 
    bgCreateRePass.x = midW
    bgCreateRePass.y = midH + 85
    groupCreate:insert(bgCreateRePass)
    
    -- TextFields Create
    txtCreateEmail = native.newTextField( midW + 35, midH - 75, 270, 60 )
    txtCreateEmail.method = "create"
    txtCreateEmail.inputType = "email"
    txtCreateEmail.hasBackground = false
	groupCreate:insert(txtCreateEmail)
    txtCreateEmail:addEventListener( "userInput", onTxtFocus )
    txtCreatePass = native.newTextField( midW + 35, midH + 05, 270, 60 )
    txtCreatePass.method = "create"
    txtCreatePass.isSecure = true
    txtCreatePass.hasBackground = false
	groupCreate:insert(txtCreatePass)
    txtCreatePass:addEventListener( "userInput", onTxtFocus )
    txtCreateRePass = native.newTextField( midW + 35, midH + 85, 270, 60 )
    txtCreateRePass.method = "create"
    txtCreateRePass.isSecure = true
    txtCreateRePass.hasBackground = false
	groupCreate:insert(txtCreateRePass)
    txtCreateRePass:addEventListener( "userInput", onTxtFocus )
    
    local btnReturn2 = display.newImage("img/btn/btnLoginRegresar.png", true) 
	btnReturn2.x = midW - 122
	btnReturn2.y = midH + 170
    btnReturn2.height = 58
    btnReturn2.width = 215
	groupCreate:insert(btnReturn2)
    btnReturn2:addEventListener( "tap", getReturnButtons )
    
    local btnDoCreate = display.newImage("img/btn/btnLoginSignIn.png", true) 
	btnDoCreate.x = midW + 122
	btnDoCreate.y = midH + 170
    btnDoCreate.height = 58
    btnDoCreate.width = 215
	groupCreate:insert(btnDoCreate)
    btnDoCreate:addEventListener( "tap", doCreate )
    
    groupCreate.x = 480
        
    -- Buttons
    local btnFB = display.newImage("img/btn/btnLoginFaceBook.png", true) 
	btnFB.x = midW
	btnFB.y = midH - 50
    btnFB.height = 62
    btnFB.width = 468
	groupBtn:insert(btnFB)
    btnFB:addEventListener( "tap", loginFaceBook )
    
    local btnCreate = display.newImage("img/btn/btnLoginCreate.png", true) 
	btnCreate.x = midW - 122
	btnCreate.y = midH + 50
    btnCreate.height = 58
    btnCreate.width = 215
	groupBtn:insert(btnCreate)
    btnCreate:addEventListener( "tap", showCreate )
    
    local btnSignIn = display.newImage("img/btn/btnLoginSignIn.png", true) 
	btnSignIn.x = midW + 122
	btnSignIn.y = midH + 50
    btnSignIn.height = 58
    btnSignIn.width = 215
	groupBtn:insert(btnSignIn)
    btnSignIn:addEventListener( "tap", showSignIn )
    
    -- Lines
    local line = {}
    line[1] = display.newLine(15, midH +1, intW - 15, midH +1)
	groupBtn:insert(line[1])
    line[2] = display.newLine(midW+1, midH + 70, midW+1, midH + 20)
	groupBtn:insert(line[2])
    
    -- Loading
    loadingGrp = display.newGroup()
    screen:insert(loadingGrp)
    local mask = display.newRect( display.contentCenterX, display.contentCenterY, intW, intH )
    mask:setFillColor( 0)
    mask.alpha = .5
    loadingGrp:insert(mask)
    local sheet = graphics.newImageSheet(Sprites.loading.source, Sprites.loading.frames)
    loadingL = display.newSprite(sheet, Sprites.loading.sequences)
    loadingL.x = midW
    loadingL.y = midH 
    loadingGrp:insert(loadingL)
    hideLoadLogin()
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    facebook.logout()
    storyboard.removeAll()
end

-- Remove Listener
function scene:exitScene( event )
    if txtSignEmail then
        txtSignEmail:removeSelf()
        txtSignEmail = nil
    end
    if txtSignPass then
        txtSignPass:removeSelf()
        txtSignPass = nil
    end
    if txtCreateEmail then
        txtCreateEmail:removeSelf()
        txtCreateEmail = nil
    end
    if txtCreatePass then
        txtCreatePass:removeSelf()
        txtCreatePass = nil
    end
    if txtCreateRePass then
        txtCreateRePass:removeSelf()
        txtCreateRePass = nil
    end
end

scene:addEventListener("createScene", scene )
scene:addEventListener("enterScene", scene )
scene:addEventListener("exitScene", scene )

function scene:exitScene( event )
    Runtime:removeEventListener( "key", onKeyEvent )
end

-- Return button Android Devices
local function onKeyEvent( event )
    local phase = event.phase
    local keyName = event.keyName
    if ( "back" == keyName and phase == "up" ) then
        if groupBtn.x < 0 then
            getReturnButtons()
            return true
        end
    end
end
Runtime:addEventListener( "key", onKeyEvent )
    
return scene


