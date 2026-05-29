--[[
Purpose: Manage player position, direction, and rendering.
]]

-- Requirements

-- Variables
local PLAYER_SPRITE_INDEX <const> = 1
local PLAYER_STATE_KEY <const> = "__USAGI_SURVIVORS_PLAYER_STATE"

local Player = {}

---@class PlayerState
---@field x number
---@field y number
---@field dir_x number
---@field dir_y number
---@field width number
---@field height number
---@field speed number
---@field initialized boolean

---@type PlayerState
local player_state = _G[PLAYER_STATE_KEY]
if player_state == nil then
  player_state = {
    x = 0,
    y = 0,
    dir_x = 1,
    dir_y = 0,
    width = 10,
    height = 10,
    speed = 1,
    initialized = false,
  }
  _G[PLAYER_STATE_KEY] = player_state
end

-- Lifecycle Functions
-- PUBLIC: Initialize or reset player state.
function Player.Init(force_reset)
  if force_reset or (not player_state.initialized) then
    player_state.x = usagi.GAME_W / 2
    player_state.y = usagi.GAME_H / 2
    player_state.dir_x = 1
    player_state.dir_y = 0
    player_state.initialized = true
  end
end

-- PUBLIC: Draw the player sprite.
function Player.Draw(dt)
  gfx.spr(PLAYER_SPRITE_INDEX, player_state.x, player_state.y)
end

-- Other Functions
-- PUBLIC: Move the player by the given input vector.
function Player.Move(dx, dy)
  player_state.x = player_state.x + (dx * player_state.speed)
  player_state.y = player_state.y + (dy * player_state.speed)

  if dx ~= 0 or dy ~= 0 then
    player_state.dir_x = dx
    player_state.dir_y = dy
  end
end

-- PUBLIC: Return player world position.
function Player.GetPosition()
  return player_state.x, player_state.y
end

-- PUBLIC: Return the latest non-zero move direction.
function Player.GetDirection()
  return player_state.dir_x, player_state.dir_y
end

return Player
