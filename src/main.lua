--[[
Purpose: Orchestrate game systems, input, collisions, progression, and frame lifecycle.
]]

-- Requirements
local Bombs = require("src.bombs")
local Bullets = require("src.bullets")
local Enemies = require("src.enemies")
local Player = require("src.player")
local UserInterface = require("src.user_interface")
local World = require("src.world")

-- Variables
local GAME_TITLE <const> = "Usagi Survivors"
local GAME_ID <const> = "com.usagiengine.USAG_SURVIVORS"
local BULLET_SPEED <const> = 5
local AUTO_FIRE_INTERVAL <const> = 1.0
local AUTO_FIRE_RANGE_PLAYER_WIDTHS <const> = 5.0
local XP_PER_KILL <const> = 15
local XP_TO_LEVEL <const> = 100
local XP_BAR_W <const> = 100
local XP_BAR_H <const> = 10
local XP_BAR_MARGIN <const> = 10
local MAX_BOMBS <const> = 3
local STARTING_WAVE <const> = 1

local state = {
  game_title = GAME_TITLE,
  auto_fire_timer = 0,
  xp_current = 0,
  wave_current = STARTING_WAVE,
  bombs_remaining = MAX_BOMBS,
  xp_to_level = XP_TO_LEVEL,
  max_bombs = MAX_BOMBS,
  ui = {
    xp_bar_w = XP_BAR_W,
    xp_bar_h = XP_BAR_H,
    xp_bar_margin = XP_BAR_MARGIN,
    bomb_icon_scale = 0.75,
  },
}
_G.__USAGI_SURVIVORS_SHARED_STATE = state

local reset_run_progress
local is_overlap
local get_player_center
local get_enemy_center
local find_closest_enemy_in_range
local fire_at_enemy
local on_enemy_killed

-- Lifecycle Functions
-- PUBLIC: Return game runtime configuration.
function _config()
  return {
    name = state.game_title,
    pixel_perfect = true,
    icon = 1,
    game_id = GAME_ID,
  }
end

-- PUBLIC: Initialize game systems for a run.
function _init(force_full_reset)
  if usagi.is_fullscreen() then
    usagi.toggle_fullscreen()
  end

  if state.wave_current == 0 then
    state.wave_current = STARTING_WAVE
  end

  UserInterface.Init(state)
  Bombs.Init()
  Bullets.Init()
  Player.Init(force_full_reset == true)
  World.Init()
  Enemies.Init()
  state.auto_fire_timer = 0

  local wave_music_volume = 0.2
  local wave_music_pitch = math.min(1.0, 0.7 + (0.025 * state.wave_current))
  music.play_ex("invincible", wave_music_volume, wave_music_pitch, 0, true)
end

-- PUBLIC: Update gameplay state for one frame.
function _update(dt)
  local move_x = 0
  local move_y = 0

  if input.held(input.LEFT) then
    move_x = move_x - 1
  elseif input.held(input.RIGHT) then
    move_x = move_x + 1
  end

  if input.held(input.UP) then
    move_y = move_y - 1
  elseif input.held(input.DOWN) then
    move_y = move_y + 1
  end

  Player.Move(move_x, move_y)
  local player_x, player_y = Player.GetPosition()
  local sprite_size = usagi.SPRITE_SIZE

  if input.key_pressed(input.KEY_SPACE) then
    if state.bombs_remaining > 0 then
      local center_x, center_y = get_player_center(player_x, player_y)
      Bombs.PlaceBomb(center_x, center_y)
      state.bombs_remaining = state.bombs_remaining - 1
      sfx.play("explosion")
    else
      sfx.play("clear")
    end
  end

  local enemies = Enemies.GetAll()
  state.auto_fire_timer = state.auto_fire_timer - dt
  while state.auto_fire_timer <= 0 do
    local auto_range = sprite_size * AUTO_FIRE_RANGE_PLAYER_WIDTHS
    local closest_enemy = find_closest_enemy_in_range(player_x, player_y, enemies, auto_range)
    if closest_enemy ~= nil then
      fire_at_enemy(player_x, player_y, closest_enemy)
    end
    state.auto_fire_timer = state.auto_fire_timer + AUTO_FIRE_INTERVAL
  end

  Bullets.Update(dt)
  Bombs.Update(dt)
  Enemies.Update(dt, player_x, player_y, state.wave_current)

  enemies = Enemies.GetAll()
  local bombs = Bombs.GetAll()
  local bullets = Bullets.GetAll()

  for bomb_index = #bombs, 1, -1 do
    local bomb = bombs[bomb_index]
    if Bombs.IsAlive(bomb) then
      local bomb_radius = (sprite_size * bomb.scale) / 2
      local enemy_half_size = sprite_size / 2

      for enemy_index = #enemies, 1, -1 do
        local enemy = enemies[enemy_index]
        if Enemies.IsAlive(enemy) then
          local enemy_center_x, enemy_center_y = get_enemy_center(enemy)
          local dx = enemy_center_x - bomb.x
          local dy = enemy_center_y - bomb.y
          local distance = math.sqrt((dx * dx) + (dy * dy))

          if distance <= (bomb_radius + enemy_half_size) then
            if Enemies.KillAt(enemy_index) then
              local did_level_up = on_enemy_killed()
              if did_level_up then
                _init(true)
                return
              end
            end
          end
        end
      end
    end
  end

  for enemy_index = #enemies, 1, -1 do
    local enemy = enemies[enemy_index]

    if Enemies.IsAlive(enemy) then
      if is_overlap(enemy.x, enemy.y, sprite_size, sprite_size, player_x, player_y, sprite_size, sprite_size) then
        sfx.play("explosion")
        reset_run_progress()
        effect.slow_mo(1.5, 0.3)
        effect.screen_shake(0.3, 4)
        _init(true)
        return
      end

      for bullet_index = #bullets, 1, -1 do
        local bullet = bullets[bullet_index]
        if Bullets.IsAlive(bullet) and is_overlap(enemy.x, enemy.y, sprite_size, sprite_size, bullet.x, bullet.y, sprite_size, sprite_size) then
          if Enemies.KillAt(enemy_index) then
            Bullets.KillAt(bullet_index)
            sfx.play("drop")

            local did_level_up = on_enemy_killed()
            if did_level_up then
              _init(true)
              return
            end
            break
          end
        end
      end
    end
  end
