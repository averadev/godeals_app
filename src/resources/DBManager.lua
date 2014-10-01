--Include sqlite
local dbManager = {}

	require "sqlite3"
	local path, db

	--Open rackem.db.  If the file doesn't exist it will be created
	local function openConnection( )
	    path = system.pathForFile("godeals.db", system.DocumentsDirectory)
	    db = sqlite3.open( path )     
	end

	local function closeConnection( )
		if db and db:isopen() then
			db:close()
		end     
	end
	 
	--Handle the applicationExit event to close the db
	local function onSystemEvent( event )
	    if( event.type == "applicationExit" ) then              
	        closeConnection()
	    end
	end

	dbManager.getSettings = function()
		local result = {}
		openConnection( )
		for row in db:nrows("SELECT * FROM config;") do
			closeConnection( )
			return  row
		end
		closeConnection( )
		return 1
	end

	dbManager.saveCoupons = function(coupons)
		openConnection( )
        -- Delete old coupons
        query = "DELETE FROM coupons;"
        db:exec( query )
        -- Insert new coupons
        for z = 1, #coupons, 1 do 
            query = "INSERT INTO coupons (id, image, description)"
            query = query.." VALUES ('"..coupons[z].id.."', '"..coupons[z].image.."', '"..coupons[z].description.."');"
            db:exec( query )
        end
    
		closeConnection( )
		return 1
	end

    dbManager.updateUser = function(email, password, name, fbId)
		openConnection( )
        local query = ''
        if fbId == '' then
            query = "UPDATE config SET email = '"..email.."', password = '"..password.."';"
        else
            query = "UPDATE config SET email = '"..email.."', name = '"..name.."', fbId = '"..fbId.."';"
        end
        db:exec( query )
		closeConnection( )
	end

    dbManager.clearUser = function()
        openConnection( )
        query = "UPDATE config SET email = '', password = '', name = '', fbId = '';"
        db:exec( query )
		closeConnection( )
    end

	--Setup squema if it doesn't exist
	dbManager.setupSquema = function()
		openConnection( )
		
		local query = "CREATE TABLE IF NOT EXISTS config (id INTEGER PRIMARY KEY, email TEXT, password TEXT, name TEXT, fbId TEXT, url TEXT);"
		db:exec( query )

        -- Return if have connection
		for row in db:nrows("SELECT email, fbId FROM config;") do
            closeConnection( )
            if row.email == '' and row.fbId == '' then
                return false
            else
                return true
            end
		end
    
        -- Coupon table
        query = "CREATE TABLE IF NOT EXISTS coupons (id INTEGER PRIMARY KEY, image TEXT, partner TEXT, "
		query = query .. "description TEXT, validity TEXT, fav INTEGER);"
		db:exec( query )
        
        -- Populate config
        query = "INSERT INTO config VALUES (1,'', '', '', '', 'http://192.168.1.198/godeals/');"
        
		db:exec( query )
    
		closeConnection( )
    
        return false
	end
	

	--setup the system listener to catch applicationExit
	Runtime:addEventListener( "system", onSystemEvent )
    

return dbManager