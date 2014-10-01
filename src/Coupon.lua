---------------------------------------------------------------------------------
-- Godeals App
-- Alberto Vera
-- GeekBucket Software Factory
---------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- REQUIRE & VARIABLES
---------------------------------------------------------------------------------
local widget = require( "widget" )
local Globals = require('src.resources.Globals')
local storyboard = require( "storyboard" )
local DBManager = require('src.resources.DBManager')
local scene = storyboard.newScene()

-- Variables
local intW = display.contentWidth
local intH = display.contentHeight
local midW = display.contentCenterX
local midH = display.contentCenterY
local page = {}
local scroll = {}
local currentX = midW
local currentI = 0
local leftX, rightX
local screen, group, initX, initCompX


---------------------------------------------------------------------------------
-- LISTENERS
---------------------------------------------------------------------------------
function gotoMain(event)
    storyboard.gotoScene( "src.Home", {
        time = 400,
        effect = "crossFade"
    })
end

function touchListener (event) 
    local phase = event.phase
    local target = event.target
    
    if ( phase == "began" ) then
        initX =  event.x
        initCompX = target.x
        target.isFocus =  true
    elseif( target.isFocus ) then
        if ( phase == "moved" ) then
            -- Calcular distancia
            distance = event.x - initX
            -- Asignar distancia
            target.x = initCompX + distance

        elseif ( phase == "ended" or phase == "cancelled" ) then
            -- Calcular distancia
            distance = event.x - initX
            -- Cancelamos el movimiento
            if (distance > -200 and distance < 200) -- si es Minimo
                or (distance > 0 and currentI == 1) -- Si es el primero
                or (distance < 0 and currentI == #Globals.Items) then -- Si es el ultimo
                --.x = initCompX
                transition.to( target, {time=200, x=initCompX, transition=easing.outExpo } )
            else
                if distance > 0 then
                    transition.to( target, {time=200, x=initCompX + intW, transition=easing.outExpo } )
                    currentI = currentI - 1
                    currentX = currentX - intW
                    if currentI > 1 then
                        getPage(currentX - intW, currentI - 1)
                    end
                else
                    transition.to( target, {time=200, x=initCompX - intW, transition=easing.outExpo } )
                    currentI = currentI + 1
                    currentX = currentX + intW
                    if not (currentI == #Globals.Items) then
                        getPage(currentX + intW, currentI + 1)
                    end
                end
            end
            target.isFocus =  false
        end
    end

    return true

end

local function movePage(toRight)
    -- Traer siguiente
    if toRight then
        -- Mover
        transition.to( page[currentI], {time = 200, x = currentX - intW } )
        transition.to( page[currentI + 1], {time = 200, x = currentX } )
        
        -- Delay and do
        timer.performWithDelay( 350, function()
            -- Index
            currentI = currentI + 1
            -- New page
            if currentI < #Globals.Items then
                getPage(rightX, currentI + 1)
            end 
            -- Scroll to Top
            scroll[currentI - 1]:scrollTo( "top" )
        end, 1 )
        
    -- Traer anterior
    else
        -- Mover
        transition.to( page[currentI], {time = 200, x = currentX + intW } )
        transition.to( page[currentI - 1], {time = 200, x = currentX } )
        
        -- Delay and do
        timer.performWithDelay( 350, function()
            -- Index
            currentI = currentI - 1
            -- New page
            if currentI > 1 then
                getPage(leftX, currentI - 1)
            end       
            -- Scroll to Top
            scroll[currentI + 1]:scrollTo( "top" )
        end, 1 )
    end
end

local function scrollListener( event )
	local phase = event.phase
	local direction = event.direction
    
    if "began" == phase then
		print( "Began: " )
	elseif "moved" == phase and not (direction == nil) then
        if direction == "right" or direction == "left" then
            print(event.target:getContentPosition() .. '-' .. currentI )
            if (event.target:getContentPosition() <= 0 and currentI < #Globals.Items) then
                page[currentI + 1].x = rightX + event.target:getContentPosition() 
            elseif (event.target:getContentPosition() >= 0 and currentI > 1) then
                page[currentI - 1].x = leftX + event.target:getContentPosition() 
            end
        end
	elseif "ended" == phase then
		if currentI < #Globals.Items then
            if page[currentI + 1].x < rightX then
                if (rightX - page[currentI + 1].x)  > 120 then 
                    movePage(true)
                else
                    transition.to( page[currentI + 1], {time = 200, x = rightX } )
                end
            end
        end
        if currentI > 1 then
            if page[currentI - 1].x > leftX then
                if (page[currentI - 1].x - leftX)  > 120 then 
                    movePage(false)
                else
                    transition.to( page[currentI - 1], {time = 200, x = leftX } )
                end
            end
        end
	end
			
	return true
end

---------------------------------------------------------------------------------
-- FUNCTIONS
---------------------------------------------------------------------------------*
function getPage(setX, i)
    if page[i] == nil then
        -- Generamos pagina
        page[i] = display.newContainer( intW, intH - 105 )
        page[i].x = setX
        page[i].y = midH + 53
        group:insert( page[i] )
        
        scroll[i] = widget.newScrollView {
            left = -midW,
            top = -midH + 52,
            width = intW+2,
            height = intH - 105,
            id = "onBottom",
            horizontalScrollDisabled = false,
            verticalScrollDisabled = false,
            listener = scrollListener,
            backgroundColor = { 1 }
        }
        page[i]:insert( scroll[i] )
            
        if Globals.Items[i].type == 2 then
            buildEvent(Globals.Items[i], i)
        elseif Globals.Items[i].type == 3 or Globals.Items[i].type == 4 then
            buildCoupon(Globals.Items[i], i)
        elseif Globals.Items[i].type == 5 then
            buildAdondeir(Globals.Items[i], i)
        elseif Globals.Items[i].type == 6 then
            buildSportTv(Globals.Items[i], i)
        end
    end
end 

function buildSportTv(item, i)
    -- Settings
    local settings = DBManager.getSettings()
    
    -- Title Detail
    local titleShape = display.newRect( midW, 50, 440, 60 )
    titleShape:setFillColor( 0 )
    scroll[i]:insert( titleShape )
    local titleInShape = display.newRect( midW, 50, 430, 50 )
    titleInShape:setFillColor( .4, .81, 0 )
    scroll[i]:insert( titleInShape )
    local title = display.newText( item.title, midW, 50, "Chivo", 24)
    title:setFillColor( 0 )
    scroll[i]:insert( title )
    
    -- Agregamos imagen
    local mask = graphics.newMask( "img/bgk/maskEvent.png" )
    local imgShape = display.newRect( midW, 205, 444, 214 )
    imgShape:setFillColor( .4 )
    scroll[i]:insert( imgShape )
    local img = display.newImage(item.image, system.TemporaryDirectory)
    img.x, img.y = midW, 265
    img.width, img.height  = 440, 330
    img:setMask( mask )
    scroll[i]:insert( img )
    
    -- Place Detail
    local dImg1 = display.newImage("img/btn/detailCity.png")
    dImg1.x, dImg1.y = 60, 350
    scroll[i]:insert( dImg1 )
    local dTxt1 = display.newText( item.subtitle1, 280, 355, 350, 24,  "Chivo", 20)
    dTxt1:setFillColor( 0 )
    scroll[i]:insert( dTxt1 )
    
    -- Vigency Detail
    local dImg3 = display.newImage("img/btn/detailVigencia.png")
    dImg3.x, dImg3.y = 60, 400
    scroll[i]:insert( dImg3 )
    local dImg3 = display.newText( item.subtitle2, 280, 405, 340, 24,  "Chivo", 20)
    dImg3:setFillColor( 0 )
    scroll[i]:insert( dImg3 )
    
    local lastY = 420
    if #item.bars > 0 then
        
        -- Separador
        lastY = 270
        local sp1 = display.newRect( midW, 445, 340, 2 )
        sp1:setFillColor( .8 )
        scroll[i]:insert( sp1 )
        
        for z = 1, #item.bars, 1 do 
            lastY =  lastY + 370
            -- Agregamos imagen
            local imgShape = display.newRect( midW, lastY, 444, 334 )
            imgShape:setFillColor( .4 )
            scroll[i]:insert( imgShape )
            
            
            local path = system.pathForFile( item.bars[z].image, system.TemporaryDirectory )
            local fhd = io.open( path )
            -- Determine if file exists
            if fhd then
                fhd:close()
                local image = display.newImage( item.bars[z].image, system.TemporaryDirectory )
                image.x = midW
                image.y = lastY
                image.width = 440
                image.height  = 330
                scroll[i]:insert( image )
            else
                -- Get from cloud
                local tmpY = lastY
                display.loadRemoteImage( settings.url .. 'assets/img/app/sporttv/min/' .. item.bars[z].image, 
                    "GET", 
                    function ( event )
                        if ( event.isError ) then
                        else
                            local image = event.target
                            image.x = midW
                            image.y = tmpY
                            image.width = 440
                            image.height  = 330
                            scroll[i]:insert( image )
                        end
                end, item.bars[z].image, system.TemporaryDirectory )
            end
            
        end
    end
    
    
end

function buildAdondeir(item, i)
    
    -- Title Detail
    local titleShape = display.newRect( midW, 50, 440, 60 )
    titleShape:setFillColor( 0 )
    scroll[i]:insert( titleShape )
    local titleInShape = display.newRect( midW, 50, 430, 50 )
    titleInShape:setFillColor( .4, .81, 0 )
    scroll[i]:insert( titleInShape )
    local title = display.newText( item.title, midW, 50, "Chivo", 24)
    title:setFillColor( 0 )
    scroll[i]:insert( title )
    
    -- Agregamos imagen
    local imgShape = display.newRect( midW, 260, 444, 334 )
    imgShape:setFillColor( .4 )
    scroll[i]:insert( imgShape )
    local img = display.newImage(item.image, system.TemporaryDirectory)
    img.x, img.y = midW, 260
    img.width, img.height  = 440, 330
    scroll[i]:insert( img )
    
    -- Add button
    local addShape = display.newRect( midW, 470, 440, 60 )
    addShape:setFillColor( 0 )
    scroll[i]:insert( addShape )
    local addInShape = display.newRect( midW, 470, 430, 50 )
    addInShape:setFillColor( 1 )
    scroll[i]:insert( addInShape )
    local addIcon = display.newImage("img/btn/favOut.png")
    addIcon.x, addIcon.y = 60, 470
    scroll[i]:insert( addIcon )
    local addTxt = display.newText( "Agregar a favoritos", midW, 470, "Chivo", 24)
    addTxt:setFillColor( 0 )
    scroll[i]:insert( addTxt )
    
    -- Separador
    local sp1 = display.newRect( midW, 520, 340, 2 )
    sp1:setFillColor( .8 )
    scroll[i]:insert( sp1 )
    
    -- Detalle
    local infoTitle = display.newText( item.subtitle1, midW, 550, "Chivo", 24)
    infoTitle:setFillColor( 0 )
    scroll[i]:insert( infoTitle )
    local infoTxt = display.newText( item.txtMax, 240, 690, 430, 0,  "Chivo", 20)
    infoTxt:setFillColor( 0 )
    scroll[i]:insert( infoTxt )
    local lastY = 520 + (infoTxt.contentHeight / 2) + 50
    infoTxt.y = lastY
    
    lastY = lastY + (infoTxt.contentHeight / 2) + 15
    
    boolBg = false
    if #item.hotels > 0 then
        boolBg = not boolBg
        lastY = addItemsPlace(item.hotels, "¿Dónde hospedarse?", 1, i, lastY, boolBg)
    end
    if #item.restaurants > 0 then
        boolBg = not boolBg
        lastY = addItemsPlace(item.restaurants, "¿Dónde comer?", 2, i, lastY, boolBg)
    end
    if #item.bars > 0 then
        boolBg = not boolBg
        lastY = addItemsPlace(item.bars, "¿Dónde divertirse?", 3, i, lastY, boolBg)
    end
    
    -- Show Map
    local mapShape = display.newRect( midW, lastY + 55, 440, 60 )
    mapShape:setFillColor( 0 )
    scroll[i]:insert( mapShape )
    local mapInShape = display.newRect( midW, lastY + 55, 430, 50 )
    mapInShape:setFillColor( 1 )
    scroll[i]:insert( mapInShape )
    local mapIcon = display.newImage("img/btn/detailMapOut.png")
    mapIcon.x, mapIcon.y = 60, lastY + 55
    scroll[i]:insert( mapIcon )
    local mapTxt = display.newText( "Mostrar Ubicación", midW, lastY + 55, "Chivo", 24)
    mapTxt:setFillColor( 0 )
    scroll[i]:insert( mapTxt )
    
    -- Ended
    local sp3 = display.newRect( 0, lastY + 130, 0, 1 )
    sp3:setFillColor( 1 )
    scroll[i]:insert( sp3 )
    
end

function addItemsPlace(items, textTitle, typeC, i, lastY, boolBg)
    local intY = lastY
    
     -- Hoteles
    lastY = lastY + 30
    local secTitle1 = display.newText( textTitle, midW, lastY, "Chivo", 24)
    secTitle1:setFillColor( 0 )
    scroll[i]:insert( secTitle1 )

    lastY = lastY + 80
    for z = 1, #items, 1 do 
        
        local itemIcon = display.newImage("img/btn/iconPlace".. typeC ..".png")
        itemIcon.x, itemIcon.y = 60, lastY - 10
        scroll[i]:insert( itemIcon )
        
        local itemName = display.newText( items[z].nombre, 280, lastY - 30, 350, 24, "Chivo", 20)
        itemName:setFillColor( 0 )
        scroll[i]:insert( itemName )

        local itemAddress = display.newText( items[z].address, 280, lastY - 5, 350, 22, "Chivo", 16)
        itemAddress:setFillColor( 0 )
        scroll[i]:insert( itemAddress )

        local itemPhone = display.newText( items[z].phone, 280, lastY + 15, 350, 22, "Chivo", 16)
        itemPhone:setFillColor( 0 )
        scroll[i]:insert( itemPhone )

        local itemInfo = display.newText( items[z].info, 240, lastY + 35, 430, 0, "Chivo", 16)
        itemInfo:setFillColor( 0 )
        scroll[i]:insert( itemInfo )

        lastY = lastY + (itemInfo.contentHeight / 2) + 30
        itemInfo.y = lastY

        if z < #items then
            lastY = lastY +  (itemInfo.contentHeight / 2) + 70
        else
            lastY = lastY +  (itemInfo.contentHeight / 2) + 30
        end
    end
    
     -- Background
    if boolBg then
        local middle = (lastY - intY) / 2
        local sp2 = display.newRect( midW, intY + middle, intW, middle * 2 )
        sp2:setFillColor( .9 )
        scroll[i]:insert( sp2 )
        sp2:toBack()
    end
    
    return lastY
    
end

function buildEvent(item, i)
    
    -- Title Detail
    local titleShape = display.newRect( midW, 50, 440, 60 )
    titleShape:setFillColor( 0 )
    scroll[i]:insert( titleShape )
    local titleInShape = display.newRect( midW, 50, 430, 50 )
    titleInShape:setFillColor( .4, .81, 0 )
    scroll[i]:insert( titleInShape )
    local title = display.newText( item.title, midW, 50, "Chivo", 24)
    title:setFillColor( 0 )
    scroll[i]:insert( title )
    
    -- Agregamos imagen
    local mask = graphics.newMask( "img/bgk/maskEvent.png" )
    local imgShape = display.newRect( midW, 205, 444, 214 )
    imgShape:setFillColor( .4 )
    scroll[i]:insert( imgShape )
    local img = display.newImage(item.image, system.TemporaryDirectory)
    img.x, img.y = midW, 265
    img.width, img.height  = 440, 330
    img:setMask( mask )
    scroll[i]:insert( img )
    
    -- Place Detail
    local dImg1 = display.newImage("img/btn/detailCity.png")
    dImg1.x, dImg1.y = 60, 350
    scroll[i]:insert( dImg1 )
    local dTxt1 = display.newText( item.subtitle1, 280, 340, 350, 24,  "Chivo", 20)
    dTxt1:setFillColor( 0 )
    scroll[i]:insert( dTxt1 )
    local dTxtSub1 = display.newText( item.subtitle2, 280, 365, 350, 24,  "Chivo", 16)
    dTxtSub1:setFillColor( 0 )
    scroll[i]:insert( dTxtSub1 )
    
    -- Vigency Detail
    local dImg3 = display.newImage("img/btn/detailVigencia.png")
    dImg3.x, dImg3.y = 60, 400
    scroll[i]:insert( dImg3 )
    local dImg3 = display.newText( item.dateMax, 280, 405, 340, 24,  "Chivo", 20)
    dImg3:setFillColor( 0 )
    scroll[i]:insert( dImg3 )
    
    -- Add button
    local addShape = display.newRect( midW, 470, 440, 60 )
    addShape:setFillColor( 0 )
    scroll[i]:insert( addShape )
    local addInShape = display.newRect( midW, 470, 430, 50 )
    addInShape:setFillColor( 1 )
    scroll[i]:insert( addInShape )
    local addIcon = display.newImage("img/btn/favOut.png")
    addIcon.x, addIcon.y = 60, 470
    scroll[i]:insert( addIcon )
    local addTxt = display.newText( "Agregar a favoritos", midW, 470, "Chivo", 24)
    addTxt:setFillColor( 0 )
    scroll[i]:insert( addTxt )
    
    -- Separador
    local sp1 = display.newRect( midW, 520, 340, 2 )
    sp1:setFillColor( .8 )
    scroll[i]:insert( sp1 )
    
    -- Detalle
    local infoTxt = display.newText( item.info, 240, 690, 430, 0,  "Chivo", 20)
    infoTxt:setFillColor( 0 )
    scroll[i]:insert( infoTxt )
    local lastY = 520 + (infoTxt.contentHeight / 2) + 20
    infoTxt.y = lastY
    
    -- Separador
    lastY = lastY + (infoTxt.contentHeight / 2) + 15
    local sp2 = display.newRect( midW, lastY, 340, 2 )
    sp2:setFillColor( .8 )
    scroll[i]:insert( sp2 )
    
    -- Show Map
    local mapShape = display.newRect( midW, lastY + 55, 440, 60 )
    mapShape:setFillColor( 0 )
    scroll[i]:insert( mapShape )
    local mapInShape = display.newRect( midW, lastY + 55, 430, 50 )
    mapInShape:setFillColor( 1 )
    scroll[i]:insert( mapInShape )
    local mapIcon = display.newImage("img/btn/detailMapOut.png")
    mapIcon.x, mapIcon.y = 60, lastY + 55
    scroll[i]:insert( mapIcon )
    local mapTxt = display.newText( "Mostrar Ubicación", midW, lastY + 55, "Chivo", 24)
    mapTxt:setFillColor( 0 )
    scroll[i]:insert( mapTxt )
    
    -- Ended
    local sp3 = display.newRect( 0, lastY + 130, 0, 1 )
    sp3:setFillColor( 1 )
    scroll[i]:insert( sp3 )
    
end

function buildCoupon(item, i)
    
    -- Title Detail
    local titleShape = display.newRect( midW, 50, 440, 60 )
    titleShape:setFillColor( 0 )
    scroll[i]:insert( titleShape )
    local titleInShape = display.newRect( midW, 50, 430, 50 )
    titleInShape:setFillColor( .4, .81, 0 )
    scroll[i]:insert( titleInShape )
    local title = display.newText( item.title, midW, 50, "Chivo", 24)
    title:setFillColor( 0 )
    scroll[i]:insert( title )
    
    -- Agregamos imagen
    local imgShape = display.newRect( midW, 260, 444, 334 )
    imgShape:setFillColor( .4 )
    scroll[i]:insert( imgShape )
    local img = display.newImage(item.image, system.TemporaryDirectory)
    img.x, img.y = midW, 260
    img.width, img.height  = 440, 330
    scroll[i]:insert( img )
    
    -- Place Detail
    local dImg1 = display.newImage("img/btn/detailPlace.png")
    dImg1.x, dImg1.y = 60, 460
    scroll[i]:insert( dImg1 )
    local dTxt1 = display.newText( item.subtitle1, 280, 465, 350, 24,  "Chivo", 20)
    dTxt1:setFillColor( 0 )
    scroll[i]:insert( dTxt1 )
    
    -- Vigency Detail
    local dImg3 = display.newImage("img/btn/detailVigencia.png")
    dImg3.x, dImg3.y = 60, 510
    scroll[i]:insert( dImg3 )
    local dImg3 = display.newText( item.validity, 280, 515, 350, 24,  "Chivo", 20)
    dImg3:setFillColor( 0 )
    scroll[i]:insert( dImg3 )
    
    -- Add button
    local addShape = display.newRect( midW, 580, 440, 60 )
    addShape:setFillColor( 0 )
    scroll[i]:insert( addShape )
    local addInShape = display.newRect( midW, 580, 430, 50 )
    addInShape:setFillColor( 1 )
    scroll[i]:insert( addInShape )
    local addIcon = display.newImage("img/btn/favOut.png")
    addIcon.x, addIcon.y = 60, 580
    scroll[i]:insert( addIcon )
    local addTxt = display.newText( "Agregar a favoritos", midW, 580, "Chivo", 24)
    addTxt:setFillColor( 0 )
    scroll[i]:insert( addTxt )
    
    -- Separador
    local sp1 = display.newRect( midW, 630, 340, 2 )
    sp1:setFillColor( .8 )
    scroll[i]:insert( sp1 )
    
    -- Terminos y condiciones
    local termTitle = display.newText( "Terminos y condiciones:", midW, 660, "Chivo", 24)
    termTitle:setFillColor( 0 )
    scroll[i]:insert( termTitle )
    local termTxt = display.newText( item.clauses, 240, 690, 430, 0,  "Chivo", 16)
    termTxt:setFillColor( 0 )
    scroll[i]:insert( termTxt )
    
    local lastY = 630 + (termTxt.contentHeight / 2) + 50
    termTxt.y = lastY
    
    -- Separador
    lastY = lastY + (termTxt.contentHeight / 2) + 15
    local sp2 = display.newRect( midW, lastY, 340, 2 )
    sp2:setFillColor( .8 )
    scroll[i]:insert( sp2 )
    
    -- Show Map
    local mapShape = display.newRect( midW, lastY + 55, 440, 60 )
    mapShape:setFillColor( 0 )
    scroll[i]:insert( mapShape )
    local mapInShape = display.newRect( midW, lastY + 55, 430, 50 )
    mapInShape:setFillColor( 1 )
    scroll[i]:insert( mapInShape )
    local mapIcon = display.newImage("img/btn/detailMapOut.png")
    mapIcon.x, mapIcon.y = 60, lastY + 55
    scroll[i]:insert( mapIcon )
    local mapTxt = display.newText( "Mostrar Ubicación", midW, lastY + 55, "Chivo", 24)
    mapTxt:setFillColor( 0 )
    scroll[i]:insert( mapTxt )
    
    -- Ended
    local sp3 = display.newRect( 0, lastY + 130, 0, 1 )
    sp3:setFillColor( 1 )
    scroll[i]:insert( sp3 )
    
end

---------------------------------------------------------------------------------
-- OVERRIDING SCENES METHODS
---------------------------------------------------------------------------------
-- Called when the scene's view does not exist:
function scene:createScene( event )
    -- Agregamos el home
	screen = self.view
    -- Parametros
	currentI = event.params.index
    
    -- Background
    local background = display.newRect(midW, midH, intW , intH)
    background:setFillColor(0.8, 0.8, 0.8)
    screen:insert(background)
    
    -- Creamos toolbar
    local titleBar = display.newRect( display.contentCenterX, 0, display.contentWidth, 105 )
    titleBar:setFillColor( titleGradient ) 
    titleBar.y = display.screenOriginY + titleBar.contentHeight * 0.5
    screen:insert(titleBar)

    local btnReturn = display.newImage("img/btn/left.png", true) 
    btnReturn.x = 35
    btnReturn.y = 70
    screen:insert(btnReturn)
    btnReturn:addEventListener( "tap", gotoMain )
    
    -- Generamos contenedor
    group = display.newGroup()
    screen:insert(group)
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    getPage(currentX, currentI) -- Current
    -- Left - Right
    leftX = currentX - intW
    rightX = currentX + intW
    if currentI > 1 then
        getPage(leftX, currentI-1) -- Left
    end
    if not (currentI == #Globals.Items) then
        getPage(rightX, currentI+1) -- Right
    end
    
end

-- Remove Listener
function scene:exitScene( event )
end

scene:addEventListener("createScene", scene )
scene:addEventListener("enterScene", scene )
scene:addEventListener("exitScene", scene )

return scene


