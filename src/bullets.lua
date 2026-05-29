--[[
Purpose: Manage bullet entities, including spawn, movement, draw, and death tween cleanup.
]]

-- Requirements
local Tween = require("src.tweens")

-- Variables
local BULLET_DEATH_DURATION <const> = 0.25

local Bullets = {}

local bullets = {}

-- Lifecycle Functions
-- PUBLIC: Reset bullet state for a new run.
function Bullets.Init()
  bullets = {}
end

-- PUBLIC: Update bullet movement and death tweens.
function Bullets.Update(dt)
  for index = #bullets, 1, -1 do
    local bullet = bullets[index]
    if bullet.is_dying then
      if Tween.Update(bullet, dt) then
        table.remove(bullets, index)
      end
    else
      bullet.x = bullet.x + bullet.vx
      bullet.y = bullet.y + bullet.vy

      if bullet.x > usagi.GAME_W or bullet.x < 0 or bullet.y > usagi.GAME_H or bullet.y < 0 then
        if Bullets.KillAt(index) then
          sfx.play("drop")
        end
      end
    end
  end
end

-- PUBLIC: Draw all active bullets.
function Bullets.Draw(dt)
  local sprite_size = usagi.SPRITE_SIZE
  local source_x = sprite_size
  local source_y = sprite_size

  for index = #bullets, 1, -1 do
    local bullet = bullets[index]
    local draw_size = sprite_size * bullet.scale
    local draw_x = bullet.x + ((sprite_size - draw_size) / 2)
    local draw_y = bullet.y + ((sprite_size - draw_size) / 2)

    gfx.sspr_ex(
      source_x, source_y, sprite_size, sprite_size,
      draw_x, draw_y, draw_size, draw_size,
      false, false, bullet.rotation, gfx.COLOR_WHITE, 1.0
    )
  end
end

-- Other Functions
-- PUBLIC: Spawn a bullet at the given position and direction.
function Bullets.ShootBullet(x, y, dx, dy, speed)
  local bullet = {
    x = x,
    y = y,
    vx = dx * speed,
    vy = dy * speed,
    rotation = math.atan(dy, dx) + (math.pi / 2),
    scale = 1.0,
    is_dying = false,
  }

  table.insert(bullets, bullet)
end

-- PUBLIC: Return all bullet entities.
function Bullets.GetAll()
  return bullets
end

-- PUBLIC: Remove a bullet by index.
function Bullets.RemoveAt(index)
  table.remove(bullets, index)
end

-- PUBLIC: Mark a bullet as dying and start its shrink tween.
function Bullets.KillAt(index)
  local bullet = bullets[index]
  if bullet == nil or bullet.is_dying then
    return false
  end

  bullet.is_dying = true
  Tween.Scale(bullet, 1.0, 0.0, BULLET_DEATH_DURATION, Tween.Easing.EaseIn)
  return true
end

-- PUBLIC: Report whether a bullet is alive.
function Bullets.IsAlive(bullet)
  return bullet ~= nil and bullet.is_dying == false
end

return Bullets
