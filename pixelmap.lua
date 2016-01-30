local pixelmap = {
  _VERSION     = 'pixelmap 1.0.0',
  _DESCRIPTION = 'loads a tilemap from pixel information of an image',
  _URL         = 'https://github.com/aloisdeniel/love-pixelmap.lua',
  _LICENSE     = [[
    MIT LICENSE
    Copyright (c) 2016 Alois Deniel
    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]],
  colors = {},
  isCache = true,
  cacheLocation = function(imgPath) return ".pixelmap/" .. imgPath .. ".lua" end
}

-- Helpers

local function rgbaToHex(r,g,b,a)
	return string.lower(string.format("#%02x%02x%02x%02x", r,g,b,a or 255))
end

-- Tries to merge the two given rectangle into r1
local function mergeRectangles(r1,r2)
  local common, notCommon = {},{}
  for _,vert1 in ipairs(r1) do
    local isCommon = false
    for _,vert2 in ipairs(r1) do
      if (vert1[1] == vert2[1]) and (vert1[2] == vert2[2]) then
        table.insert(common,ver1)
        isCommon = true
      end
    end
    if not isCommon then 
      table.insert(commonPoints,ver1)
    end
  end
    
  -- If two points in common then merge is possible
  return (#common == 2)
end

local function mergeAllRectangles(rectangles)
  
  local result = {}
  local horizontals = {}
  local verticals = {}
  local current = nil
  
  -- Sorts rectangles  by y, then x
  table.sort(rectangles, function(a,b) return (a.tl.y < b.tl.y) or ((a.tl.y == b.tl.y) and (a.tl.x < b.tl.x)) end)
  
  -- Merge horizontally
  for _,r in ipairs(rectangles) do
    if current and (current.tr.x == r.tl.x) and (current.br.x == r.bl.x) and (current.tr.y == r.tl.y) and (current.br.y == r.bl.y) then
     current.tr, current.br =  r.tr, r.br
    else
      current = r
      table.insert(horizontals,current)
    end
  end
  
  -- Sorts rectangles by x, then y
  table.sort(horizontals, function(a,b) return (a.tl.x < b.tl.x) or ((a.tl.x == b.tl.x) and (a.tl.y < b.tl.y)) end)
  
  -- Merge vertically
  current = nil
  for _,r in ipairs(horizontals) do
    if current and (current.bl.x == r.tl.x) and (current.br.x == r.tr.x) and (current.bl.y == r.tl.y) and (current.br.y == r.tr.y) then
     current.bl, current.br =  r.bl, r.br
    else
      current = r
      table.insert(verticals,current)
    end
  end
  
  -- Simply rectangle for to tables
  for _,r in ipairs(verticals) do
    table.insert(result,{ x=r.tl.x,y=r.tl.y,w=r.tr.x - r.tl.x, h=r.bl.y - r.tl.y })
  end
    
  return result
end

local function mergeTiles(tileCoords)
  local rectangles = {}
  for _,coord in ipairs(tileCoords) do
    local x,y = coord[1], coord[2]
    local l,t,r,b = x,y,x+1,y+1
    table.insert(rectangles,{ 
      tl={ x=l,y=t },
      tr={ x=r,y=t },
      br={ x=r,y=b },
      bl={ x=l,y=b },
    })
  end
  return mergeAllRectangles(rectangles)
end

-- Table serialization

local function serialize(v)
  local t = type(v)
  if t == "string" then 
    return string.format("%q", v)
  elseif (t == "number") or (t == "boolean") then 
    return tostring(v)
  elseif t == "table" then 
    local values = {}
    for key,value in pairs(v) do
      table.insert(values, "["..serialize(key).."] = " .. serialize(value))
    end    
    return "{ ".. table.concat(values, ", ") .. " }"
  end  
  return "nil"
end

-- Registering tiles

pixelmap.register = function(color, tile, groups)
  assert(type(color) == 'string', "color must be provided in hexadecimal format (#RRGGBBAA)")
  pixelmap.colors[string.lower(color)] = { tile= tile, groups = groups }
end

-- Loader

pixelmap.load = function(path)  
  local localPath = pixelmap.cacheLocation(path)
  
  -- Loading result from local storage if available
  if pixelmap.isCache and love.filesystem.exists(localPath) then
    return love.filesystem.load(localPath)()
  end
  
  local image = love.graphics.newImage(path)
  local data = image:getData()
  local dw, dh = data:getWidth(), data:getHeight()
  local result = { tiles={},  groups={} }
  
  -- Extracting each tile from each pixel
  for x=0,(dw-1) do
    for y=0,(dh-1) do
      local r, g, b, a = data:getPixel(x,y)
      if a > 0 then
        local key = rgbaToHex(r, g, b, a)  
        local value = pixelmap.colors[key]
        assert(value,"color has not been registered : " .. key)
        if not result.tiles[x] then result.tiles[x] = {} end
        local column = result.tiles[x]
        column[y] = value.tile
        
        if value.groups then
          for _,groupName in ipairs(value.groups) do
            local group = result.groups[groupName]
            if not group then
              group = {}
              result.groups[groupName] = group
            end
            table.insert(group, {x,y})
          end
        end
      end
    end
  end
  
  -- Creating groups from nearby tiles
  for name,tiles in pairs(result.groups) do
    result.groups[name] = mergeTiles(tiles)
  end
  
  -- Saving result to local storage
  if pixelmap.isCache then
    local content = serialize(result)
    local  folder = string.match(localPath, "(.-)([^\\/]-([^%.]+))$")
    assert(love.filesystem.createDirectory(folder),"Map loading failed : saving map to local storage failed")
    assert(love.filesystem.write(localPath,"return " .. content),"Map loading failed : saving map to local storage failed")
  end
  
  return result
end

return pixelmap