end

-- PUBLIC: Draw the full frame.
function _draw(dt)
  gfx.clear(gfx.COLOR_BLACK)
  World.Draw(dt)
  Bombs.Draw(dt)
  Enemies.Draw(dt)
  Player.Draw(dt)
  Bullets.Draw(dt)
  UserInterface.Draw(dt)
end

-- Other Functions
reset_run_progress = function()
  state.auto_fire_timer = 0
  state.xp_current = 0
  state.wave_current = STARTING_WAVE
  state.bombs_remaining = MAX_BOMBS
  effect.stop()
end

is_overlap = function(x1, y1, w1, h1, x2, y2, w2, h2)
  return x1 < (x2 + w2) and (x1 + w1) > x2 and y1 < (y2 + h2) and (y1 + h1) > y2
end

get_player_center = function(player_x, player_y)
  local sprite_size = usagi.SPRITE_SIZE
  return player_x + (sprite_size / 2), player_y + (sprite_size / 2)
end

get_enemy_center = function(enemy)
  local sprite_size = usagi.SPRITE_SIZE
  return enemy.x + (sprite_size / 2), enemy.y + (sprite_size / 2)
end

find_closest_enemy_in_range = function(player_x, player_y, enemies, range)
  local player_center_x, player_center_y = get_player_center(player_x, player_y)
  local closest_enemy = nil
  local closest_distance = range + 1

  for index = 1, #enemies do
    local enemy = enemies[index]
    if Enemies.IsAlive(enemy) then
      local enemy_center_x, enemy_center_y = get_enemy_center(enemy)
      local dx = enemy_center_x - player_center_x
      local dy = enemy_center_y - player_center_y
      local distance = math.sqrt((dx * dx) + (dy * dy))

      if distance <= range and distance < closest_distance then
        closest_distance = distance
        closest_enemy = enemy
      end
    end
  end

  return closest_enemy
end

fire_at_enemy = function(player_x, player_y, enemy)
  local player_center_x, player_center_y = get_player_center(player_x, player_y)
  local enemy_center_x, enemy_center_y = get_enemy_center(enemy)
  local dx = enemy_center_x - player_center_x
  local dy = enemy_center_y - player_center_y
  local distance = math.sqrt((dx * dx) + (dy * dy))

  if distance <= 0 then
    return
  end

  local dir_x = dx / distance
  local dir_y = dy / distance
  local bullet_x = player_center_x - (usagi.SPRITE_SIZE / 2)
  local bullet_y = player_center_y - (usagi.SPRITE_SIZE / 2)

  Bullets.ShootBullet(bullet_x, bullet_y, dir_x, dir_y, BULLET_SPEED)
  sfx.play("rotate")
end

on_enemy_killed = function()
  state.xp_current = state.xp_current + XP_PER_KILL

  if state.xp_current >= XP_TO_LEVEL then
    state.xp_current = 0
    state.bombs_remaining = MAX_BOMBS
    state.wave_current = state.wave_current + 1
    sfx.play("levelup")
    return true
  end

  return false
end

return {
  _config = _config,
  _init = _init,
  _update = _update,
  _draw = _draw,
}
