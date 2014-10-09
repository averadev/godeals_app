
local Sprites = {}

Sprites.subMenu = {
  source = "img/btn/submenuArrow.png",
  frames = {width=40, height=40, numFrames=4},
  sequences = {
    { name = "stand", start = 1, count = 1, time=0},
    { name = "down", frames={ 2,3,4,5 }, loopCount=1, time=200},
    { name = "up", frames={ 3,2,1,0 }, loopCount=1, time=200}
  }
}

Sprites.loading = {
  source = "img/btn/loading.png",
  frames = {width=48, height=48, numFrames=8},
  sequences = {
      { name = "stop", loopCount = 1, start = 1, count=1},
      { name = "play", time=1000, start = 1, count=8}
  }
}

Sprites.fav = {
  source = "img/btn/detailFav.png",
  frames = {width=22, height=19, numFrames=6},
  sequences = {
      { name = "stop", loopCount = 1, start = 1, count=1},
      { name = "isFav", loopCount = 1, start = 6, count=1},
      { name = "play", time=300, start = 1, count=6, loopCount=1}
  }
}

Sprites.red = {
  source = "img/btn/red.png",
  frames = {width=40, height=40, numFrames=4},
  sequences = {
      { name = "stop", loopCount = 1, start = 1, count=1},
      { name = "search", time=1500, start = 1, count=3},
      { name = "si-red", loopCount = 1, start = 3, count=1},
      { name = "no-red", loopCount = 1, start = 4, count=1},
  }
}

return Sprites