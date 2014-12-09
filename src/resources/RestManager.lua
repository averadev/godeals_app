--Include sqlite
local RestManager = {}

	local mime = require("mime")
    local json = require("json")
    local crypto = require("crypto")
    local DBManager = require('src.resources.DBManager')
    local Globals = require('src.resources.Globals')

    function urlencode(str)
          if (str) then
              str = string.gsub (str, "\n", "\r\n")
              str = string.gsub (str, "([^%w ])",
              function ( c ) return string.format ("%%%02X", string.byte( c )) end)
              str = string.gsub (str, " ", "%%20")
          end
          return str    
    end

	--Open rackem.db.  If the file doesn't exist it will be created
	RestManager.getCoupons = function()
        local settings = DBManager.getSettings()
        -- Set url
	    local url = settings.url
        url = url.."api/getCoupons/format/json"
        url = url.."/idApp/"..settings.idApp
    
        local function callback(event)
            if ( event.isError ) then
                
            else
                local data = json.decode(event.response)
                DBManager.saveCoupons(data.coupons)
                -- do with data what you want...
            end
            return true
        end
    
        -- Do request
        network.request( url, "GET", callback ) 
	end

    RestManager.getByDate = function(add)
        if networkConnection(true) then
            local settings = DBManager.getSettings()
            -- Set url
            local url = settings.url
            url = url.."api/getByDate/format/json"
            url = url.."/idApp/"..settings.idApp
            url = url.."/next/"..add
            
            local function callback(event)
                if ( event.isError ) then
                else
                    local data = json.decode(event.response)
                    if #data.items == 0 then
                        -- emptyFav()
                    else
                        loadTxtBanner(data.dateFormat)
                        loadImages(data.items)
                    end
                end
                return true
            end
            -- Do request
            network.request( url, "GET", callback )  
        end
	end

	RestManager.getItems = function(type, subtype)
        if networkConnection(true) then
            local settings = DBManager.getSettings()
            -- Set url
            local url = settings.url
            url = url.."api/getItems/format/json"
            url = url.."/idApp/"..settings.idApp
            url = url.."/type/"..type
            if not (subtype == nil) then
                url = url.."/subtype/"..subtype
            end

            local function callback(event)
                if ( event.isError ) then
                    native.showAlert( "Go Deals", event.isError, { "OK"})
                else
                    local data = json.decode(event.response)
                    if data.success then
                        if #data.items == 0 then
                            emptyPage()
                        else
                            loadImages(data.items)
                        end
                    else
                        native.showAlert( "Go Deals", data.message, { "OK"})
                    end
                end
                return true
            end
            -- Do request
            network.request( url, "GET", callback )  
        end
	end

	RestManager.getServices = function(type)
        local settings = DBManager.getSettings()
        -- Set url
        local url = settings.url
        url = url.."api/getServices/format/json"
        url = url.."/idApp/"..settings.idApp

        local function callback(event)
            if ( event.isError ) then
                native.showAlert( "Go Deals", event.isError, { "OK"})
            else
                local data = json.decode(event.response)
                if data.success then
                    loadMapIcons(data.items)
                else
                    native.showAlert( "Go Deals", data.message, { "OK"})
                end
            end
            return true
        end
        -- Do request
        network.request( url, "GET", callback ) 
	end

    RestManager.createUser = function(email, password, name, fbId)
        local settings = DBManager.getSettings()
        -- Set url
        password = crypto.digest(crypto.md5, password)
        local url = settings.url
        url = url.."api/createUser/format/json"
        url = url.."/email/"..urlencode(email)
        url = url.."/password/"..password
        url = url.."/name/"..urlencode(name)
        url = url.."/fbId/"..fbId
        
        local function callback(event)
            if ( event.isError ) then
            else
                hideLoadLogin()
                local data = json.decode(event.response)
                if data.success then
                    DBManager.updateUser(data.idApp, email, password, name, fbId)
                    gotoHome()
                else
                    native.showAlert( "Go Deals", data.message, { "OK"})
                end
            end
            return true
        end
        -- Do request
        network.request( url, "GET", callback ) 
    end

    RestManager.validateUser = function(email, password)
        local settings = DBManager.getSettings()
        -- Set url
        password = crypto.digest(crypto.md5, password)
        local url = settings.url
        url = url.."api/validateUser/format/json"
        url = url.."/idApp/"..settings.idApp
        url = url.."/email/"..urlencode(email)
        url = url.."/password/"..password
    
        local function callback(event)
            if ( event.isError ) then
            else
                hideLoadLogin()
                local data = json.decode(event.response)
                if data.success then
                    gotoHome()
                else
                    native.showAlert( "Go Deals", data.message, { "OK"})
                end
            end
            return true
        end
        -- Do request
        network.request( url, "GET", callback ) 
    end

    RestManager.setFav = function(id, typeId, status)
        local settings = DBManager.getSettings()
        -- Set url
	    local url = settings.url
        url = url.."api/setFav/format/json"
        url = url.."/idApp/"..settings.idApp
        url = url.."/couponId/"..id
        url = url.."/typeId/"..typeId
        url = url.."/status/"..status
        
        local function callback(event)
            return true
        end
    
        -- Do request
        network.request( url, "GET", callback ) 
    end

    RestManager.getFav = function()
        if networkConnection(true) then
            local settings = DBManager.getSettings()
            -- Set url
            local url = settings.url
            url = url.."api/getFav/format/json"
            url = url.."/idApp/"..settings.idApp

            local function callback(event)
                if ( event.isError ) then
                else
                    local data = json.decode(event.response)
                    if #data.items == 0 then
                        emptyFav()
                    else
                        loadImages(data.items)
                    end
                end
                return true
            end
            -- Do request
            network.request( url, "GET", callback )  
        end
	end

    RestManager.getAds = function()
        if networkConnection(true) then
            local settings = DBManager.getSettings()
            -- Set url
            local url = settings.url
            url = url.."api/getAds/format/json"
            url = url.."/idApp/"..settings.idApp

            local function callback(event)
                if ( event.isError ) then
                else
                    local data = json.decode(event.response)
                    DBManager.saveAds(data.items)
                end
                return true
            end
            -- Do request
            network.request( url, "GET", callback )  
        end
	end

    RestManager.getComer = function()
        if networkConnection(true) then
            local settings = DBManager.getSettings()
            -- Set url
            local url = settings.url
            url = url.."api/getComer/format/json"
            url = url.."/idApp/"..settings.idApp

            local function callback(event)
                if ( event.isError ) then
                else
                    local data = json.decode(event.response)
                    if #data.items == 0 then
                        emptyFav()
                    else
                        loadImages(data.items)
                    end
                end
                return true
            end
            -- Do request
            network.request( url, "GET", callback )  
        end
	end

    RestManager.getComercio = function(idComer)
        if networkConnection(true) then
            local settings = DBManager.getSettings()
            -- Set url
            local url = settings.url
            url = url.."api/getComercio/format/json"
            url = url.."/idApp/"..settings.idApp
            url = url.."/idComer/"..idComer

            local function callback(event)
                if ( event.isError ) then
                else
                    local data = json.decode(event.response)
                    -- Print header
                    loadComerio(data.comercio)
                    -- Print items
                    Globals.Directory = data.items
                    if  #data.items > 0 then
                        loadImages(data.items)
                    end
                end
                return true
            end
            -- Do request
            network.request( url, "GET", callback )  
        end
	end

    RestManager.getDirectory = function()
        if networkConnection(true) then
            local settings = DBManager.getSettings()
            -- Set url
            local url = settings.url
            url = url.."api/getDirectory/format/json"
            url = url.."/idApp/"..settings.idApp

            local function callback(event)
                if ( event.isError ) then
                else
                    local data = json.decode(event.response)
                    Globals.Directory = data.items
                    loadDirectory()
                end
                return true
            end
            -- Do request
            network.request( url, "GET", callback )  
        end
	end

    RestManager.getSubmenus = function()
        local settings = DBManager.getSettings()
        -- Set url
	    local url = settings.url
        url = url.."api/getSubmenus/format/json"
        url = url.."/idApp/"..settings.idApp
        
        local function callback(event)
            if ( event.isError ) then
            else
                local data = json.decode(event.response)
                Globals.DirectoryType = data.directoryType
                Globals.CouponType1 = data.couponType1
                Globals.CouponType2 = data.couponType2
            end
            return true
        end
        -- Do request
        network.request( url, "GET", callback )  
	end

    

return RestManager