Menu = {}

function Menu:new()
    -- Variables
    local self = display.newGroup()
    local menuTipo = {}
    local groups = {}
    local fxTap = audio.loadSound( "fx/click.wav")
    
    local opts = {
        {'btnMenuAll', 'Todo'},   --  Opcion Todo
        {'btnMenuEventos', 'Eventos'},   --  Opcion Eventos
        {'btnMenuEntretenimiento', 'Entretenimiento'},   --  Opcion Entretenimiento
        {'btnMenuProductos', 'Productos y Servicios'},   --  Opcion Productos
        {'btnMenuAdondeir', '¿Adonde ir?'},   --  Opcion Adondeir
        {'btnMenuSporttv', 'Sport TV'},   --  Opcion Sporttv
        {'btnMenuFood', 'Directorio Culinario'},   --  Opcion Extra
        {'btnMenuLogout', 'Cerrar Sesión'}   --  Cerrar Sesion
    }
    
    function getSubMenu(event)
        local sub = event.target
        if sub.isUp then
            sub.isUp = false
            sub:setSequence("down")
            sub:play()
            transition.to( groups[sub.sub], { time=500, height=0, y=groups[sub.sub].y - 125 } )
            for z = sub.sub + 1, 7, 1 do 
                transition.to( groups[z], { time=500, y=groups[z].y - 255 } )
            end
        else
            sub.isUp = true
            sub:setSequence("up")
            sub:play()
            transition.to( groups[sub.sub], { time=500, height=250, y=groups[sub.sub].y + 125 } )
            for z = sub.sub + 1, 7, 1 do 
                transition.to( groups[z], { time=500, y=groups[z].y + 255 } )
            end
        end
    end
    
    function tapMenu(event)
        -- Print color menu
        local menu = event.target
        
        -- Abrir opcion
        audio.play(fxTap)
        for z = 1, #menuTipo, 1 do 
            if menuTipo[z].alpha > .2 then menuTipo[z].alpha = .1 end
        end
        menu.alpha = .3
        -- Show Text
        changeTitle(opts[menu.type][2])
        -- Show Data
        timer.performWithDelay( 500, function()
            -- Do things
            hideMenu()
            hideFilter()
                
            if menu.type == 3 or menu.type == 4 then
                showFilter()
                loadCouponFilter(menu.type)
            end
                
            -- Load data
            if menu.type == 7 then
                showFilter()
                loadDirectory()
            elseif menu.type == 8 then -- Cerrar session
                timer.performWithDelay( 500, function() logout() end, 1)
            else
                loadBy(menu.type)
            end
        end, 1 )
    end
    
    function userData(settings)
        -- Agregamos avatar
        local function networkListenerFB( event )
            -- Verificamos el callback activo
            if ( event.isError ) then
            else
                local mask = graphics.newMask( "img/bgk/maskAvatar.jpg" )
                event.target.x = 90
                event.target.y = 120
                event.target:setMask( mask )
                scrollMenu:insert( event.target )
            end
        end
        print("http://graph.facebook.com/".. settings.fbId .."/picture?type=normal")
        display.loadRemoteImage( "http://graph.facebook.com/".. settings.fbId .."/picture?type=large&width=120&height=120", 
            "GET", networkListenerFB, "avatarFb", system.TemporaryDirectory ) 
        
        local txt1 = display.newText( settings.name, 270, 105, 200, 27, "Chivo", 24)
        txt1:setFillColor( 1, 1, 1 )
        scrollMenu:insert(txt1)
        local txt2 = display.newText( settings.email, 270, 130, 200, 20, "Chivo", 15)
        txt2:setFillColor( 1, 1, 1 )
        scrollMenu:insert(txt2)
    end
    
    -- Creamos la pantalla del menu
    function self:builScreen(settings)
        -- Variables
        local lastY = 210;
        local intW = display.contentWidth
        local intH = display.contentHeight
        local midW = display.contentCenterX
        local midH = display.contentCenterY
        local Sprites = require('src.resources.Sprites')
        local widget = require( "widget" )
        -- Colocamos el menu a la izquierda
        self.x = -400
        
        -- Background
        local background = display.newImage("img/bgk/menu.jpg", true) 
        background.anchorX = 0 
        background.anchorY = 0 
        background.x = 0
        background.y = 0
        self:insert(background)
        
        -- Lista de Cupones
        scrollMenu = widget.newScrollView
        {
            left = 0,
            top = 0,
            width = 400,
            height = intH + 5,
            id = "scrollMenu",
            horizontalScrollDisabled = true,
            verticalScrollDisabled = false,
            listener = scrollListener,
            hideBackground = true
        }
        self:insert(scrollMenu)
        
        -- Add user data
        if not (settings.fbId == '') then
            userData(settings)
        else
            lastY = 108;
        end
        
        -- Opciones basicas del menu
        for z = 1, #opts, 1 do 
            groups[z] = display.newContainer( 400, 68 )
            groups[z].x = 200
            groups[z].y = lastY + 30
            scrollMenu:insert( groups[z] )
            -- Agregamos rectangulo alfa al pie
            local shape = display.newRect( 0, 0, 400, 68 )
            shape:setFillColor( 0, 0, 0 )
            shape:addEventListener( "tap", tapMenu )
            shape.type = z
            menuTipo[z] = shape
            groups[z]:insert( shape )
            -- Select first item
            if z == 1 then shape.alpha = .3
            else shape.alpha = .1 end
            -- Agregamos imagen
            local img = display.newImage("img/btn/"..opts[z][1]..".png")
            img.x = (-155)
            groups[z]:insert( img )
            -- Agregamos Texto
            local txt = display.newText( opts[z][2], 55, 15, 350, 60, "Chivo", 26)
            txt:setFillColor( 1, 1, 1 )
            groups[z]:insert(txt)
            
            lastY = lastY + 70
            if z == 7 then
                lastY = lastY + 15
            elseif z == #opts then
                local txt = display.newText( " ", 100, lastY + 100, "Chivo", 12)
                scrollMenu:insert( txt )
            end
            
        end 
        
        -- Border Right
        local borderRight = display.newRect( 398, midH, 4, intH )
        borderRight:setFillColor( {
            type = 'gradient',
            color1 = { .1, .1, .1, .7 }, 
            color2 = { .4, .4, .4, .2 },
            direction = "left"
        } ) 
        borderRight:setFillColor( 0, 0, 0 ) 
        self:insert(borderRight)
        
    end

    return self
end