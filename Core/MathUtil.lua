---@class StarNav.MathUtil
local MathUtil = {};

---@param angle number Angle in degrees
---@return number angle Normalized angle
function MathUtil.NormalizeAngle(angle)
    return (angle % 360 + 360) % 360;
end

---@param angle1 number Current heading
---@param angle2 number Target heading
---@return number angleDelta
function MathUtil.GetAngleDelta(angle1, angle2)
    local delta = (angle2 - angle1 + 360) % 360;
    if delta > 180 then
        delta = delta - 360;
    end
    return delta;
end

---@param pos1 Vector2DType Start position
---@param pos2 Vector2DType End position
---@return number angle
function MathUtil.GetAngleToPosition(pos1, pos2)
    local deltaX = pos2.x - pos1.x;
    local deltaY = pos2.y - pos1.y;
    -- atan2 returns the angle in DEGREES (not to be confused with math.atan2 which returns the angle in radians)
    local angleToPoi = atan2(deltaY, deltaX);
    local normalizedAngleToPoi = MathUtil.NormalizeAngle(angleToPoi);

    return normalizedAngleToPoi;
end

---@param pos1 Vector2DType
---@param pos2 Vector2DType
---@return number distance
function MathUtil.GetDistanceToPosition(pos1, pos2)
    local dx = pos1.x - pos2.x;
    local dy = pos1.y - pos2.y;
    return math.sqrt(dx * dx + dy * dy);
end

------------

StarNav.MathUtil = MathUtil;