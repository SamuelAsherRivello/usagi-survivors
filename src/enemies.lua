--[[
Purpose: Manage enemy spawning, movement toward the player, draw, and death tween cleanup.
]]

-- Requirements
local Tween = require("src.tweens")

-- Variables
local ENEMY_SPRITE_INDEX <const> = 2
local ENEMY_BASE_SPEED <const> = 0.5
local ENEMY_SPAWN_INTERVAL <const> = 1.0
local ENEMY_DEATH_DURATION <const> = 0.25
local ENEMY_SPEED_PER_WAVE <const> = 0.25

local Enemies = {}

local enemies = {}
local spawn_timer = 0

local spawn_enemy

-- Lifecycle Functions
-- PUBLIC: Reset enemy state for a new run.
function Enemies.Init()
  enemies = {}
  spawn_timer = 0
end

-- PUBLIC: Update spawning, movement, and death tweens.
function Enemies.Update(dt, player_x, player_y, wave_current)
  spawn_timer = spawn_timer - dt
  while spawn_timer <= 0 do
    spawn_enemy()
    spawn_timer = spawn_timer + ENEMY_SPAWN_INTERVAL
  end

  local wave = wave_current or 1
  local enemy_speed = ENEMY_BASE_SPEED * (1 + ((wave - 1) * ENEMY_SPEED_PER_WAVE))

  for index = #enemies, 1, -1 do
    local enemy = enemies[index]
    if enemy.is_dying then
      if Tween.Update(enemy, dt) then
        table.remove(enemies, index)
      end
    else
      local to_player_x = player_x - enemy.x
      local to_player_y = player_y - enemy.y
      local distance = math.sqrt((to_player_x * to_player_x) + (to_player_y * to_player_y))

      if distance > 0 then
        enemy.x = enemy.x + (to_player_x / distance) * enemy_speed
        enemy.y = enemy.y + (to_player_y / distance) * enemy_speed
      end
    end
  end
end

-- PUBLIC: Draw all enemies.
function Enemies.Draw(dt)
  local sprite_size = usagi.SPRITE_SIZE
  local source_x = sprite_size
  local source_y = 0

  for index = #enemies, 1, -1 do
    local enemy = enemies[index]
    if enemy.is_dying then
      local draw_size = sprite_size * enemy.scale
      local draw_x = enemy.x + ((sprite_size - draw_size) / 2)
      local draw_y = enemy.y + ((sprite_size - draw_size) / 2)

      gfx.sspr_ex(
        source_x, source_y, sprite_size, sprite_size,
        draw_x, draw_y, draw_size, draw_size,
        false, false, 0, gfx.COLOR_WHITE, 1.0
      )
    else
      gfx.spr(ENEMY_SPRITE_INDEX, enemy.x, enemy.y)
    end
  end
end

-- Other Functions
spawn_enemy = function()
  local sprite_size = usagi.SPRITE_SIZE
  local side = math.random(1, 4)
  local x = 0
  local y = 0

  if side == 1 then
    x = -sprite_size
    y = math.random(0, usagi.GAME_H - sprite_size)
  elseif side == 2 then
    x = usagi.GAME_W
    y = math.random(0, usagi.GAME_H - sprite_size)
  elseif side == 3 then
    x = math.random(0, usagi.GAME_W - sprite_size)
    y = -sprite_size
  else
    x = math.random(0, usagi.GAME_W - sprite_size)
    y = usagi.GAME_H
  end

  table.insert(enemies, {
    x = x,
    y = y,
    scale = 1.0,
    is_dying = false,
  })
end

-- PUBLIC: Return all enemy entities.
function Enemies.GetAll()
  return enemies
end

-- PUBLIC: Remove an enemy by index.
function Enemies.RemoveAt(index)
  table.remove(enemies, index)
end

-- PUBLIC: Mark an enemy as dying and start its shrink tween.
function Enemies.KillAt(index)
  local enemy = enemies[index]
  if enemy == nil or enemy.is_dying then
    return false
  end

  enemy.is_dying = true
  Tween.Scale(enemy, 1.0, 0.0, ENEMY_DEATH_DURATION, Tween.Easing.EaseIn)
  return true
end

-- PUBLIC: Report whether an enemy is alive.
function Enemies.IsAlive(enemy)
  return enemy ~= nil and enemy.is_dying == false
end

return Enemies
