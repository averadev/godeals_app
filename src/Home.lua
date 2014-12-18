---------------------------------------------------------------------------------
-- Godeals App
-- Alberto Vera
-- GeekBucket Software Factory
---------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- REQUIRE & VARIABLES
---------------------------------------------------------------------------------
local storyboard = require( "storyboard" )
local Globals = require('src.resources.Globals')
local Sprites = require('src.resources.Sprites')
local DBManager = require('src.resources.DBManager')
local RestManager = require('src.resources.RestManager')
local widget = require( "widget" )
local scene = storyboard.newScene()

-- Pantallas
require('src.Menu')
local menuScreen = Menu:new()
local homeScreen = display.newGroup()

-- Objects
local scrollView, menuGrp, menuRGrp, subMenuGrp, navGrp, settings, titleLoading, mask 
local btnMenu, loading, title, loadingGrp, bgFloatMenu, titleNav, navArrowL, bgNav, filter
local svHeightY = {}
local coupons = {}
local imageItems = {}
local submenu = {}
local submenuTxt = {}
local submenuline = {}
local submenuRest = {}
local bgSubMenu = {}
local bgSubMenuR = {}
local banners = {}
local noPackage = 1
local fxTap = audio.loadSound( "fx/click.wav")

-- Variables
local intW = display.contentWidth
local intH = display.contentHeight
local midW = display.contentCenterX
local midH = display.contentCenterY
local h = display.topStatusBarContentHeight
local lastY = 0;
local noMax, noCou = 1, 1
local noCallback = 0
local currentPage = 0
local currentAgenda = 0
local isHome = true
local isBreak = false


---------------------------------------------------------------------------------
-- LISTENERS
---------------------------------------------------------------------------------
function showMenu(event)
    if isHome and mask.alpha == 0 then
        isHome = false
        transition.to( homeScreen, { x = homeScreen.x + 400, time = 400, transition = easing.outExpo } )
        transition.to( menuScreen, { x = menuScreen.x + 400, time = 400, transition = easing.outExpo } )
        transition.to( mask, { alpha = .5, time = 400, transition = easing.outQuad } )
    end
end

function hideMenu(event)
    if not isHome and not isBreak then
        isBreak = true
        transition.to( homeScreen, { x = 0, time = 400, transition = easing.outExpo } )
        transition.to( menuScreen, { x = - 400, time = 400, transition = easing.outExpo } )
        transition.to( mask, { alpha = 0, time = 400, transition = easing.outQuad } )
        timer.performWithDelay( 500, function()
            isHome = true
            isBreak = false
        end, 1 )
    end
    hideMenuFilter()
    hideMenuRFilter()
end

function moveHome(xPosH)
    homeScreen.x = xPosH
end

function agendaR(event)
    if isHome and mask.alpha == 0 then
        cleanHome()
        audio.play(fxTap)
        noCallback = noCallback + 1
        navArrowL.alpha = 1
        currentAgenda = currentAgenda + 1
        RestManager.getByDate(currentAgenda)
    end
end

function agendaL(event)
    if isHome and mask.alpha == 0 and navArrowL.alpha == 1 then
        cleanHome()
        audio.play(fxTap)
        noCallback = noCallback + 1
        currentAgenda = currentAgenda - 1
        if currentAgenda == 0 then navArrowL.alpha = .3 end
        RestManager.getByDate(currentAgenda)
    end
end

function showCoupon(event)
    if isHome and mask.alpha == 0 then
        storyboard.gotoScene( "src.Coupon", {
            time = 400,
            effect = "crossFade",
            params = { index = event.target.index }
        })
    end
end

function logout()
    DBManager.clearUser()
    storyboard.gotoScene( "src.Login", {
        time = 400,
        effect = "crossFade"
    })
end

function showFav(event)
    if isHome then
        currentPage = 0
        showAgendaBar(false)
        menuScreen:clearSelMenu()
        cleanHome()
        hideFilter()
        noCallback = noCallback + 1
        title.text = "Favoritos"
        event.target.alpha = .5
        RestManager.getFav()
    end
end

function showComer(event)
    if isHome then
        currentPage = 0
        showAgendaBar(false)
        menuScreen:clearSelMenu()
        cleanHome()
        hideFilter()
        noCallback = noCallback + 1
        title.text = "Comercios"
        event.target.alpha = .5
        RestManager.getComer()
    end
end


function loadComercio(idComer)
    bgNav:setFillColor( 0 )
    title.text = ""
    currentPage = 0
    showAgendaBar(false)
    cleanHome()
    noCallback = noCallback + 1
    RestManager.getComercio(idComer)
end

function showMap(event)
    if isHome then
        storyboard.gotoScene( "src.Map", { time = 400, effect = "crossFade" })
    end
end
function showMenuR(event)
    if menuRGrp.alpha == 0 then
        transition.to( mask, { alpha = .5, time = 400, transition = easing.outQuad } )
        transition.to( menuRGrp, { alpha = 1, time = 400, transition = easing.outQuad } )
    else
        hideMenuRFilter()
    end
end
function hideMenuRFilter()
    if menuRGrp.alpha == 1 then
        transition.to( mask, { alpha = 0, time = 400, transition = easing.outQuad } )
        transition.to( menuRGrp, { alpha = 0, time = 400, transition = easing.outQuad } )
    end
end

function showMenuFilter(event)
    if filter.alpha == 1 then 
        if subMenuGrp.alpha == 0 then
            if #coupons > 0 then if coupons[2].method == 'search' then coupons[2].x = -300 end end
            transition.to( mask, { alpha = .5, time = 400, transition = easing.outQuad } )
            transition.to( subMenuGrp, { alpha = 1, time = 400, transition = easing.outQuad } )
        else
            hideMenuFilter()
        end
    end
end
function hideMenuFilter()
    if subMenuGrp.alpha == 1 then
        if #coupons > 0 then if coupons[2].method == 'search' then coupons[2].x = midW - 30 end end
        transition.to( mask, { alpha = 0, time = 400, transition = easing.outQuad } )
        transition.to( subMenuGrp, { alpha = 0, time = 400, transition = easing.outQuad } )
    end
end

function searchDir(event)
    -- Cargar por tipo
    if mask.alpha == 0 then
        Globals.CurrentRest = {}
        for z = 1, #bgSubMenu, 1 do bgSubMenu[z].alpha = .1 end
        bgSubMenu[1].alpha = .5
        local toFind = coupons[2].text:upper()
        for i = 1, #Globals.Directory do
            if string.match(Globals.Directory[i].name:upper(), toFind) then
                table.insert(Globals.CurrentRest, Globals.Directory[i])
            end
        end
        loadRestaurants()
        native.setKeyboardFocus(nil)
    end
