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

	dbManager.getIdComer = function()
		local result = {}
		openConnection( )
		for row in db:nrows("SELECT * FROM config;") do
            local idComer = tonumber(row.idComer)
			if idComer > 0 then
                query = "UPDATE config SET idComer = 0"
                db:exec( query )
            end
		    closeConnection( )
			return  row.idComer
		end
		closeConnection( )
		return 0
	end

    dbManager.updateIdComer = function(idComer)
		openConnection( )
        local query = ''
        query = "UPDATE config SET idComer = "..idComer
        db:exec( query )
		closeConnection( )
	end

    dbManager.updateUser = function(idApp, email, password, name, fbId)
		openConnection( )
        local query = ''
        if fbId == '' then
            query = "UPDATE config SET idApp = "..idApp..", email = '"..email.."', password = '"..password.."', idComer = 0;"
        else
            query = "UPDATE config SET idApp = "..idApp..", email = '"..email.."', name = '"..name.."', fbId = '"..fbId.."', idComer = 0;"
        end
        db:exec( query )
		closeConnection( )
	end

    dbManager.clearUser = function()
        openConnection( )
        query = "UPDATE config SET idApp = 0, email = '', password = '', name = '', fbId = '';"
        db:exec( query )
		closeConnection( )
    end
    
	dbManager.saveAds = function(items)
		openConnection( )
    
        -- Delete all
        query = "DELETE FROM ads WHERE status = 1;"
        db:exec( query )
    
        for row in db:nrows("SELECT id FROM ads;") do
            for z = 1, #items, 1 do 
                print(items[z].id.." - "..row.id)
                if tonumber(items[z].id) == tonumber(row.id) then
                    items[z] = nil;
                end
            end
		end
    
        -- Save update
        for z = 1, #items, 1 do 
            if not (items[z] == nil) then
                query = "INSERT INTO ads VALUES ("
                        ..items[z].id..",'"
                        ..items[z].message.."','"
                        ..items[z].uuid.."','"
                        ..items[z].latitude.."','"
                        ..items[z].longitude.."', 1);"
                db:exec( query )
            end
        end
    
		closeConnection( )
		return 1
	end

	--Setup squema if it doesn't exist
	dbManager.setupSquema = function()
		openConnection( )
		
		local query = "CREATE TABLE IF NOT EXISTS config (id INTEGER PRIMARY KEY, idApp INTEGER, email TEXT, password TEXT, name TEXT, fbId TEXT, idComer TEXT, url TEXT);"
		db:exec( query )
    
        local query = "CREATE TABLE IF NOT EXISTS ads (id INTEGER PRIMARY KEY, message TEXT, uuid TEXT, latitude TEXT, longitude TEXT, status INTEGER);"
		db:exec( query )

        -- Return if have connection
		for row in db:nrows("SELECT idApp FROM config;") do
            closeConnection( )
            if row.idApp == 0 then
                return false
            else
                return true
            end
		end
        
        -- Populate config
        --query = "INSERT INTO config VALUES (1, 0, '', '', '', '', 0, 'http://192.168.1.197/godeals/');"
        query = "INSERT INTO config VALUES (1, 0, '', '', '', '', 0, 'http://godeals.mx/');"
        
		db:exec( query )
    
		closeConnection( )
    
        return false
	end
	

	--setup the system listener to catch applicationExit
	Runtime:addEventListener( "system", onSystemEvent )
    

return dbManager