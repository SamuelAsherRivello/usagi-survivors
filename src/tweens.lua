--[[
Purpose: Provide simple reusable tween helpers for scale animations.
]]

-- Requirements

-- Variables
local EASING_LINEAR <const> = "linear"
local EASING_EASE_IN <const> = "ease_in"
local EASING_EASE_OUT <const> = "ease_out"

local Tween = {}

Tween.Easing = {
  Linear = EASING_LINEAR,
  EaseIn = EASING_EASE_IN,
  EaseOut = EASING_EASE_OUT,
}

local ensure_tween_state
local apply_easing

-- Lifecycle Functions
-- PUBLIC: Advance active tween state and apply interpolated scale values.
function Tween.Update(object, dt)
  local state = object._tween_state or object._tweenState
  if object._tween_state == nil and object._tweenState ~= nil then
    object._tween_state = object._tweenState
  end

  if state == nil or state.scale == nil then
    return false
  end

  local tween = state.scale
  tween.elapsed = math.min(tween.elapsed + dt, tween.duration)

  local t = 1
  if tween.duration > 0 then
    t = tween.elapsed / tween.duration
  end

  local eased_t = apply_easing(t, tween.easing)
  object.scale = tween.from_value + ((tween.to_value - tween.from_value) * eased_t)

  if tween.elapsed >= tween.duration then
    state.scale = nil
    return true
  end

  return false
end

-- Other Functions
ensure_tween_state = function(object)
  if object._tween_state == nil then
    object._tween_state = object._tweenState or {}
  end
  object._tweenState = object._tween_state

  return object._tween_state
end

apply_easing = function(t, easing)
  if easing == Tween.Easing.EaseIn then
    return t * t
  end

  if easing == Tween.Easing.EaseOut then
    local inverse = 1 - t
    return 1 - (inverse * inverse)
  end

  return t
end

-- PUBLIC: Start a scale tween on a target object.
function Tween.Scale(object, from_value, to_value, duration, easing)
  local state = ensure_tween_state(object)
  state.scale = {
    from_value = from_value,
    to_value = to_value,
    duration = math.max(duration, 0),
    elapsed = 0,
    easing = easing or Tween.Easing.Linear,
  }
  object.scale = from_value
end

return Tween