end
function searchCancel(event)
    if mask.alpha == 0 then
        -- Hide button
        event.target.alpha = 0
        coupons[2].text = ''
        for z = 1, #bgSubMenu, 1 do bgSubMenu[z].alpha = .1 end
        bgSubMenu[1].alpha = .5
        -- Set new rows
        Globals.CurrentRest = Globals.Directory
        loadRestaurants()
        native.setKeyboardFocus(nil)
    end
end
function onTxtSearch(event)
    if event.target.text == '' then
        coupons[4].alpha = 0
    else
        coupons[4].alpha = 1
    end
    if ( "submitted" == event.phase ) then
        searchDir()
    end
end

function getMenuR(event)
end

---------------------------------------------------------------------------------
-- FUNCTIONS
---------------------------------------------------------------------------------

-- Cargamos por menu
function changeTitle(value)
    title.text = value
end

function networkConnection(screenError)
    local netConn = require('socket').connect('www.google.com', 80)
    if netConn == nil then
        if screenError then
            notConnection()
        end
        return false
    end
    netConn:close()
    return true
end

local function reloadConn()
    audio.play(fxTap)
    if networkConnection(false) then
        coupons[4].alpha = 0
        loadBy(1)
    else
        coupons[4].alpha = 0
        transition.to( coupons[4], { alpha = 1, time = 800} )
    end
end

function showFilter()
    filter.alpha = 1
end
function hideFilter()
    filter.alpha = .5
end

function emptyFav()
    coupons[1] = display.newImage( scrollView, "img/btn/errorOmg.png", true) 
    loadingGrp.alpha = 0
    
    coupons[2] = display.newText( scrollView, "¡Oh!", 12, 0, "Chivo", 30 )
    coupons[2].y = - 200
    coupons[2]:setFillColor( .3 )
    
    coupons[3] = display.newText( scrollView, "Aún no tienes Deals marcados como favoritos.", 12, 0, "Chivo", 20 )
    coupons[3].y = - 160
    coupons[3]:setFillColor( .15 )
    
    coupons[4] = display.newText( scrollView, "Puedes marcar tu Deal como Favorito", 12, 0, "Chivo", 20 )
    coupons[4].y = 140
    coupons[4]:setFillColor( .3 )
    
    coupons[5] = display.newText( scrollView, "en el detalle del mismo ;)", 12, 0, "Chivo", 20 )
    coupons[5].y = 165
    coupons[5]:setFillColor( .3 )
end

function emptyPage()
    coupons[1] = display.newImage( scrollView, "img/btn/errorOmg.png", true) 
    loadingGrp.alpha = 0
    
    coupons[2] = display.newText( scrollView, "¡Oh!", 12, 0, "Chivo", 30 )
    coupons[2].y = - 200
    coupons[2]:setFillColor( .3 )
    
    coupons[3] = display.newText( scrollView, "De momento esta sección esta vacia.", 12, 0, "Chivo", 20 )
    coupons[3].y = - 160
    coupons[3]:setFillColor( .15 )
    
    coupons[4] = display.newText( scrollView, "No te preocupes, seguramente en algunas horas", 12, 0, "Chivo", 20 )
    coupons[4].y = 140
    coupons[4]:setFillColor( .3 )
    
    coupons[5] = display.newText( scrollView, "tendrá información y promociones ;)", 12, 0, "Chivo", 20 )
    coupons[5].y = 165
    coupons[5]:setFillColor( .3 )
end

function notConnection()
    title.text = ''
    loadingGrp.alpha = 0

    coupons[1] = display.newImage( scrollView, "img/btn/errorSad.png", true) 
    loadingGrp.alpha = 0
    
    coupons[2] = display.newText( scrollView, "¡Emmm!", 12, 0, "Chivo", 30 )
    coupons[2].y = - 230
    coupons[2]:setFillColor( .3 )
    
    coupons[3] = display.newText( scrollView, "Al parecer no hay conexión a internet.", 12, 0, "Chivo", 20 )
    coupons[3].y = - 190
    coupons[3]:setFillColor( .15 )
    
    coupons[4] = display.newRoundedRect( scrollView, 0, 160, 380, 60, 10 )
    coupons[4]:addEventListener( "tap", reloadConn )
    coupons[4]:setFillColor( .5 )
    
    coupons[5] = display.newText( scrollView, "Volver a intentar (^_^)/", 12, 0, "Chivo", 20 )
    coupons[5].y = 160
    coupons[5]:setFillColor( 1 )
end

local function onRowRender( event )
    --Set up the localized variables to be passed via the event table
    local row = event.row
    local id = row.index
    
    row.nameText = display.newText( Globals.CurrentRest[id].name, 12, 0, "Chivo", 20 )
    row.nameText.anchorX = 0
    row.nameText.anchorY = 0.5
    row.nameText:setFillColor( 0 )
    row.nameText.x = 55
    row.nameText.y = 27
    
    row.shape = display.newRect( row, midW, 54, intW, 30 )
    row.shape:setFillColor( {
        type = 'gradient',
        color1 = { 1, 1 }, 
        color2 = { .9, .7 },
        direction = "top"
    } )
    
    if Globals.CurrentRest[id].isFav == '0' or Globals.CurrentRest[id].isFav == 0 then
        row.restMark = display.newImage( row, "img/btn/restMark"..Globals.CurrentRest[id].directoryTypeId..".png", true) 
        row.restMark.x = 435
        row.restMark.y = 35
    else
        local path = system.pathForFile( Globals.CurrentRest[id].image, system.TemporaryDirectory )
        local fhd = io.open( path )
        -- Determine if file exists
        if fhd then
            fhd:close()
            row.restMark = display.newImage(row, Globals.CurrentRest[id].image, system.TemporaryDirectory )
            row.restMark.x = 430
            row.restMark.y = 35
        else
            -- Get from remote
            display.loadRemoteImage( settings.url .. 'assets/img/app/directory/' .. Globals.CurrentRest[id].image, 
            "GET", 
            function ( event )
                if ( event.isError ) then
                else
                    event.target.x = 430
                    event.target.y = 35
                    row:insert(event.target)
                end
            end, Globals.CurrentRest[id].image, system.TemporaryDirectory )
        end
    end
    
    row.iconPhone = display.newImage( row, "img/btn/iconPhone.png", true) 
    row.iconPhone.x = 70
    row.iconPhone.y = 54

    row.phoneText = display.newText( Globals.CurrentRest[id].phone, 12, 0, "Chivo", 18 )
    row.phoneText.anchorX = 0
    row.phoneText.anchorY = 0.5
    row.phoneText:setFillColor( 0.3 )
    row.phoneText.x = 90
    row.phoneText.y = 54

    row:insert( row.nameText )
    row:insert( row.phoneText )
    return true
