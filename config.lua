---------------------------------------------------------------------------------
-- Birdz Videogame
-- Alberto Vera
-- GeekBucket Software Factory
---------------------------------------------------------------------------------

local mediaRes = display.pixelWidth  / 480

application = {
	content = {
		width = display.pixelWidth / mediaRes,
        height = display.pixelHeight / mediaRes, 
        scale = "letterBox",

        imageSuffix = {
            ["-small"] = 0.375,
            ["@2x"] = 1.5
        }
	}
}
