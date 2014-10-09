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
local scrollView, menuGrp, subMenuGrp, restMenuGrp, settings, mask 
local btnMenu, loading, title, loadingGrp, NoConnGrp
local svHeightY = {}
local coupons = {}
local imageItems = {}
local submenu = {}
local submenuTxt = {}
local submenuline = {}
local submenuRest = {}
local noPackage = 1
local fxTap = audio.loadSound( "fx/click.wav")

-- Variables
local intW = display.contentWidth
local intH = display.contentHeight
local midW = display.contentCenterX
local midH = display.contentCenterY
local lastY = 0;
local noMax, noCou = 1, 1
local noCallback = 0
local isHome = true
local isBreak = false


---------------------------------------------------------------------------------
-- LISTENERS
---------------------------------------------------------------------------------
function showMenu(event)
    if isHome then
        isHome = false
        transition.to( homeScreen, { x = homeScreen.x + 400, time = 400, transition = easing.outExpo } )
        transition.to( menuScreen, { x = menuScreen.x + 400, time = 400, transition = easing.outExpo } )
        transition.to( mask, { alpha = .5, time = 400, transition = easing.outQuad } )
    end
end

function hideMenu(event)
    if not isHome and not isBreak then
        isBreak = true
        transition.to( homeScreen, { x = homeScreen.x - 400, time = 400, transition = easing.outExpo } )
        transition.to( menuScreen, { x = menuScreen.x - 400, time = 400, transition = easing.outExpo } )
        transition.to( mask, { alpha = 0, time = 400, transition = easing.outQuad } )
        timer.performWithDelay( 500, function()
            isHome = true
            isBreak = false
        end, 1 )
    end
end

function showCoupon(event)
    if isHome then
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
        hideRestMenus()
        cleanHome()
        hideSubmenu()
        noCallback = noCallback + 1
        RestManager.getFav()
        title.text = "Favoritos"
    end
end

function showMap(event)
    if isHome then
        storyboard.gotoScene( "src.Map", { time = 400, effect = "crossFade" })
    end
end

function doFilter(event)
    
end