end

function getDirectoryType(event)
    -- Remove selections
    for z = 1, #bgSubMenu, 1 do
        bgSubMenu[z].alpha = .1
    end
    -- Set new selection
    local t = event.target
    t.alpha = .5
    
    if t.cat == 'Coupon' then
        cleanHome()
        noCallback = noCallback + 1
        if t.type == '0' or t.type == 0 then
            RestManager.getItems(Globals.promoCat)
        else
            RestManager.getItems(Globals.promoCat, t.type)
        end
    else
        -- Clear elements
        Globals.CurrentRest = {}
        coupons[2].text = ''
        coupons[4].alpha = 0
        native.setKeyboardFocus(nil)
        -- Cargar por tipo
        if t.type == '0' or t.type == 0 then
            Globals.CurrentRest = Globals.Directory
        else
            for i = 1, #Globals.Directory do
                if Globals.Directory[i].directoryTypeId == t.type then
                    table.insert(Globals.CurrentRest, Globals.Directory[i])
                end
            end
        end
        loadRestaurants()
    end
end

function loadSubmenu()
    clearSubMenu()
    bgFloatMenu.height = #Globals.SubMenu * 60
    
    for z = 1, #Globals.SubMenu, 1 do 
        submenu[z] = display.newGroup()
        subMenuGrp:insert(submenu[z])
        local tmpPosc = (35 + h) + (60 * z)

        bgSubMenu[z] = display.newRect(submenu[z], 360, tmpPosc, 240, 50 )
        bgSubMenu[z]:setFillColor( .2 ) 
        bgSubMenu[z].alpha = .1
        bgSubMenu[z].cat = Globals.SubMenu[z].type
        if z == 1 then bgSubMenu[z].alpha = .5 end
        bgSubMenu[z].type = Globals.SubMenu[z].id
        bgSubMenu[z]:addEventListener( "tap", getDirectoryType )

        local imgIcon = display.newImage(submenu[z], "img/btn/btn".. Globals.SubMenu[z].type .. Globals.SubMenu[z].id ..".png", true) 
        imgIcon.x = 280
        imgIcon.y = tmpPosc

        local desc = display.newText( submenu[z], Globals.SubMenu[z].name, 390, tmpPosc, 160, 18, "Chivo", 16)
        desc:setFillColor( .8, .8, .8 )

        local line = display.newRect(submenu[z], 360, tmpPosc + 30, 180, 1 )
        line.alpha = .2
    end
end
function clearSubMenu()
    for z = 1, #bgSubMenu, 1 do
        bgSubMenu[z]:removeSelf()
        bgSubMenu[z] = nil
    end
    for z = 1, #submenu, 1 do
        submenu[z]:removeSelf()
        submenu[z] = nil
    end
    submenu = {}
    bgSubMenu = {}
end

function loadCouponFilter(typeS)
    if typeS == 3 then Globals.SubMenu = Globals.CouponType2 end
    if typeS == 4 then Globals.SubMenu = Globals.CouponType1 end
    loadSubmenu()
end

function loadDirectory()
    if  loadingGrp.alpha == 0 then
        currentPage = 7
        noCallback = noCallback + 1
        Globals.callbackDirectory = noCallback
        cleanHome()
        titleLoading.text = "Por favor espere..."
    end
    
    if #Globals.Directory == 0 then
        -- Load info from cloud
        RestManager.getDirectory()
    elseif Globals.callbackDirectory == noCallback then
        -- Cargar menu
        Globals.SubMenu = Globals.DirectoryType
        loadSubmenu()
        
        -- Stop Loading
        loadingGrp.alpha = 0
        loading:setSequence("stop")
        
        -- Create Table View
        coupons[1] = widget.newTableView {
            height = scrollView.height - 60,
            width = intW,
            left = 0,
            top = 60,
            onRowRender = onRowRender
        }
        scrollView:insert( coupons[1] )

        coupons[2] = native.newTextField(midW - 30, 30, 280, 60 )
        coupons[2].method = "search"
        coupons[2].hasBackground = false
        scrollView:insert( coupons[2] )
        coupons[2]:addEventListener( "userInput", onTxtSearch )

        coupons[3] = display.newImage("img/btn/btnSearch.png", true) 
        coupons[3].type = 1
        coupons[3].x = intW - 40
        coupons[3].y = 30
        scrollView:insert( coupons[3] )
        coupons[3]:addEventListener( "tap", searchDir )

        coupons[4] = display.newImage("img/btn/btnClose.png", true) 
        coupons[4].x = intW - 100
        coupons[4].y = 30
        coupons[4].alpha = 0
        scrollView:insert( coupons[4] )
        coupons[4]:addEventListener( "tap", searchCancel )
        
        coupons[5] = display.newImage("img/btn/bgTxtSearch.png", true) 
        coupons[5].x = midW - 30
        coupons[5].y = 50
        scrollView:insert( coupons[5] )
        
        -- Cargamos todos los registros
        Globals.CurrentRest = Globals.Directory
        loadRestaurants()
        
    end
end

