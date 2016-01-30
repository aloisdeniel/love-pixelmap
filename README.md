![Logo](logo.png)

A tile LÖVE map loader from pixel information of an image.

## Example

```lua
local pixelmap = require('pixelmap')

pixelmap.register("#86a36bff", "G", { "Ground" })
pixelmap.register("#a47550ff", "C", { "Ground" })
pixelmap.register("#6e5a4aff", "N")

local map = pixelmap.load('map.png')

--[[
{
	tiles= {
		[2] = { [3]="G", [4]="C", [5]="C" },
		[4] = { [1]="O" }
	},
	groups = {
		"Ground" = { { x=2,y=3,w=1,h=3} }
	}
}]]

```

See the complete sample : [./sample](./sample)

## Installation

Just copy the `pixelmap.lua` file somewhere in your projects (maybe inside a `/lib/` folder) and require it accordingly.

## API

### Property `pixelmap.isCache = true`

Indicates whether the loaded map should be saved as lua table in the folder `.pixelmap/<path_img>.lua` of the local storage for quicker next load.

### Function `pixelmap.register(color,tile,groups)`

Registers a tile and associate it to a pixel color. Groups can be added to generate area of tiles from same groups (collisions for example)

* *arg* `color` - `string` - `required` : the RGBA hexadecimal color of the pixel color (ex: `"#ff2200ff"`).
* *arg* `tile` - `object` - `required` : the value of the tile (could be its id, irs coords, ...). The structure must really simple in order to be serialized.
* *arg* `groups` - `array<string>` - `optional` : the group ids of the tile.


### Function `pixelmap.load(path) : Map`

Loads an image, reads each of its pixels and generate a map table containing the tiles and groups.

* *arg* `path` - `string` - `required` : path the image containing the pixels of the map.
* *returns* A `Map` table

### Type `Map`

The result of the loading process.

*Example* : 

```lua
{
	tiles= {
		[2] = { [3]="G", [4]="C", [5]="C" },
		[4] = { [1]="O" }
	},
	groups = {
		"Ground" = { { x=2,y=3,w=1,h=3} }
	}
}
```

## Roadmap / Ideas

* Add layer supports from file naming convention.

## Copyright and license

MIT © [Aloïs Deniel](http://aloisdeniel.github.io)