function getSubMenu(event)
    local t = event.target
    if #submenu > #submenuline then
        submenuline[#submenuline + 1] = display.newRect( midW, midH, 80, 70 )
        submenuline[#submenuline].alpha = .2
        subMenuGrp:insert(submenuline[#submenuline])
    end
    submenuline[#submenuline].x = t.x
    submenuline[#submenuline].y = t.y
    
    -- Load option
    cleanHome()
    noCallback = noCallback + 1
    RestManager.getItems(t.type, t.subtype)
end

function getSubMenuRest(event)
    -- Alpha
    local t = event.target
    for z = 1, #submenuRest, 1 do 
        submenuRest[z].alpha = .01
    end
    t.alpha = .4
    
    -- Set new rows
    coupons[3].type = t.type
    coupons[1]:deleteAllRows()
    Globals.CurrentRest = Globals.Restaurantes[t.type]
    setRestaurants()
end

local function onRowRender( event )

   --Set up the localized variables to be passed via the event table
   local row = event.row
   local id = row.index
    
   row.nameText = display.newText( Globals.CurrentRest[id][1], 12, 0, "Chivo", 18 )
   row.nameText.anchorX = 0
   row.nameText.anchorY = 0.5
   row.nameText:setFillColor( 0 )
   row.nameText.y = 20
   row.nameText.x = 20

   row.phoneText = display.newText( Globals.CurrentRest[id][2], 12, 0, "Chivo", 18 )
   row.phoneText.anchorX = 0
   row.phoneText.anchorY = 0.5
   row.phoneText:setFillColor( 0.5 )
   row.phoneText.y = 40
   row.phoneText.x = 20

   row:insert( row.nameText )
   row:insert( row.phoneText )
   return true
end

function hideRestMenus()
    if restMenuGrp.x == 0 then
        coupons[1]:deleteAllRows()
        coupons[1]:removeSelf()
        coupons[1] = nil
        transition.to( restMenuGrp, { time=500, x = 160 } )
        transition.to( scrollView, { time=500, width = intW, x = midW } )
    end
end

function searchDir(event)
    -- Set new rows
    local noMenu = coupons[3].type
    coupons[1]:deleteAllRows()
    Globals.CurrentRest = {}
    local toFind = coupons[2].text:upper()
    for z = 1, #Globals.Restaurantes[noMenu], 1 do 
        if string.match(Globals.Restaurantes[noMenu][z][1]:upper(), toFind) then
            Globals.CurrentRest[#Globals.CurrentRest + 1 ] = Globals.Restaurantes[noMenu][z]
        end
    end
    setRestaurants()
end
function searchCancel(event)
    event.target.alpha = 0
    coupons[2].text = ''
    
    -- Set new rows
    typeS = coupons[3].type
    coupons[1]:deleteAllRows()
    Globals.CurrentRest = Globals.Restaurantes[typeS]
    setRestaurants()
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

---------------------------------------------------------------------------------
-- FUNCTIONS
---------------------------------------------------------------------------------

-- Cargamos por menu
function changeTitle(value)
    title.text = value
end

local function networkConnection()
    local netConn = require('socket').connect('www.google.com', 80)
    if netConn == nil then
        return false
    end
    netConn:close()
    return true
end

local function reloadConn()
    audio.play(fxTap)
    if networkConnection() then
        NoConnGrp.alpha = 0
        loadBy(1)
    end
end

function loadRestaurants()
    cleanHome()
    hideSubmenu()
    -- Stop Loading
    loadingGrp.alpha = 0
    loading:setSequence("stop")
    -- Show menu
    transition.to( restMenuGrp, { time=500, x = 0 } )
    transition.to( scrollView, { time=500, width = 320, x = 160 } )
    
    -- Create Table View
    coupons[1] = widget.newTableView {
        height = intH - 165,
        width = 320,
        left = 80,
        top = 60,
        onRowRender = onRowRender
    }
    scrollView:insert( coupons[1] )
    
    coupons[2] = native.newTextField(midW - 50, 30, 220, 60 )
    coupons[2].method = "search"
    coupons[2].hasBackground = false
    scrollView:insert( coupons[2] )
    coupons[2]:addEventListener( "userInput", onTxtSearch )
    
    coupons[3] = display.newImage("img/btn/btnSearch.png", true) 
    coupons[3].type = 1
    coupons[3].x = 370
    coupons[3].y = 30
    scrollView:insert( coupons[3] )
    coupons[3]:addEventListener( "tap", searchDir )
    
    coupons[4] = display.newImage("img/btn/btnClose.png", true) 
    coupons[4].x = 310
    coupons[4].y = 30
    coupons[4].alpha = 0
    scrollView:insert( coupons[4] )
    coupons[4]:addEventListener( "tap", searchCancel )
    
    -- Load
    for z = 1, #submenuRest, 1 do 
        submenuRest[z].alpha = .01
    end
    submenuRest[1].alpha = .4
    Globals.CurrentRest = Globals.Restaurantes[1]
    setRestaurants()
end

-- Obtenemos los datos de la web
function loadBy(type)
    hideRestMenus()
    cleanHome()
    hideSubmenu()
    noCallback = noCallback + 1
    RestManager.getItems(type)
end

-- Armamos el submenu
function loadSubmenu(items, type)
    if not(subMenuGrp.y == 0) then
        -- Show filter menu
        menuGrp.x = -60
        title.x = 230
        
        local spcIcn = ((6 - #items) * 40)
        for z = 1, #items, 1 do 
            local newX = ((z * 80) - 40) + spcIcn
            submenu[z] = display.newImage("img/btn/submenu".. items[z].id ..".png", true) 
            submenu[z].x = newX
            submenu[z].y = intH - 35
            submenu[z].type = type
            submenu[z].subtype = items[z].id
            submenu[z]:addEventListener( "tap", getSubMenu )
            subMenuGrp:insert(submenu[z])

            submenuTxt[z] = display.newText( Globals.CouponType[tonumber(items[z].id)], newX, intH - 18, "Chivo", 10)
            submenuTxt[z]:setFillColor( 1 )
            subMenuGrp:insert(submenuTxt[z]) 

            if z < #items then 
                submenuline[z] = display.newRect( newX + 40, intH - 35, 2, 70 )
                subMenuGrp:insert(submenuline[z])
            end

        end
        transition.to( subMenuGrp, { time=500, y = 0 } )
    end
end

-- Limpiamos botones y ocultamos la barra
function hideSubmenu()
    if subMenuGrp.x < 0 then
        -- Hide filter menu
        menuGrp.x = -60
        title.x = 255
        
        for z = 1, #submenu, 1 do 
            submenu[z]:removeEventListener( "tap", getSubMenu )
            submenu[z]:removeSelf()
            submenu[z] = nil
            submenuTxt[z]:removeSelf()
            submenuTxt[z] = nil
        end
        for z = 1, #submenuline, 1 do 
            submenuline[z]:removeSelf()
            submenuline[z] = nil
        end
        transition.to( subMenuGrp, { time=500, y = 70 } )
    end
end

-- Cargamos imagenes
function loadImages(items)
    Globals.Items = items
    for y = 1, #Globals.Items, 1 do 
        Globals.Items[y].callback = noCallback
    end
    loadImage(1)
end
function loadImage(posc)
    -- Listener loading
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
        if Globals.Items[z].fav == 1 or Globals.Items[z].fav == "1" then
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
    for z = 1, #imageItems, 1 do 
        imageItems[z]:removeSelf()
        imageItems[z] = nil
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
    -- Play loading
    loadingGrp.alpha = 1
    loading:setSequence("play")
    loading:play()
    -- Set scroll Top
    scrollView:scrollToPosition( { y = 0 } )
    -- Quitar escena de cupones
    storyboard.removeScene( "src.Coupon" )
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
    coupons[lastC] = display.newContainer( 444, 169 )
    coupons[lastC].index = lastC
    coupons[lastC].x = midW
    coupons[lastC].type = 2
    coupons[lastC].y = lastY + 110
    scrollView:insert( coupons[lastC] )
    coupons[lastC]:addEventListener( "tap", showCoupon )
    
    -- Agregamos rectangulo alfa al pie
    local maxShape = display.newRect( 0, 0, 480, 169 )
    maxShape:setFillColor( 1, 1, 1 )
    coupons[lastC]:insert( maxShape )
    
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
    txtTitle:setFillColor( .27, .54, 0 )
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
        local txtSubtitle1 = display.newText( obj.partnerName, 110, 45, 200, 46, "Chivo", 18)
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

function setRestaurants(rest)
    -- Set Rows
    for i = 1, #Globals.CurrentRest do

        local rowHeight = 70
        local rowColor = { default={ 1, 1, 1 }, over={ 1, 0.5, 0, 0.2 } }
        local lineColor = { 0.5, 0.5, 0.5 }
        
        -- Insert a row into the tableView
        coupons[1]:insertRow({
            rowHeight = rowHeight,
            rowColor = rowColor,
            lineColor = lineColor
        })
    end
end

---------------------------------------------------------------------------------
-- TIMERS
---------------------------------------------------------------------------------
function moveElements()
end

---------------------------------------------------------------------------------
-- OVERRIDING SCENES METHODS
---------------------------------------------------------------------------------
-- Called when the scene's view does not exist:
function scene:createScene( event )
    -- Agregamos el home
	local screenGroup = self.view
    screenGroup:insert(homeScreen)
    
    -- Height status bar
    local h = display.topStatusBarContentHeight
    
    -- Gradiente del toolbar
    local titleGradient = {
        type = 'gradient',
        color1 = { .1, .1, .1, 1 }, 
        color2 = { .2, .2, .2, .8 },
        direction = "up"
    }
    
    -- Lista de Cupones
    svHeightY[1] = intH - 63 + h
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
	btnMenu.x = 45
	btnMenu.y = 30 + h
	homeScreen:insert(btnMenu)
    btnMenu:addEventListener( "tap", showMenu )
    
    menuGrp = display.newGroup()
    homeScreen:insert(menuGrp)
    
    title = display.newText( "", 230, 30 + h, "Chivo", 22)
    title:setFillColor( .8, .8, .8 )
    menuGrp:insert(title)

    local fav = display.newImage("img/btn/btnMenuStar.png", true) 
	fav.x = intW - 90
	fav.y = 30 + h
	menuGrp:insert(fav)
    fav:addEventListener( "tap", showFav )

    local search = display.newImage("img/btn/btnMenuMapa.png", true) 
	search.x = intW - 30
	search.y = 30 + h
	menuGrp:insert(search)
    search:addEventListener( "tap", showMap )
    
    local filter = display.newImage("img/btn/btnMenuFilter.png", true) 
	filter.x = intW + 30
	filter.y = 30 + h
	menuGrp:insert(filter)
    filter:addEventListener( "tap", doFilter )
    
    -- Create submenu bar
    subMenuGrp = display.newGroup()
    homeScreen:insert(subMenuGrp)
    bottomBar = display.newRect( intW + 90, (65 + h), 160, intH - (65 + h) )
    bottomBar.anchorY = 0
    bottomBar:setFillColor( 0 ) 
	subMenuGrp:insert(bottomBar)
    
    -- Create Restaurant Menu
    local optsMenu = {
        'Cafeterias',
        'Comida Mexicana',
        'Comida Oriental',
        'Comida Europea',
        'Comida Rapida',
        'Comida Saludable',
        'Carnes y Cortes',
        'Pescados y Mariscos'
    }
    restMenuGrp = display.newGroup()
    homeScreen:insert(restMenuGrp)
    rightBar = display.newRect( intW - 80, midH + 52, 160, intH - 104 )
    rightBar:setFillColor( titleGradient ) 
	restMenuGrp:insert(rightBar)
    
    local spcMenu = (intH - 130) / #optsMenu
    for z = 1, #optsMenu, 1 do 
        local newY = (z * spcMenu) + 68
        local image = display.newImage("img/btn/btnRest".. z ..".png", true) 
        image.x = 350
        image.y = newY
        restMenuGrp:insert(image)
        
        submenuRest[z] = display.newRect( 400, newY, 160, spcMenu+2 )
        submenuRest[z].alpha = .01
        submenuRest[z].type = z
        restMenuGrp:insert(submenuRest[z])
        submenuRest[z]:addEventListener( "tap", getSubMenuRest )
        if z == 1 then submenuRest[z].alpha = .4 end
        
        if z < #optsMenu then 
            local line = display.newRect( 400, newY + (spcMenu/2), 120, 2 )
            line.alpha = .2
            restMenuGrp:insert(line)
        end
        
        local desc = display.newText( optsMenu[z], 430, newY + 2, 100, 40, "Chivo", 16)
        desc:setFillColor( .8, .8, .8 )
        restMenuGrp:insert(desc)
    end
    
    local borderLeft = display.newRect( 320, midH + 52, 4, intH -104 )
    borderLeft:setFillColor( {
        type = 'gradient',
        color1 = { .4, .4, .4, .2 }, 
        color2 = { .1, .1, .1, .7 },
        direction = "left"
    } ) 
    borderLeft:setFillColor( 0, 0, 0 ) 
    restMenuGrp:insert(borderLeft)
    restMenuGrp.x = 160
    
    -- Creamos la mascara
    mask = display.newRect( display.contentCenterX, display.contentCenterY, intW, intH )
    mask:setFillColor( 0, 0, 0)
    mask.alpha = 0
    homeScreen:insert(mask)
    mask:addEventListener( "tap", hideMenu )
    
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
    local title = display.newText( "Cargando, por favor espere...", midW, midH+50, "Chivo", 16)
    title:setFillColor( .3, .3, .3 )
    loadingGrp:insert(title)
    
    -- Sin conexion
    NoConnGrp = display.newGroup()
    homeScreen:insert(NoConnGrp)
    local robot = display.newImage("img/btn/robot.png", true) 
	robot.x = midW
	robot.y = midH
	NoConnGrp:insert(robot)
    local btnReload = display.newImage("img/btn/btnReloadCon.png", true) 
	btnReload.x = midW
	btnReload.y = midH + 130
	NoConnGrp:insert(btnReload)
    btnReload:addEventListener( "tap", reloadConn )
    local title2 = display.newText( "No se pudo conectar a Internet, volver a intentar.", midW, midH+130, "Chivo", 16)
    title2:setFillColor( .3, .3, .3 )
    NoConnGrp:insert(title2)
    NoConnGrp.alpha = 0
    
    clearTempDir()
    if networkConnection() then
        loadBy(5)
    else
        loadingGrp.alpha = 0
        NoConnGrp.alpha = 1
    end
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    storyboard.removeAll()
end

-- Remove Listener
function scene:exitScene( event )
end

scene:addEventListener("createScene", scene )
scene:addEventListener("enterScene", scene )
scene:addEventListener("exitScene", scene )

return scene

