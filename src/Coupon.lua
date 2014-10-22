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
local Sprites = require('src.resources.Sprites')
local RestManager = require('src.resources.RestManager')
local scene = storyboard.newScene()

-- Variables
local intW = display.contentWidth
local intH = display.contentHeight
local midW = display.contentCenterX
local midH = display.contentCenterY
local page = {}
local scroll = {}
local btnMap = {}
local iconFav = {}
local mapG
local settings
local currentX = midW
local currentI = 0
local leftX, rightX
local screen, group, txtTitle, initX, initCompX, hC


---------------------------------------------------------------------------------
-- LISTENERS
---------------------------------------------------------------------------------
function gotoMain(event)
    if not (mapG == nil) then
        mapG:removeSelf()
        mapG = nil
    end
    storyboard.gotoScene( "src.Home", {
        time = 400,
        effect = "crossFade"
    })
end

function tapPageMap(event)
    local t = event.target
    if mapG == nil then
        t:setFillColor( 0 )
        local t = event.target
        mapG = display.newGroup()
        --page[t.index]:insert( mapG )
        local bgShape = display.newRect( midW, intH + 138, intW, 286 )
        bgShape:setFillColor( 0 )
        mapG:insert( bgShape )
        local imgMin = display.newImage("img/btn/btnMinMap.png")
        imgMin.index = t.index
        imgMin.x, imgMin.y = intW - 40, intH - 24
        imgMin:addEventListener( "tap", tapPageMap )
        mapG:insert( imgMin )
        
        transition.to( mapG, {time=600, y = mapG.y - 280, transition=easing.outExpo, 
            onComplete = function()
                -- Crear mapa
                local mapC = native.newMapView( midW, intH + 140, 480, 280 )
                mapC:setCenter( t.latitude, t.longitude, 0.01, 0.01 )
                mapG:insert(mapC)
                -- Add Maker
                mapC:addMarker( t.latitude, t.longitude)
            end
        })
    else
        btnMap[t.index]:setFillColor( .2 )
        transition.to( mapG, {time=600, y = mapG.y + 300, transition=easing.outExpo, 
            onComplete = function()
                -- Remove map
                mapG:removeSelf()
                mapG = nil
            end           
        })
    end
end

