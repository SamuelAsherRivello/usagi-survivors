--[[
Purpose: Build and render a lightweight patterned background grid.
]]

-- Requirements

-- Variables
local DOT_STEP <const> = 6
local LINE_STEP <const> = 18
local LINE_HEIGHT <const> = 3
local BACKGROUND_COLOR <const> = gfx.COLOR_DARK_GRAY

local World = {}

local dots = {}
local lines = {}
local is_initialized = false
local built_width = 0
local built_height = 0

local build_pattern
local ensure_ready

-- Lifecycle Functions
-- PUBLIC: Initialize world background caches.
function World.Init()
  build_pattern()
end

-- PUBLIC: Draw the world background pattern.
function World.Draw(dt)
  ensure_ready()

  for dot_index = 1, #dots do
    local dot = dots[dot_index]
    gfx.px(dot.x, dot.y, BACKGROUND_COLOR)
  end

  for line_index = 1, #lines do
    local line = lines[line_index]
    gfx.line(line.x, line.y, line.x, line.y + LINE_HEIGHT, BACKGROUND_COLOR)
  end
end

-- Other Functions
build_pattern = function()
  dots = {}
  lines = {}

  for y = 0, usagi.GAME_H - 1, DOT_STEP do
    for x = 0, usagi.GAME_W - 1, DOT_STEP do
      local marker = (x + (y * 3)) % 11
      if marker == 0 then
        table.insert(dots, { x = x, y = y })
      end
    end
  end

  for x = 0, usagi.GAME_W - 1, LINE_STEP do
    local y = ((x * 7) % (usagi.GAME_H - LINE_HEIGHT))
    table.insert(lines, { x = x, y = y })
  end

  built_width = usagi.GAME_W
  built_height = usagi.GAME_H
  is_initialized = true
end

ensure_ready = function()
  if (not is_initialized) or built_width ~= usagi.GAME_W or built_height ~= usagi.GAME_H then
    build_pattern()
  end
end

return World
