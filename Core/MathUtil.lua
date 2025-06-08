---@class StarNav.MathUtil
local MathUtil = {};

---@param angle number Angle in degrees
---@return number angle Normalized angle
function MathUtil.NormalizeAngle(angle)
    return (angle % 360 + 360) % 360;
end

---@param pos1 Vector2DMixin
---@param pos2 Vector2DMixin
---@return number angle
function MathUtil.GetAngleToPosition(pos1, pos2)
    local deltaX = pos2.x - pos1.x;
    local deltaY = pos2.y - pos1.y;
    -- atan2 returns the angle in DEGREES (not to be confused with math.atan2 which returns the angle in radians)
    local angleToPoi = atan2(deltaY, deltaX);
    local normalizedAngleToPoi = MathUtil.NormalizeAngle(angleToPoi);

    return normalizedAngleToPoi;
end

------------

StarNav.MathUtil = MathUtil;