function tapPageFav(event)
    local t = event.target
    if not t.isMark then
        -- Do candy eye
        t.isMark = true
        t:setFillColor( 0, .5, 0 )
        -- Set fav to cloud
        Globals.Items[t.index].isFav = 1
        RestManager.setFav(t.idCupon, t.idType, 1)
    else
        -- Do candy eye
        t.isMark = false
        t:setFillColor( 0 )
        -- Remove fav to cloud
        Globals.Items[t.index].isFav = 0
        RestManager.setFav(t.idCupon, t.idType, 0)
    end
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
     -- Verificar mapa
    if not (mapG == nil) then
        transition.to( mapG, {time=200, y = mapG.y + 300, transition=easing.outExpo, onComplete = function()
            mapG:removeSelf()
            mapG = nil 
        end })
    end
    
    -- Traer siguiente
    if toRight then
        -- Mover
        transition.to( page[currentI], {time = 200, x = currentX - intW } )
        transition.to( page[currentI + 1], {time = 200, x = currentX } )
        
        -- Delay and do
        timer.performWithDelay( 350, function()
            -- Index
            currentI = currentI + 1
            -- Change title
            txtTitle.text = Globals.Items[currentI].title
            -- New page
            if currentI < #Globals.Items then
                getPage(rightX, currentI + 1)
            end 
            -- Scroll to Top
            -- scroll[currentI - 1]:scrollTo( "top" )
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
            -- Change title
            txtTitle.text = Globals.Items[currentI].title
            -- New page
            if currentI > 1 then
                getPage(leftX, currentI - 1)
            end       
            -- Scroll to Top
            --scroll[currentI + 1]:scrollTo( "top" )
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
        page[i] = display.newContainer( intW, intH - 65 + hC )
        page[i].x = setX
        page[i].y = midH + 33
        group:insert( page[i] )
        
        scroll[i] = widget.newScrollView {
            left = -midW,
            top = -midH + 32 + hC,
            width = intW+2,
            height = intH - 65 - hC,
            id = "onBottom",
            friction = .8,
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
    
    -- Agregamos imagen
    local imgShape = display.newRect( midW, 156, 444, 276 )
    imgShape:setFillColor( .4 )
    scroll[i]:insert( imgShape )
    local imgShape2 = display.newRect(  midW, 262, 444, 62  )
    imgShape2:setFillColor( 0, .7, 0 )
    scroll[i]:insert( imgShape2 )
    local mask = graphics.newMask( "img/bgk/maskEvent.png" )
    local img = display.newImage(item.image, system.TemporaryDirectory)
    img.x, img.y = midW, 185
    img.width, img.height  = 440, 330
    img:setMask( mask )
    scroll[i]:insert( img )
    -- Boton de Fav
    local shapeR = display.newRect( midW, 262, 440, 60 )
    shapeR.index = i
    shapeR.idCupon = item.idCupon
    shapeR.idType = item.type
    shapeR.isMark = false
    shapeR:setFillColor( 0 )
    shapeR:addEventListener( "tap", tapPageFav )
    scroll[i]:insert( shapeR )
    local sheet = graphics.newImageSheet(Sprites.fav.source, Sprites.fav.frames)
    iconFav[i] = display.newSprite(sheet, Sprites.fav.sequences)
    iconFav[i].x, iconFav[i].y = midW - 100, 262
    scroll[i]:insert( iconFav[i] )
    local favTxt = display.newText( "Agregar a Favoritos", midW + 20, 262, "Chivo", 20)
    favTxt:setFillColor( 1 )
    scroll[i]:insert( favTxt )
    
    -- Is fav
    if not(item.isFav == 0 or item.isFav == '0') then 
        shapeR.isMark = true
        shapeR:setFillColor( 0, .5, 0 )
    end
    
    -- Place Detail
    local dImg1 = display.newImage("img/btn/detailPlace.png")
    dImg1.x, dImg1.y = 60, 340
    scroll[i]:insert( dImg1 )
    local dTxt1 = display.newText( (item.subtitle1), 270, 340, 360, 24,  "Chivo", 18)
    dTxt1:setFillColor( 0 )
    scroll[i]:insert( dTxt1 )
    local dotted1 = display.newImage("img/btn/dottedLine.png")
    dotted1.x, dotted1.y = midW, 370
    scroll[i]:insert( dotted1 )
    -- Date Detail
    local dImg3 = display.newImage("img/btn/detailVigencia.png")
    dImg3.x, dImg3.y = 60, 410
    scroll[i]:insert( dImg3 )
    local dImg3 = display.newText( item.fecha, 270, 410, 360, 24,  "Chivo", 18)
    dImg3:setFillColor( 0 )
    scroll[i]:insert( dImg3 )
    -- Time Detail
    local dImg3 = display.newImage("img/btn/detailHora.png")
    dImg3.x, dImg3.y = 290, 410
    scroll[i]:insert( dImg3 )
    local dImg3 = display.newText( item.time, 400, 410, 150, 24,  "Chivo", 18)
    dImg3:setFillColor( 0 )
    scroll[i]:insert( dImg3 )
    -- Line Dotted
    local dotted2 = display.newImage("img/btn/dottedLine.png")
    dotted2.x, dotted2.y = midW, 450
    scroll[i]:insert( dotted2 )
    
    -- Ubicaciones de transmision
    local lastY = 280
    if #item.bars > 0 then
        
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
    
    lastY =  lastY + 200
    -- Publicidad
    local publiShape = display.newRect( midW, lastY + 65, 480, 130 )
    publiShape:setFillColor( .95 )
    scroll[i]:insert( publiShape )
    -- Determine if publicity exists
    local pathP = system.pathForFile( item.publicidad, system.TemporaryDirectory )
    local fhdP = io.open( pathP )
    if fhdP then
        fhdP:close()
        local publicidad = display.newImage(item.publicidad, system.TemporaryDirectory )
        publicidad.x, publicidad.y = midW, lastY + 55
        scroll[i]:insert( publicidad )
    else
        -- Get from cloud
        display.loadRemoteImage( settings.url .. 'assets/img/app/publicity/movil/' .. item.publicidad, "GET", 
            function ( event )
                if ( event.isError ) then
                else
                    event.target.x, event.target.y = midW, lastY + 55
                    scroll[i]:insert( event.target )
                end
        end, item.publicidad, system.TemporaryDirectory )
    end
end

function buildAdondeir(item, i)
    
    -- Agregamos imagen
    local imgShape = display.newRect( midW, 156, 444, 276 )
    imgShape:setFillColor( .4 )
    scroll[i]:insert( imgShape )
    local imgShape2 = display.newRect(  midW, 262, 444, 62  )
    imgShape2:setFillColor( 0, .7, 0 )
    scroll[i]:insert( imgShape2 )
    local mask = graphics.newMask( "img/bgk/maskEvent.png" )
    local img = display.newImage(item.image, system.TemporaryDirectory)
    img.x, img.y = midW, 185
    img.width, img.height  = 440, 330
    img:setMask( mask )
    scroll[i]:insert( img )
    -- Boton de Mapa
    btnMap[i] = display.newRect( midW - 110, 262, 220, 60 )
    btnMap[i].index = i
    btnMap[i]:setFillColor( 0 )
    btnMap[i].partnerName = item.partnerName
    btnMap[i].latitude = tonumber(item.latitude)
    btnMap[i].longitude = tonumber(item.longitude)
    btnMap[i]:addEventListener( "tap", tapPageMap )
    scroll[i]:insert( btnMap[i] )
    local mapIcon = display.newImage("img/btn/detailMap.png")
    mapIcon.x, mapIcon.y = 50, 262
    scroll[i]:insert( mapIcon )
    local mapTxt = display.newText( "Mostrar Mapa", midW - 100, 262, "Chivo", 20)
    mapTxt:setFillColor( 1 )
    scroll[i]:insert( mapTxt )
    -- Boton de Fav
    local shapeR = display.newRect( midW + 110, 262, 218, 60 )
    shapeR.index = i
    shapeR.idCupon = item.idCupon
    shapeR.idType = item.type
    shapeR.isMark = false
    shapeR:setFillColor( 0 )
    shapeR:addEventListener( "tap", tapPageFav )
    scroll[i]:insert( shapeR )
    local sheet = graphics.newImageSheet(Sprites.fav.source, Sprites.fav.frames)
    iconFav[i] = display.newSprite(sheet, Sprites.fav.sequences)
    iconFav[i].x, iconFav[i].y = midW + 32, 262
    scroll[i]:insert( iconFav[i] )
    local favTxt = display.newText( "Favoritos", midW + 110, 262, "Chivo", 20)
    favTxt:setFillColor( 1 )
    scroll[i]:insert( favTxt )
    
    -- Is fav
    if not(item.isFav == 0 or item.isFav == '0') then 
        shapeR.isMark = true
        shapeR:setFillColor( 0, .5, 0 )
    end
    
    local lastY = 330
    
    -- Descripcion
    local descTitle = display.newText( item.subtitle1, 190, lastY + 10, 330, 28, "Chivo", 20)
    descTitle:setFillColor( 0, .4, 0 )
    scroll[i]:insert( descTitle )
    local descTxt = display.newText( item.txtMax, 240, 690, 430, 0,  "Chivo", 16)
    descTxt:setFillColor( 0 )
    scroll[i]:insert( descTxt )
    -- Move Text
    lastY = lastY + (descTxt.contentHeight / 2) + 25
    descTxt.y = lastY
    lastY = lastY + (descTxt.contentHeight / 2) + 50
    
    
    boolBg = true
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
    
    lastY = lastY - 20
    
    -- Publicidad
    local publiShape = display.newRect( midW, lastY + 65, 480, 130 )
    publiShape:setFillColor( .95 )
    scroll[i]:insert( publiShape )
    -- Determine if publicity exists
    local pathP = system.pathForFile( item.publicidad, system.TemporaryDirectory )
    local fhdP = io.open( pathP )
    if fhdP then
        fhdP:close()
        local publicidad = display.newImage(item.publicidad, system.TemporaryDirectory )
        publicidad.x, publicidad.y = midW, lastY + 55
        scroll[i]:insert( publicidad )
    else
        -- Get from cloud
        display.loadRemoteImage( settings.url .. 'assets/img/app/publicity/movil/' .. item.publicidad, "GET", 
            function ( event )
                if ( event.isError ) then
                else
                    event.target.x, event.target.y = midW, lastY + 55
                    scroll[i]:insert( event.target )
                end
        end, item.publicidad, system.TemporaryDirectory )
    end
end

function addItemsPlace(items, textTitle, typeC, i, lastY, boolBg)
    local intY = lastY
    
     -- Hoteles
    --lastY = lastY + 30
    local shapeR = display.newRect( midW, lastY, 480, 40 )
    shapeR:setFillColor( 0 )
    scroll[i]:insert( shapeR )
    local secTitle1 = display.newText( textTitle, midW, lastY, "Chivo", 24)
    secTitle1:setFillColor( 1 )
    scroll[i]:insert( secTitle1 )

    lastY = lastY + 80
    for z = 1, #items, 1 do 
        
         -- Agregamos rectangulo alfa al pie
        local shapeAlpha
        if (z%2) == 0 then
            shapeAlpha = display.newRect( midW, lastY, 480, 100 )
            shapeAlpha:setFillColor( .95 )
            scroll[i]:insert( shapeAlpha )
        end
        
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
        
        if (z%2) == 0 then
            shapeAlpha.height = shapeAlpha.height + itemInfo.contentHeight + 10
            shapeAlpha.y = lastY + (itemInfo.contentHeight / 2) - 5
        end
                
        if z > 1 then
            local dotted = display.newImage("img/btn/dottedLine.png")
            dotted.x, dotted.y = midW, itemName.y - 30
            scroll[i]:insert( dotted )
        end

        lastY = lastY + (itemInfo.contentHeight / 2) + 30
        itemInfo.y = lastY
        if z < #items then
            lastY = lastY +  (itemInfo.contentHeight / 2) + 70
        else
            lastY = lastY +  (itemInfo.contentHeight / 2) + 40
        end
    end
    
    return lastY
    
end

function buildEvent(item, i)
    -- Group to move
    local groupEvt = display.newGroup()
    scroll[i]:insert( groupEvt )
    
    -- Agregamos imagen
    local imgShape = display.newRect( midW, 216, 444, 396 )
    imgShape:setFillColor( .4 )
    scroll[i]:insert( imgShape )
    local imgShape2 = display.newRect(  midW, 383, 444, 62  )
    imgShape2:setFillColor( 0, .7, 0 )
    groupEvt:insert( imgShape2 )
    local img = display.newImage(item.image, system.TemporaryDirectory)
    img.x, img.y = midW, 185
    img.width, img.height  = 440, 330
    groupEvt:insert( img )
    
    -- Boton de Mapa
    btnMap[i] = display.newRect( midW - 110, 383, 220, 60 )
    btnMap[i].index = i
    btnMap[i]:setFillColor( 0 )
    btnMap[i].partnerName = item.partnerName
    btnMap[i].latitude = tonumber(item.latitude)
    btnMap[i].longitude = tonumber(item.longitude)
    btnMap[i]:addEventListener( "tap", tapPageMap )
    groupEvt:insert( btnMap[i] )
    local mapIcon = display.newImage("img/btn/detailMap.png")
    mapIcon.x, mapIcon.y = 50, 382
    groupEvt:insert( mapIcon )
    local mapTxt = display.newText( "Mostrar Mapa", midW - 100, 382, "Chivo", 20)
    mapTxt:setFillColor( 1 )
    groupEvt:insert( mapTxt )
    -- Boton de Fav
    local shapeR = display.newRect( midW + 110, 383, 218, 60 )
    shapeR.index = i
    shapeR.idCupon = item.idCupon
    shapeR.idType = item.type
    shapeR.isMark = false
    shapeR:setFillColor( 0 )
    shapeR:addEventListener( "tap", tapPageFav )
    groupEvt:insert( shapeR )
    local sheet = graphics.newImageSheet(Sprites.fav.source, Sprites.fav.frames)
    iconFav[i] = display.newSprite(sheet, Sprites.fav.sequences)
    iconFav[i].x, iconFav[i].y = midW + 32, 382
    groupEvt:insert( iconFav[i] )
    local favTxt = display.newText( "Favoritos", midW + 110, 382, "Chivo", 20)
    favTxt:setFillColor( 1 )
    groupEvt:insert( favTxt )
    
    -- Is fav
    if not(item.isFav == 0 or item.isFav == '0') then 
        shapeR.isMark = true
        shapeR:setFillColor( 0, .5, 0 )
    end
    
    -- Place Detail
    local dImg1 = display.newImage("img/btn/detailPlace.png")
    dImg1.x, dImg1.y = 60, 460
    groupEvt:insert( dImg1 )
    local dTxt1 = display.newText( (item.subtitle1..", "..item.subtitle2), 270, 460, 360, 24,  "Chivo", 18)
    dTxt1:setFillColor( 0 )
    groupEvt:insert( dTxt1 )
    local dotted1 = display.newImage("img/btn/dottedLine.png")
    dotted1.x, dotted1.y = midW, 490
    groupEvt:insert( dotted1 )
    -- Date Detail
    local dImg3 = display.newImage("img/btn/detailVigencia.png")
    dImg3.x, dImg3.y = 60, 530
    groupEvt:insert( dImg3 )
    local dImg3 = display.newText( item.dateMax, 270, 530, 360, 24,  "Chivo", 18)
    dImg3:setFillColor( 0 )
    groupEvt:insert( dImg3 )
    -- Time Detail
    local dImg3 = display.newImage("img/btn/detailHora.png")
    dImg3.x, dImg3.y = 290, 530
    groupEvt:insert( dImg3 )
    local dImg3 = display.newText( item.time, 400, 530, 150, 24,  "Chivo", 18)
    dImg3:setFillColor( 0 )
    groupEvt:insert( dImg3 )
    -- Line Dotted
    local dotted2 = display.newImage("img/btn/dottedLine.png")
    dotted2.x, dotted2.y = midW, 570
    groupEvt:insert( dotted2 )
    
    -- Descripcion
    local descTitle = display.newText( "Detalle del evento:", 190, 610, 330, 28, "Chivo", 20)
    descTitle:setFillColor( 0, .4, 0 )
    groupEvt:insert( descTitle )
    local descTxt = display.newText( item.info, 240, 690, 430, 0,  "Chivo", 16)
    descTxt:setFillColor( 0 )
    groupEvt:insert( descTxt )
    local lastY = 580 + (descTxt.contentHeight / 2) + 50
    descTxt.y = lastY
    lastY = lastY + (descTxt.contentHeight / 2) + 20
    
    -- Publicidad
    local publiShape = display.newRect( midW, lastY + 65, 480, 130 )
    publiShape:setFillColor( .95 )
    groupEvt:insert( publiShape )
    -- Determine if publicity exists
    local pathP = system.pathForFile( item.publicidad, system.TemporaryDirectory )
    local fhdP = io.open( pathP )
    if fhdP then
        fhdP:close()
        local publicidad = display.newImage(item.publicidad, system.TemporaryDirectory )
        publicidad.x, publicidad.y = midW, lastY + 55
        groupEvt:insert( publicidad )
    else
        -- Get from cloud
        display.loadRemoteImage( settings.url .. 'assets/img/app/publicity/movil/' .. item.publicidad, "GET", 
            function ( event )
                if ( event.isError ) then
                else
                    event.target.x, event.target.y = midW, lastY + 55
                    groupEvt:insert( event.target )
                end
        end, item.publicidad, system.TemporaryDirectory )
    end
    
    
    -- Reload Main Image
    local pathP = system.pathForFile( "max"..item.image, system.TemporaryDirectory )
    local fhdP = io.open( pathP )
    if fhdP then
        fhdP:close()
        local img2 = display.newImage("max"..item.image, system.TemporaryDirectory )
        img2.x = midW
        img2.y = (img2.height / 2) + 20
        scroll[i]:insert( img2 )
        -- Move Group
        img:removeSelf()
        img = nil
        imgShape.y = img2.y
        imgShape.height = img2.height + 4
        groupEvt.y = img2.height - 330
    else
        -- Get from cloud
        display.loadRemoteImage( settings.url .. 'assets/img/app/event/fullapp/' .. item.image, "GET", 
            function ( event )
                if ( event.isError ) then
                else
                    event.target.x, event.target.y = midW, (event.target.height / 2) + 20
                    scroll[i]:insert( event.target )
                    -- Move Group
                    img:removeSelf()
                    img = nil
                    imgShape.y = event.target.y
                    imgShape.height = event.target.height + 4
                    groupEvt.y = event.target.height - 330
                end
        end, "max"..item.image, system.TemporaryDirectory )
    end
    
end

function buildCoupon(item, i)
    
    -- Agregamos imagen
    local imgShape = display.newRect( midW, 216, 444, 396 )
    imgShape:setFillColor( .4 )
    scroll[i]:insert( imgShape )
    local imgShape2 = display.newRect(  midW, 383, 444, 62  )
    imgShape2:setFillColor( 0, .7, 0 )
    scroll[i]:insert( imgShape2 )
    local img = display.newImage(item.image, system.TemporaryDirectory)
    img.x, img.y = midW, 185
    img.width, img.height  = 440, 330
    scroll[i]:insert( img )
    
    -- Boton de Mapa
    btnMap[i] = display.newRect( midW - 110, 383, 220, 60 )
    btnMap[i].index = i
    btnMap[i]:setFillColor( 0 )
    btnMap[i].partnerName = item.partnerName
    btnMap[i].latitude = tonumber(item.latitude)
    btnMap[i].longitude = tonumber(item.longitude)
    btnMap[i]:addEventListener( "tap", tapPageMap )
    scroll[i]:insert( btnMap[i] )
    local mapIcon = display.newImage("img/btn/detailMap.png")
    mapIcon.x, mapIcon.y = 50, 382
    scroll[i]:insert( mapIcon )
    local mapTxt = display.newText( "Mostrar Mapa", midW - 100, 382, "Chivo", 20)
    mapTxt:setFillColor( 1 )
    scroll[i]:insert( mapTxt )
    -- Boton de Fav
    local shapeR = display.newRect( midW + 110, 383, 218, 60 )
    shapeR.index = i
    shapeR.idCupon = item.idCupon
    shapeR.idType = item.type
    shapeR.isMark = false
    shapeR:setFillColor( 0 )
    shapeR:addEventListener( "tap", tapPageFav )
    scroll[i]:insert( shapeR )
    local sheet = graphics.newImageSheet(Sprites.fav.source, Sprites.fav.frames)
    iconFav[i] = display.newSprite(sheet, Sprites.fav.sequences)
    iconFav[i].x, iconFav[i].y = midW + 32, 382
    scroll[i]:insert( iconFav[i] )
    local favTxt = display.newText( "Favoritos", midW + 110, 382, "Chivo", 20)
    favTxt:setFillColor( 1 )
    scroll[i]:insert( favTxt )
    
    -- Is fav
    if not(item.isFav == 0 or item.isFav == '0') then 
        shapeR.isMark = true
        shapeR:setFillColor( 0, .5, 0 )
    end
    
    -- Place Detail
    local dImg1 = display.newImage("img/btn/detailPlace.png")
    dImg1.x, dImg1.y = 60, 460
    scroll[i]:insert( dImg1 )
    local dTxt1 = display.newText( item.subtitle1, 270, 460, 360, 24,  "Chivo", 18)
    dTxt1:setFillColor( 0 )
    scroll[i]:insert( dTxt1 )
    local dotted1 = display.newImage("img/btn/dottedLine.png")
    dotted1.x, dotted1.y = midW, 490
    scroll[i]:insert( dotted1 )
    -- Vigency Detail
    local dImg3 = display.newImage("img/btn/detailVigencia.png")
    dImg3.x, dImg3.y = 60, 530
    scroll[i]:insert( dImg3 )
    local dImg3 = display.newText( item.validity, 270, 530, 360, 24,  "Chivo", 18)
    dImg3:setFillColor( 0 )
    scroll[i]:insert( dImg3 )
    local dotted2 = display.newImage("img/btn/dottedLine.png")
    dotted2.x, dotted2.y = midW, 570
    scroll[i]:insert( dotted2 )
        
    -- Descripcion
    local descTitle = display.newText( "Detalle de la promoción:", 190, 610, 330, 28, "Chivo", 20)
    descTitle:setFillColor( 0, .4, 0 )
    scroll[i]:insert( descTitle )
    local descTxt = display.newText( item.detail, 240, 690, 430, 0,  "Chivo", 16)
    descTxt:setFillColor( 0 )
    scroll[i]:insert( descTxt )
    local lastY = 580 + (descTxt.contentHeight / 2) + 50
    descTxt.y = lastY
    lastY = lastY + (descTxt.contentHeight / 2) + 60
    local dotted3 = display.newImage("img/btn/dottedLine.png")
    dotted3.x, dotted3.y = midW, lastY - 40
    scroll[i]:insert( dotted3 )
    
    -- Terminos y condiciones
    local termTitle = display.newText( "Terminos y condiciones:", 190, lastY, 330, 28, "Chivo", 20)
    termTitle:setFillColor( 0, .4, 0 )
    scroll[i]:insert( termTitle )
    local termTxt = display.newText( item.clauses, 240, lastY, 430, 0,  "Chivo", 16)
    termTxt:setFillColor( 0 )
    scroll[i]:insert( termTxt )
    -- Move Text
    lastY = lastY + (termTxt.contentHeight / 2) + 25
    termTxt.y = lastY
    lastY = lastY + (termTxt.contentHeight / 2) + 15
    
    -- Publicidad
    local publiShape = display.newRect( midW, lastY + 65, 480, 130 )
    publiShape:setFillColor( .95 )
    scroll[i]:insert( publiShape )
    -- Determine if publicity exists
    local pathP = system.pathForFile( item.publicidad, system.TemporaryDirectory )
    local fhdP = io.open( pathP )
    if fhdP then
        fhdP:close()
        local publicidad = display.newImage(item.publicidad, system.TemporaryDirectory )
        publicidad.x, publicidad.y = midW, lastY + 55
        scroll[i]:insert( publicidad )
    else
        -- Get from cloud
        display.loadRemoteImage( settings.url .. 'assets/img/app/publicity/movil/' .. item.publicidad, "GET", 
            function ( event )
                if ( event.isError ) then
                else
                    event.target.x, event.target.y = midW, lastY + 55
                    scroll[i]:insert( event.target )
                end
        end, item.publicidad, system.TemporaryDirectory )
    end
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
    background:setFillColor(0)
    screen:insert(background)
    
    -- Height status bar
    hC = display.topStatusBarContentHeight
    
    -- Creamos toolbar
    local titleBar = display.newRect( display.contentCenterX, hC, display.contentWidth, 65 )
    titleBar.anchorY = 0;
    titleBar:setFillColor( 0 ) 
    screen:insert(titleBar)
    
    local lineBar = display.newRect( display.contentCenterX, 63 + hC, display.contentWidth, 5 )
    lineBar:setFillColor({
        type = 'gradient',
        color1 = { 0, 1, 0, 1 }, 
        color2 = { 0, .5, 0, .5 },
        direction = "bottom"
    }) 
    screen:insert(lineBar)

    local btnReturn = display.newImage("img/btn/left.png", true) 
    btnReturn.x = 35
    btnReturn.y = 35 + hC
    screen:insert(btnReturn)
    btnReturn:addEventListener( "tap", gotoMain )
    
    txtTitle = display.newText( "", midW + 15, 35 + hC, "Chivo", 24)
    txtTitle:setFillColor( 1 )
    screen:insert( txtTitle )
    
    -- Generamos contenedor
    group = display.newGroup()
    screen:insert(group)
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    -- Settings
    settings = DBManager.getSettings()
    -- Title Detail
    txtTitle.text = Globals.Items[currentI].title
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


