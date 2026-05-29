--[[
Purpose: Render gameplay HUD elements from shared game state.
]]

-- Requirements

-- Variables
local SHARED_STATE_KEY <const> = "__USAGI_SURVIVORS_SHARED_STATE"
local CONTROLS_TEXT <const> = "Keys: WASD, Space"
local XP_TEXT <const> = "XP"
local BOMBS_TEXT <const> = "Bombs"
local UI_LEFT_SHIFT <const> = 5
local LABEL_X_SHIFT <const> = 2
local XP_LABEL_Y_SHIFT <const> = -2
local BOMBS_LABEL_Y_SHIFT <const> = -2

local UserInterface = {}

---@type any
local state = nil

local ensure_state

-- Lifecycle Functions
---@param shared_state any
-- PUBLIC: Initialize UI state bindings.
function UserInterface.Init(shared_state)
  state = shared_state
  _G[SHARED_STATE_KEY] = shared_state
end

-- PUBLIC: Draw all HUD elements.
function UserInterface.Draw(dt)
  if not ensure_state() then
    return
  end

  gfx.text(state.game_title, 10, 10, gfx.COLOR_WHITE)
  gfx.text(CONTROLS_TEXT, 10, 22, gfx.COLOR_WHITE)
  local wave_current = math.max(1, state.wave_current or 1)
  local wave_text = string.format("Wave: %03d", wave_current)
  gfx.text(wave_text, 10, 34, gfx.COLOR_WHITE)
  gfx.rect_ex(0, 0, usagi.GAME_W, usagi.GAME_H, 2, gfx.COLOR_WHITE)

  local bomb_icon_scale = state.ui.bomb_icon_scale
  local bomb_icon_size = usagi.SPRITE_SIZE * bomb_icon_scale
  local bomb_spacing = bomb_icon_size + 4
  local bombs_row_w = (bomb_icon_size * state.max_bombs) + ((state.max_bombs - 1) * 4)

  local xp_bar_w = bombs_row_w
  local ui_block_offset_x = 20
  local row_x = (((usagi.GAME_W - xp_bar_w - state.ui.xp_bar_margin) - ui_block_offset_x) - 13) - UI_LEFT_SHIFT
  local xp_bar_x = row_x
  local xp_bar_y = state.ui.xp_bar_margin
  local label_right_x = usagi.GAME_W - state.ui.xp_bar_margin

  local bombs_label = BOMBS_TEXT
  local bombs_label_w = usagi.measure_text(bombs_label)
  local bombs_label_x = ((label_right_x - bombs_label_w) - UI_LEFT_SHIFT) + LABEL_X_SHIFT
  local xp_label = XP_TEXT
  local xp_label_x = bombs_label_x
  local xp_fill_w = xp_bar_w * (state.xp_current / state.xp_to_level)
  gfx.rect_fill(xp_bar_x, xp_bar_y, xp_bar_w, state.ui.xp_bar_h, gfx.COLOR_DARK_GRAY)
  gfx.rect_fill(xp_bar_x, xp_bar_y, xp_fill_w, state.ui.xp_bar_h, gfx.COLOR_GREEN)
  gfx.rect_ex(xp_bar_x, xp_bar_y, xp_bar_w, state.ui.xp_bar_h, 1, gfx.COLOR_WHITE)
  gfx.text(xp_label, xp_label_x, xp_bar_y + XP_LABEL_Y_SHIFT, gfx.COLOR_WHITE)

  local bombs_label_y = xp_bar_y + state.ui.xp_bar_h + 8
  local bomb_icons_x = row_x
  local bomb_icon_y = bombs_label_y + 0.2
  local bomb_label_y = bomb_icon_y + ((bomb_icon_size - 10) / 2) + BOMBS_LABEL_Y_SHIFT
  local bomb_source_x = 0
  local bomb_source_y = usagi.SPRITE_SIZE
  gfx.text(bombs_label, bombs_label_x, bomb_label_y, gfx.COLOR_WHITE)

  for bomb_index = 1, state.max_bombs do
    local bomb_icon_x = bomb_icons_x + ((bomb_index - 1) * bomb_spacing)
    local tint = gfx.COLOR_DARK_GRAY
    if bomb_index <= state.bombs_remaining then
      tint = gfx.COLOR_WHITE
    end

    gfx.sspr_ex(
      bomb_source_x, bomb_source_y, usagi.SPRITE_SIZE, usagi.SPRITE_SIZE,
      bomb_icon_x, bomb_icon_y, bomb_icon_size, bomb_icon_size,
      false, false, 0, tint, 1.0
    )
  end
end

-- Other Functions
ensure_state = function()
  if state == nil then
    state = _G[SHARED_STATE_KEY]
  end

  return state ~= nil
end

return UserInterface
