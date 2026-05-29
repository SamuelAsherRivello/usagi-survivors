--[[
Purpose: Manage bomb entities, including spawn, tweened growth, drawing, and removal.
]]

-- Requirements
local Tween = require("src.tweens")

-- Variables
local BOMB_SCALE_START <const> = 0.0
local BOMB_SCALE_END <const> = 5.0
local BOMB_GROW_DURATION <const> = 1.0

local Bombs = {}

local bombs = {}

-- Lifecycle Functions
-- PUBLIC: Reset bomb state for a new run.
function Bombs.Init()
  bombs = {}
end

-- PUBLIC: Update all active bombs and remove finished tweens.
function Bombs.Update(dt)
  for index = #bombs, 1, -1 do
    local bomb = bombs[index]
    if Tween.Update(bomb, dt) then
      table.remove(bombs, index)
    end
  end
end

-- PUBLIC: Draw all active bombs.
function Bombs.Draw(dt)
  local sprite_size = usagi.SPRITE_SIZE
  local source_x = 0
  local source_y = sprite_size

  for index = #bombs, 1, -1 do
    local bomb = bombs[index]
    local draw_size = sprite_size * bomb.scale
    local draw_x = bomb.x - (draw_size / 2)
    local draw_y = bomb.y - (draw_size / 2)

    gfx.sspr_ex(
      source_x, source_y, sprite_size, sprite_size,
      draw_x, draw_y, draw_size, draw_size,
      false, false, 0, gfx.COLOR_WHITE, 1.0
    )
  end
end

-- Other Functions
-- PUBLIC: Spawn a bomb centered at the given world position.
function Bombs.PlaceBomb(x, y)
  local bomb = {
    x = x,
    y = y,
    scale = BOMB_SCALE_START,
  }

  Tween.Scale(bomb, BOMB_SCALE_START, BOMB_SCALE_END, BOMB_GROW_DURATION, Tween.Easing.EaseOut)
  table.insert(bombs, bomb)
end

-- PUBLIC: Return all bomb entities.
function Bombs.GetAll()
  return bombs
end

-- PUBLIC: Remove a bomb by index.
function Bombs.RemoveAt(index)
  table.remove(bombs, index)
end

-- PUBLIC: Remove a bomb by index and report success.
function Bombs.KillAt(index)
  local bomb = bombs[index]
  if bomb == nil then
    return false
  end

  table.remove(bombs, index)
  return true
end

-- PUBLIC: Report whether a bomb reference is still valid.
function Bombs.IsAlive(bomb)
  return bomb ~= nil
end

return Bombs
