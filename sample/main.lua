package.path = [[../?.lua;]]..package.path

-- 01. Loading the map

local pixelmap = require('pixelmap')
pixelmap.register(0)
pixelmap.register(1, "#86a36bff", { "Ground" })
pixelmap.register(2, "#a47550ff", { "Ground" })
pixelmap.register(3, "#6e5a4aff")

local map = pixelmap.load('maps/map.png')

-- 02. Drawing the result

local tileset = {
  {134,164,107,100},
  {164,117,80,100},
  {110,80,74,100},
}

function love.draw()
  
  local mx, my = love.mouse.getPosition()
  love.graphics.translate(mx*0.5-350, my*0.5-200)
  
  -- 02.a. Drawing the tiles
  
  for y, row in ipairs(map.tiles) do
    for x, tile in ipairs(row) do
      if tileset[tile] then
        love.graphics.setColor(tileset[tile])
        love.graphics.rectangle("fill",x*10,y*10,10,10)
      end
    end
  end
  
  -- 02.b. Drawing the groups
  
  love.graphics.setColor({255,255,255,255})
  for name, group in pairs(map.groups) do
    for _, rect in ipairs(group) do
      local x,y,w,h = rect.x*10,rect.y*10,rect.w*10,rect.h*10
      love.graphics.rectangle("line",x,y,w,h)
      love.graphics.print( name,x+w/2,y+3)
    end
  end
  
end
