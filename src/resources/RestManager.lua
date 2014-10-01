--Include sqlite
local RestManager = {}

	local mime = require("mime")
    local json = require("json")
    local crypto = require("crypto")
    local DBManager = require('src.resources.DBManager')

	--Open rackem.db.  If the file doesn't exist it will be created
	RestManager.getCoupons = function()
        local settings = DBManager.getSettings()
        -- Set url
	    local url = settings.url
        url = url.."api/getCoupons/format/json"
        url = url.."/email/"..settings.email
    
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

	RestManager.getItems = function(type, subtype)
        local settings = DBManager.getSettings()
        -- Set url
	    local url = settings.url
        url = url.."api/getItems/format/json"
        url = url.."/email/"..settings.email
        url = url.."/type/"..type
        if not (subtype == nil) then
            url = url.."/subtype/"..subtype
        end
        url = string.gsub(url, "%@", "%%40")
        
        local function callback(event)
            if ( event.isError ) then
                native.showAlert( "Go Deals", event.isError, { "OK"})
            else
                local data = json.decode(event.response)
                if data.success then
                    if (type==3 or type==4) and subtype == nil then loadSubmenu(data.submenu, type) end
                    loadImages(data.items)
                else
                    native.showAlert( "Go Deals", data.message, { "OK"})
                end
            end
            return true
        end
        -- Do request
        network.request( url, "GET", callback )  
	end

	RestManager.getServices = function(type)
        local settings = DBManager.getSettings()
        -- Set url
	    local url = settings.url
        url = url.."api/getServices/format/json"
        url = url.."/email/"..settings.email
        url = string.gsub(url, "%@", "%%40")
    
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
        url = url.."/email/"..email
        url = url.."/password/"..password
        url = url.."/name/"..name
        url = url.."/fbId/"..fbId
        url = string.gsub(url, "%@", "%%40")
        url = string.gsub(url, " ", "%%20")
        
        local function callback(event)
            if ( event.isError ) then
                native.showAlert( "Go Deals", event.isError, { "OK"})
            else
                local data = json.decode(event.response)
                if data.success then
                    DBManager.updateUser(email, password, name, fbId)
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
        url = url.."/email/"..email
        url = url.."/password/"..password
        url = string.gsub(url, "%@", "%%40")
    
        local function callback(event)
            if ( event.isError ) then
                native.showAlert( "Go Deals", event.isError, { "OK"})
            else
                local data = json.decode(event.response)
                if data.success then
                    DBManager.updateUser(email, password, '', '')
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

    

return RestManager