function loadRestaurants()
    -- Set Rows
    if coupons[1]:getNumRows() > 0 then
        coupons[1]:deleteAllRows()
    end
    print(#Globals.CurrentRest)
    for i = 1, #Globals.CurrentRest do
        local rowHeight = 70
        local rowColor = { default={ 1, 1, 1 }, over={ 1, 0.5, 0, 0.2 } }
        local lineColor = { 1 }
        
        -- Insert a row into the tableView
        coupons[1]:insertRow({
            rowHeight = rowHeight,
            rowColor = rowColor,
            lineColor = lineColor
        })
    end
end

-- Obtenemos los datos de la web
function loadBy(type)
    cleanHome()
    titleLoading.text = "Por favor espere..."
    currentPage = type
    Globals.promoCat = type
    noCallback = noCallback + 1
    if type == 1 then
        showAgendaBar(true)
        RestManager.getByDate(currentAgenda)
    else
        showAgendaBar(false)
        RestManager.getItems(type)
    end
end

function showAgendaBar(bool)
    if bool then
        navGrp.alpha = 1
        navArrowL.alpha = .3
        currentAgenda = 0
        scrollView.height = intH - (133 + h)
        scrollView.y = (midH + ((135 + h)/2))
    else
        navGrp.alpha = 0
        scrollView.height = intH - (63 + h)
        scrollView.y = (midH + ((65 + h)/2))
    end
    
end

-- Cargar Info comercio
function loadComerio(comercio)
    
    -- Stop Loading
    loadingGrp.alpha = 0
    loading:setSequence("stop")
    
    -- Generamos contenedor
    local lastB = 1
    lastY = lastY + 15
    banners[lastB] = display.newContainer( 444, 400 )
    banners[lastB].index = lastC
    banners[lastB].x = midW
    banners[lastB].y = lastY + 166
    scrollView:insert( banners[lastB] )
    
    local bg = display.newImage(banners[lastB], "img/btn/tmpComer.jpg", true) 
	bg.x, bg.y = 0, 0
    
    local shape = display.newRect(banners[lastB], 0, -110, 440, 90 )
    shape:setFillColor( 1, .4 )
    local square1 = display.newRect(banners[lastB], 0, -155, 440, 2 ) 
    square1:setFillColor( .7, .5 )
    local square2 = display.newRect(banners[lastB], 0, -65, 440, 2 ) 
    square2:setFillColor( .7, .5 )
    local square3 = display.newRect(banners[lastB], -219, -110, 2, 90 ) 
    square3:setFillColor( .7, .5 )
    local square4 = display.newRect(banners[lastB], 219, -110, 2, 90 ) 
    square4:setFillColor( .7, .5 )
    
    -- Agregamos logo
    local path = system.pathForFile( comercio.image, system.TemporaryDirectory )
    local fhd = io.open( path )
    if fhd then
        fhd:close()
        local mask = graphics.newMask( "img/bgk/maskAvatar.jpg" )
        local logo = display.newImage(banners[1], comercio.image, system.TemporaryDirectory )
        logo.x = -160
        logo.y = -110
        logo.width = 80
        logo.height  = 80
        logo:setMask( mask )
    else
        local function networkListenerComer( event )
            if ( event.isError ) then
            else
                local mask = graphics.newMask( "img/bgk/maskAvatar.jpg" )
                event.target.x = -160
                event.target.y = -1100
                event.target.width = 80
                event.target.height  = 80
                event.target:setMask( mask )
                banners[1]:insert( event.target )
            end
        end

        display.loadRemoteImage( 
        settings.url..'assets/img/app/logo/'..comercio.image, 
        "GET", networkListenerComer, comercio.image, system.TemporaryDirectory ) 
    end
    
    -- Agregamos banner
    if not (comercio.banner == '') then
        local yBanner = lastY + 170
        local path = system.pathForFile(comercio.banner, system.TemporaryDirectory )
        local fhd = io.open( path )
        if fhd then
            fhd:close()
            local image = display.newImage(banners[1], comercio.banner, system.TemporaryDirectory )
            image.x = 0
            image.y = 0
            image:toBack()
            bg:toBack()
        else
            local function networkListenerComer( event )
                if ( event.isError ) then
                else
                    event.target.x = 0
                    event.target.y = 0
                    event.target:setMask( mask )
                    banners[1]:insert( event.target )
                    event.target:toBack()
                    bg:toBack()
                end
            end

            display.loadRemoteImage( 
            settings.url..'assets/img/app/comercio/'..comercio.banner, 
            "GET", networkListenerComer, comercio.banner, system.TemporaryDirectory ) 
        end
    end
    
    local txtTitle = display.newText( comercio.name, 45, -120, 300, 30,  "Chivo", 25)
    txtTitle:setFillColor( .1 )
    banners[lastB]:insert(txtTitle)
    local txtSubtitle1 = display.newText( comercio.categoryName, 30, -90, 270, 25, "Chivo", 18)
    txtSubtitle1:setFillColor( .2 )
    banners[lastB]:insert(txtSubtitle1)
    
    -- Footer
    local shapeL = display.newRect(banners[lastB], 0, 75, 440, 60 )
    shapeL:setFillColor( 0, .7 )
    local icon1 = display.newImage(banners[lastB], "img/btn/iconTel.png", true) 
	icon1.x, icon1.y = -160, 75
    local txtTelefono = display.newText( comercio.phone, -20, 75, 200, 28, "Chivo", 25)
    txtTelefono:setFillColor( 1 )
    banners[lastB]:insert(txtTelefono)
    
    local shapeL = display.newRect(banners[lastB], 0, 135, 440, 60 )
    shapeL:setFillColor( 0, .7 )
    local icon1 = display.newImage(banners[lastB], "img/btn/iconPlace.png", true) 
	icon1.x, icon1.y = -160, 135
    local txtTelefono = display.newText( comercio.address, -20, 135, 200, 40, "Chivo", 17)
    txtTelefono:setFillColor( 1 )
    banners[lastB]:insert(txtTelefono)
    
    local dotted1 = display.newImage("img/btn/dottedLine.png")
    dotted1.x, dotted1.y = 0, 105
    banners[lastB]:insert( dotted1 )
    
    local dotted2 = display.newImage("img/btn/dottedLine2.png")
    dotted2.x, dotted2.y = 0, 193
    dotted2.alpha = .5
    banners[lastB]:insert( dotted2 )
    
    if comercio.id == '11' then
        local imgD = display.newImage("img/btn/tmpGB.png")
        imgD.x, imgD.y = midW, 670
        scrollView:insert( imgD )
    end
    
    -- Guardamos la ultima posicion
    lastY = lastY + 360
    
end
    

-- Cargamos imagenes
function loadImages(items)
    Globals.Items = items
    titleLoading.text = "Descargando imagenes..."
    for y = 1, #Globals.Items, 1 do 
        Globals.Items[y].callback = noCallback
    end
    loadImage(1)
end
function loadImage(posc)
    -- Listener loading
    if not (Globals.Items[posc].image == nil) then
        local function networkListener( event )
            -- Verificamos el callback activo
            if #Globals.Items <  posc then 
                if not ( event.isError ) then
                    destroyImage(event.target)
                end
            elseif Globals.Items[posc].callback == noCallback then
                if ( event.isError ) then
                    native.showAlert( "Go Deals", "Network error :(", { "OK"})
                else
                    event.target.alpha = 0
                    imageItems[posc] = event.target
                    if posc < #Globals.Items and posc <= (noPackage * 10) then
                        loadImage(posc + 1)
                    else
                        buildItems()
                    end
                end
            elseif not ( event.isError ) then
                destroyImage(event.target)
            end
        end
        -- Do call image

        Globals.Items[posc].idCupon = Globals.Items[posc].id
        Globals.Items[posc].id = posc
        local path = system.pathForFile( Globals.Items[posc].image, system.TemporaryDirectory )
        local fhd = io.open( path )
        -- Determine if file exists
        if fhd then
            fhd:close()
            imageItems[posc] = display.newImage( Globals.Items[posc].image, system.TemporaryDirectory )
            if Globals.Items[posc].callback == noCallback then
                imageItems[posc].alpha = 0
                if posc < #Globals.Items and posc <= (noPackage * 10) then
                    loadImage(posc + 1)
                else
                    buildItems()
                end
            else
                destroyImage(imageItems[posc])
            end
        else
           display.loadRemoteImage( settings.url..'assets/img/app/'..Globals.Items[posc].path..Globals.Items[posc].image, 
            "GET", networkListener, Globals.Items[posc].image, system.TemporaryDirectory ) 
        end
    else
        loadImage(posc + 1)
    end
end

function destroyImage(obj)
    obj.alpha = 0
    obj:removeSelf()
    obj = nil
end

-- Construimos items
function buildItems()
    -- Stop loading sprite
    if noPackage == 1 then
        loading:setSequence("stop")
        loadingGrp.alpha = 0
    else
        coupons[#coupons]:removeSelf()
        coupons[#coupons] = nil
    end
    -- Build items
    local z = (noPackage * 10) - 9
    while z <= #Globals.Items and z <= (noPackage * 10) do 
        -- Armar titulos
        if currentPage == 1 then
            local typeBanner = ''
            if z == 1 then
                if Globals.Items[z].type == 2 then typeBanner = 'Eventos' 
                elseif Globals.Items[z].type == 6 then typeBanner = 'Sport TV' 
                elseif Globals.Items[z].type == 3 then typeBanner = 'Promociones y Descuentos' end
            else
                if not (Globals.Items[z].type == Globals.Items[z - 1].type) then
                    if Globals.Items[z].type == 2 then typeBanner = 'Eventos' 
                    elseif Globals.Items[z].type == 6 then typeBanner = 'Sport TV' 
                    elseif Globals.Items[z].type == 3 then typeBanner = 'Promociones y Descuentos' end
                end
            end
            if not (typeBanner == '') then setBanner(typeBanner) end
        end
        
        -- Armar cupones
        if Globals.Items[z].fav == 2 or Globals.Items[z].fav == "2" then
            setComerCoupon(Globals.Items[z]) 
        elseif Globals.Items[z].fav == 1 or Globals.Items[z].fav == "1" then
            setMaxCoupon(Globals.Items[z]) 
        else
            setStdCoupon(Globals.Items[z]) 
        end
        z = z + 1
    end
    
    -- Validate Loading
    if  #Globals.Items > (noPackage * 10) then
        -- Create Loading
        coupons[#coupons + 1] = display.newContainer( 444, 150 )
        coupons[#coupons].x = midW
        coupons[#coupons].y = lastY + 60
        scrollView:insert( coupons[#coupons] )
        
        -- Sprite and text
        local sheet = graphics.newImageSheet(Sprites.loading.source, Sprites.loading.frames)
        local loadingBottom = display.newSprite(sheet, Sprites.loading.sequences)
        loadingBottom.y = -10
        coupons[#coupons]:insert(loadingBottom)
        loadingBottom:setSequence("play")
        loadingBottom:play()
        local title = display.newText( "Cargando, por favor espere...", 0, 30, "Chivo", 16)
        title:setFillColor( .3, .3, .3 )
        coupons[#coupons]:insert(title) 
        
        -- Call new images
        noPackage = noPackage + 1
        loadImage((noPackage * 10) - 9)
    else
        if navGrp.alpha == 1 then
            lastY = lastY + 70
        end
        
        -- Create Space
        coupons[#coupons + 1] = display.newContainer( 444, 40 )
        coupons[#coupons].x = midW
        coupons[#coupons].y = lastY + 40
        scrollView:insert( coupons[#coupons] )
    end
end

-- Limpiamos scrollview
function cleanHome()
    -- Limpiar Scroll
    noPackage = 1
    for z = 1, #bgSubMenuR, 1 do 
        bgSubMenuR[z].alpha = .1
    end
    for z = 1, #imageItems, 1 do 
        imageItems[z]:removeSelf()
        imageItems[z] = nil
    end
    for z = 1, #banners, 1 do 
        if not(banners[z] == nil) then
            banners[z]:removeSelf()
            banners[z] = nil
        end
    end
    for z = 1, #coupons, 1 do 
        if not(coupons[z] == nil) then
            coupons[z]:removeEventListener( "tap", showCoupon )
            coupons[z]:removeSelf()
            coupons[z] = nil
        end
    end
    lastY = 0;
    coupons = {}
    banners = {}
    -- Play loading
    loadingGrp.alpha = 1
    loading:setSequence("play")
    loading:play()
    -- Set scroll Top
    scrollView:scrollToPosition( { y = 0 } )
    -- Quitar escena de cupones
    storyboard.removeScene( "src.Coupon" )
end

function loadTxtBanner(dateFormat)
    titleNav.text = dateFormat
end

function setBanner(typeBanner)
    -- Counter
    local lastC = #banners + 1
    if #banners == 0 then lastY = lastY + 20 end
    
    -- Generamos contenedor
    banners[lastC] = display.newContainer( 480, 50 )
    banners[lastC].index = lastC
    banners[lastC].x = midW
    banners[lastC].y = lastY + 68
    scrollView:insert( banners[lastC] )
    
    local shapeL = display.newRect( -40, 0, 360, 50 )
    shapeL:setFillColor( 0, .59, 0 )
    banners[lastC]:insert( shapeL )
    local shapeR = display.newRect( 180, 0, 80, 50 )
    shapeR:setFillColor( 0, .69, 0 )
    banners[lastC]:insert( shapeR )
    
    local icon = display.newImage(banners[lastC], "img/btn/iconCalendar.png", true) 
	icon.x = 180
	icon.y = 0
    
    -- Texto
    local txtTitle = display.newText( typeBanner, 0, 5, 360, 30, "Chivo", 22)
    txtTitle:setFillColor( 1 )
    banners[lastC]:insert( txtTitle )
    
    lastY = lastY + 70
end

function showComercio(event)
    loadComercio(event.target.idComer)
end
    
-- Genera una plantillla de comercio
function setComerCoupon(obj)
    -- Obtiene el total de cupones de la tabla y agrega uno
    local lastC = #coupons + 1
    
    -- Add Space
    if #coupons > 0 then
        lastY = lastY + 20
    else
        lastY = lastY + 30
    end
    
    -- Generamos contenedor
    coupons[lastC] = display.newContainer( 444, 330 )
    coupons[lastC].index = lastC
    coupons[lastC].x = midW
    coupons[lastC].y = lastY + 170
    scrollView:insert( coupons[lastC] )
    
    local bg = display.newImage(coupons[lastC], "img/btn/tmpComer.jpg", true) 
	bg.x, bg.y = 0, 0
    
    -- Agregamos banner
    if not (obj.banner == '') then
        local yBanner = lastY + 170
        local path = system.pathForFile( obj.banner, system.TemporaryDirectory )
        local fhd = io.open( path )
        if fhd then
            fhd:close()
            local image = display.newImage( obj.banner, system.TemporaryDirectory )
            image.x = 0
            image.y = 0
            coupons[lastC]:insert( image )
        else
            local function networkListenerComer( event )
                if ( event.isError ) then
                else
                    event.target.x = 0
                    event.target.y = 0
                    event.target:setMask( mask )
                    coupons[lastC]:insert( event.target )
                    event.target:toBack()
                    bg:toBack()
                end
            end

            display.loadRemoteImage( 
            settings.url..'assets/img/app/comercio/'..obj.banner, 
            "GET", networkListenerComer, obj.banner, system.TemporaryDirectory ) 
        end
    end
    local shape = display.newRect(coupons[lastC], 0, -110, 440, 90 )
    shape:setFillColor( 1, .4 )
    local square1 = display.newRect(coupons[lastC], 0, -155, 440, 2 ) 
    square1:setFillColor( .7, .5 )
    local square2 = display.newRect(coupons[lastC], 0, -65, 440, 2 ) 
    square2:setFillColor( .7, .5 )
    local square3 = display.newRect(coupons[lastC], -219, -110, 2, 90 ) 
    square3:setFillColor( .7, .5 )
    local square4 = display.newRect(coupons[lastC], 219, -110, 2, 90 ) 
    square4:setFillColor( .7, .5 )
    
    -- Agregamos logo
    local mask = graphics.newMask( "img/bgk/maskAvatar.jpg" )
    imageItems[obj.id].alpha = 1
    imageItems[obj.id].x = -160
    imageItems[obj.id].y = -110
    imageItems[obj.id].width = 80
    imageItems[obj.id].height  = 80
    imageItems[obj.id]:setMask( mask )
    coupons[lastC]:insert( imageItems[obj.id] )
    
    local txtTitle = display.newText( obj.name, 45, -120, 300, 30,  "Chivo", 25)
    txtTitle:setFillColor( .1 )
    coupons[lastC]:insert(txtTitle)
    local txtSubtitle1 = display.newText( obj.categoryName, 30, -90, 270, 25, "Chivo", 18)
    txtSubtitle1:setFillColor( .2 )
    coupons[lastC]:insert(txtSubtitle1)
    
    -- Footer
    local shapeL = display.newRect(coupons[lastC], -70, 135, 300, 60 )
    shapeL:setFillColor( 0, .7 )
    local shapeR = display.newRect(coupons[lastC], 150, 135, 140, 60 )
    shapeR:setFillColor( 0, .69, 0, .85 )
    shapeR.idComer = obj.idComer
    shapeR:addEventListener( "tap", showComercio )
    
    local icon1 = display.newImage(coupons[lastC], "img/btn/iconTel.png", true) 
	icon1.x, icon1.y = -160, 135
    local txtTelefono = display.newText( obj.phone, -20, 135, 200, 28, "Chivo", 25)
    txtTelefono:setFillColor( 1 )
    coupons[lastC]:insert(txtTelefono)
    
    local txtInfo = display.newText( "+ Info", 170, 135, 100, 28, "Chivo", 25)
    txtInfo:setFillColor( 1 )
    coupons[lastC]:insert(txtInfo)
    
    -- Guardamos la ultima posicion
    lastY = lastY + 350
    
end

-- Genera un cupon destacado
function setMaxCoupon(obj)
    -- Obtiene el total de cupones de la tabla y agrega uno
    local lastC = #coupons + 1
    
    -- Add Space
    if #coupons > 0 and  coupons[#coupons].type == 2 then
        lastY = lastY + 25
    else
        lastY = lastY + 5
    end
    
    -- Generamos contenedor
    coupons[lastC] = display.newContainer( 444, 334 )
    coupons[lastC].index = lastC
    coupons[lastC].x = midW
    coupons[lastC].type = 1
    coupons[lastC].y = lastY + 185
    scrollView:insert( coupons[lastC] )
    coupons[lastC]:addEventListener( "tap", showCoupon )
    
    -- Agregamos rectangulo alfa al pie
    local maxShape = display.newRect( 0, 0, 444, 334 )
    maxShape:setFillColor( 1, 1, 1, .7 )
    coupons[lastC]:insert( maxShape )
    
    -- Agregamos imagen
    imageItems[obj.id].alpha = 1
    imageItems[obj.id].width = 440
    imageItems[obj.id].height  = 330
    coupons[lastC]:insert( imageItems[obj.id] )
    
    -- Agregamos rectangulo alfa al pie
    local maxBottom = display.newRect( 0, 115, 440, 100 )
    maxBottom:setFillColor( 0, 0, 0, .7 )
    coupons[lastC]:insert( maxBottom )
    
    -- Agregamos textos
    if obj.type == 2 then
        local txtTitle = display.newText( obj.title, 20, 105, 440, 46,  "Chivo", 35)
        txtTitle:setFillColor( .4, .81, 0 )
        coupons[lastC]:insert(txtTitle)
        local txtSubtitle1 = display.newText( obj.dateMin .. ' en ' .. obj.subtitle1, 20, 148, 440, 60, "Chivo", 18)
        txtSubtitle1:setFillColor( 1, 1, 1 )
        coupons[lastC]:insert(txtSubtitle1)
        local txtSubtitle2 = display.newText( obj.subtitle2, 20, 170, 440, 60, "Chivo", 18)
        txtSubtitle2:setFillColor( 1, 1, 1 )
        coupons[lastC]:insert(txtSubtitle2)
    elseif obj.type == 3 or obj.type == 4 then
        local txtTitle = display.newText( obj.title, 20, 105, 440, 46,  "Chivo", 30)
        txtTitle:setFillColor( .4, .81, 0 )
        coupons[lastC]:insert(txtTitle)
        local txtSubtitle1 = display.newText( obj.subtitle1, 20, 148, 440, 60, "Chivo", 18)
        txtSubtitle1:setFillColor( 1, 1, 1 )
        coupons[lastC]:insert(txtSubtitle1)
    elseif obj.type == 5 then
        local txtTitle = display.newText( obj.title, 20, 105, 440, 46,  "Chivo", 30)
        txtTitle:setFillColor( .4, .81, 0 )
        coupons[lastC]:insert(txtTitle)
        local txtSubtitle1 = display.newText( obj.subtitle1, 20, 148, 440, 60, "Chivo", 18)
        txtSubtitle1:setFillColor( 1, 1, 1 )
        coupons[lastC]:insert(txtSubtitle1)
    elseif obj.type == 6 then
        local txtTitle = display.newText( obj.title, 20, 105, 440, 46,  "Chivo", 30)
        txtTitle:setFillColor( .4, .81, 0 )
        coupons[lastC]:insert(txtTitle)
        local txtSubtitle1 = display.newText(obj.subtitle1, 20, 148, 440, 60, "Chivo", 18)
        txtSubtitle1:setFillColor( 1, 1, 1 )
        coupons[lastC]:insert(txtSubtitle1)
        local txtSubtitle2 = display.newText( obj.subtitle2, 20, 170, 440, 60, "Chivo", 18)
        txtSubtitle2:setFillColor( 1, 1, 1 )
        coupons[lastC]:insert(txtSubtitle2)
    end
    
    -- Guardamos la ultima posicion
    lastY = lastY + 350
    
end

-- Genera un cupon estandar
function setStdCoupon(obj)
    -- Obtiene el total de cupones de la tabla y agrega uno
    local lastC = #coupons + 1
    
    -- Generamos contenedor
    coupons[lastC] = display.newContainer( 442, 167 )
    coupons[lastC].index = lastC
    coupons[lastC].x = midW
    coupons[lastC].type = 2
    coupons[lastC].y = lastY + 105
    scrollView:insert( coupons[lastC] )
    coupons[lastC]:addEventListener( "tap", showCoupon )
    
    -- Agregamos rectangulo alfa al pie
    local maxShape = display.newRect( 0, 0, 480, 169 )
    maxShape:setFillColor( .7 )
    coupons[lastC]:insert( maxShape )
    local rShape = display.newRect( 110, 0, 218, 166 )
    rShape:setFillColor( {
        type = 'gradient',
        color1 = { 1 }, 
        color2 = { .95 },
        direction = "up"
    } )
    coupons[lastC]:insert( rShape )
    
    -- Agregamos imagen
    imageItems[obj.id].alpha = 1
    imageItems[obj.id].index = lastC
    imageItems[obj.id].x= -110
    imageItems[obj.id].width = 220
    imageItems[obj.id].height  = 165
    coupons[lastC]:insert( imageItems[obj.id] )
    
    -- Agregamos textos
    local txtTitle = display.newText( {
        text = obj.title,     
        x = 110,
        y = -35,
        width = 200,
        height =60,
        font = "Chivo",   
        fontSize = 22,
        align = "center"
    })
    txtTitle:setFillColor( 0, .54, 0 )
    coupons[lastC]:insert(txtTitle)
    
     -- Agregamos textos
    if obj.type == 2 then
        local txtSubtitle1 = display.newText( obj.dateMax, 110, 45, 200, 46, "Chivo", 18)
        txtSubtitle1:setFillColor( 0, 0, 0 )
        coupons[lastC]:insert(txtSubtitle1)
        local txtSubtitle2 = display.newText( obj.subtitle1 .. ', ' .. obj.subtitle2, 110, 62, 200, 23, "Chivo", 18)
        txtSubtitle2:setFillColor( 0, 0, 0 )
        coupons[lastC]:insert(txtSubtitle2)
    elseif obj.type == 3 or obj.type == 4 then
        local txtSubtitle1 = display.newText( obj.partnerName, 110, 45, 200, 46, "Chivo", 20)
        txtSubtitle1:setFillColor( 0, 0, 0 )
        coupons[lastC]:insert(txtSubtitle1)
        local txtSubtitle2 = display.newText( obj.cityName, 110, 62, 200, 23, "Chivo", 18)
        txtSubtitle2:setFillColor( 0, 0, 0 )
        coupons[lastC]:insert(txtSubtitle2)
    end
    
    -- Agregamos linea negra al pie
    scrollView:insert( coupons[lastC] )
    
    -- Guardamos la ultima posicion
    lastY = lastY + 177
    
end

-- Limpiamos imagenes con 15 dias de descarga
local function clearTempDir()
    local lfs = require "lfs"
    local doc_path = system.pathForFile( "", system.TemporaryDirectory )
    local destDir = system.TemporaryDirectory  -- where the file is stored
    local lastTwoWeeks = os.time() - 1209600

    for file in lfs.dir(doc_path) do
        -- file is the current file or directory name
        local file_attr = lfs.attributes( system.pathForFile( file, destDir  ) )
        -- Elimina despues de 2 semanas
        if file_attr.modification < lastTwoWeeks then
           os.remove( system.pathForFile( file, destDir  ) ) 
        end
    end
end

local function clsAds(event)
    t = event.target
    t:setFillColor( .5 )
    timer.performWithDelay( 500, function()
        t:setFillColor( 0 )
    end, 1 )
    DBManager.clsAds()
end



---------------------------------------------------------------------------------
-- OVERRIDING SCENES METHODS
---------------------------------------------------------------------------------
-- Called when the scene's view does not exist:
function scene:createScene( event )
    -- Agregamos el home
	local screenGroup = self.view
    screenGroup:insert(homeScreen)
    
    -- Gradiente del toolbar
    local titleGradient = {
        type = 'gradient',
        color1 = { .1, .1, .1, 1 }, 
        color2 = { .2, .2, .2, .8 },
        direction = "up"
    }
    
    -- Lista de Cupones
    svHeightY[1] = intH - (63 + h)
    scrollView = widget.newScrollView
    {
        left = 0,
        top = 65 + h,
        width = intW+2,
        height = svHeightY[1],
        id = "onBottom",
        friction = .8,
        horizontalScrollDisabled = true,
        verticalScrollDisabled = false,
        listener = scrollListener,
        backgroundColor = { 0.8, 0.8, 0.8 }
    }
    homeScreen:insert(scrollView)
    svHeightY[2] = scrollView.y
    
    -- Creamos toolbar
    local titleBar = display.newRect( display.contentCenterX, h, display.contentWidth, 65 )
    titleBar.anchorY = 0;
    titleBar:setFillColor( 0 ) 
	homeScreen:insert(titleBar)
    
    local lineBar = display.newRect( display.contentCenterX, 63 + h, display.contentWidth, 5 )
    lineBar:setFillColor({
        type = 'gradient',
        color1 = { 0, 1, 0, 1 }, 
        color2 = { 0, .5, 0, .5 },
        direction = "bottom"
    }) 
    homeScreen:insert(lineBar)
    
    btnMenu = display.newImage("img/btn/btnMenuGo.png", true) 
	btnMenu.x = 35
	btnMenu.y = 30 + h
	homeScreen:insert(btnMenu)
    btnMenu:addEventListener( "tap", showMenu )
    
    -- Temporal notification
    bgNav = display.newRect(homeScreen, 230, 30 + h, 80, 40 )
    bgNav:setFillColor( 0 )
    bgNav:addEventListener( "tap", clsAds )
    
    title = display.newText( "", 230, 30 + h, "Chivo", 22)
    title:setFillColor( .8, .8, .8 )
    homeScreen:insert(title)
    
    filter = display.newImage("img/btn/btnMenuFilter.png", true) 
	filter.x = intW - 95
	filter.y = 30 + h
    filter.alpha = .5
	homeScreen:insert(filter)
    filter:addEventListener( "tap", showMenuFilter )
    
    local btnMenuR = display.newImage("img/btn/btnMenuGo.png", true) 
	btnMenuR.x = intW - 35
	btnMenuR.y = 30 + h
	homeScreen:insert(btnMenuR)
    btnMenuR:addEventListener( "tap", showMenuR )
    
    -- Navigation Days
    navGrp = display.newGroup()
    homeScreen:insert(navGrp)
    
    local bgTopAgenda = display.newImage(navGrp, "img/btn/bgTopAgenda.jpg", true) 
    bgTopAgenda.anchorY = 0
	bgTopAgenda.x = midW
	bgTopAgenda.y =  (65 + h)
    
    titleNav = display.newText( "", 240, 100 + h, "Chivo", 22)
    titleNav:setFillColor( 1 )
    navGrp:insert(titleNav)
    
    
    navArrowL = display.newImage(navGrp, "img/btn/navArrowL.png", true) 
	navArrowL.x = 45
	navArrowL.y = (100 + h)
    navArrowL:addEventListener( "tap", agendaL )
    
    local navArrowR = display.newImage(navGrp, "img/btn/navArrowR.png", true) 
	navArrowR.x = intW - 45
	navArrowR.y = (100 + h)
    navArrowR:addEventListener( "tap", agendaR )
    
    -- Creamos la mascara
    mask = display.newRect( display.contentCenterX, display.contentCenterY, intW, intH )
    mask:setFillColor( 0, 0, 0)
    mask.alpha = 0
    homeScreen:insert(mask)
    mask:addEventListener( "tap", hideMenu )
    
    -- Create filtro
    subMenuGrp = display.newGroup()
    homeScreen:insert(subMenuGrp)
    bgFloatMenu = display.newRoundedRect( intW - 120, (65 + h), 260, 400, 10 )
    bgFloatMenu.anchorY = 0
    subMenuGrp.alpha = 0
    bgFloatMenu:setFillColor( 0 ) 
	subMenuGrp:insert(bgFloatMenu)
    
    local filterTmp = display.newImage(subMenuGrp, "img/btn/btnMenuFilter.png", true) 
	filterTmp.x = intW - 95
	filterTmp.y = 30 + h
    
    -- Menu Derecho
    menuRGrp = display.newGroup()
    homeScreen:insert(menuRGrp)
    local bgFloatMenuR = display.newRoundedRect(menuRGrp, intW - 90, (65 + h), 200, 190, 10 )
    bgFloatMenuR.anchorY = 0
    menuRGrp.alpha = 0
    bgFloatMenuR:setFillColor( 0 ) 
    
    local menuGoTmp = display.newImage(menuRGrp, "img/btn/btnMenuGo.png", true) 
	menuGoTmp.x = intW - 35
	menuGoTmp.y = 30 + h
    
    bgSubMenuR[1] = display.newRect(menuRGrp, intW - 90, (95 + h), 180, 50 )
    bgSubMenuR[1]:setFillColor( .2 ) 
    bgSubMenuR[1].alpha = .1
    bgSubMenuR[1].type = 'Favoritos'
    bgSubMenuR[1]:addEventListener( "tap", showFav )
    local imgR1 = display.newImage(menuRGrp, "img/btn/btnMenuStar.png", true) 
    imgR1.x, imgR1.y = intW - 145, (95 + h)
    local descR1 = display.newText( menuRGrp, "Favoritos", intW - 60, (95 + h), 100, 18, "Chivo", 16)
    descR1:setFillColor( .8, .8, .8 )
    local lineR1 = display.newRect(menuRGrp, intW - 90, (95 + h) + 30, 150, 1 )
    lineR1.alpha = .5
    
    bgSubMenuR[2] = display.newRect(menuRGrp, intW - 90, (155 + h), 180, 50 )
    bgSubMenuR[2]:setFillColor( .2 ) 
    bgSubMenuR[2].alpha = .1
    bgSubMenuR[2].type = 'Busqueda'
    bgSubMenuR[2]:addEventListener( "tap", showComer )
    local imgR2 = display.newImage(menuRGrp, "img/btn/btnMenuSearch.png", true) 
    imgR2.x, imgR2.y = intW - 145, (155 + h)
    local descR2 = display.newText( menuRGrp, "Comercios", intW - 60, (155 + h), 100, 18, "Chivo", 16)
    descR2:setFillColor( .8, .8, .8 )
    local lineR2 = display.newRect(menuRGrp, intW - 90, (155 + h) + 30, 150, 1 )
    lineR2.alpha = .5
    
    bgSubMenuR[3] = display.newRect(menuRGrp, intW - 90, (215 + h), 180, 50 )
    bgSubMenuR[3]:setFillColor( .2 ) 
    bgSubMenuR[3].alpha = .1
    bgSubMenuR[3].type = 'Mapa'
    bgSubMenuR[3]:addEventListener( "tap", getMenuR )
    local imgR3 = display.newImage(menuRGrp, "img/btn/btnMenuMapa.png", true) 
    imgR3.x, imgR3.y = intW - 145, (215 + h)
    local descR3 = display.newText( menuRGrp, "Cerca de Mi", intW - 60, (215 + h), 100, 18, "Chivo", 16)
    descR3:setFillColor( .8, .8, .8 )
    
    --Creamos la pantalla del Menu
    settings = DBManager.getSettings()
    menuScreen:builScreen(settings)
    
    -- Loading
    loadingGrp = display.newGroup()
    homeScreen:insert(loadingGrp)
    local sheet = graphics.newImageSheet(Sprites.loading.source, Sprites.loading.frames)
    loading = display.newSprite(sheet, Sprites.loading.sequences)
    loading.x = midW
    loading.y = midH 
    loadingGrp:insert(loading)
    titleLoading = display.newText( "", midW, midH+50, "Chivo", 16)
    titleLoading:setFillColor( .3, .3, .3 )
    loadingGrp:insert(titleLoading)
    
    clearTempDir()
    if networkConnection(true) then
        RestManager.getSubmenus()
        RestManager.getAds()
        if Globals.idDisplay == 0 then
            title.text = "Agenda"
            loadBy(1)
        else
            loadComercio(Globals.idDisplay)
        end
    end
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    storyboard.removeAll()
end

-- Remove Listener
function scene:exitScene( event )
    Runtime:removeEventListener( "key", onKeyEvent )
end

local function onKeyEvent( event )
    local phase = event.phase
    local keyName = event.keyName
    if ( "back" == keyName and phase == "up" ) then
        showMenu()
        return true
    end
end
Runtime:addEventListener( "key", onKeyEvent )

scene:addEventListener("createScene", scene )
scene:addEventListener("enterScene", scene )
scene:addEventListener("exitScene", scene )

return scene

