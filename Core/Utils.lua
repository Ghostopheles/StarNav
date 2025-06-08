---@class StarNav.Utils
local Utils = {};

local EnumGetNameCache = {};
function Utils.GetEnumValueName(enum, value)
    local GetName = EnumGetNameCache[enum];

    if not GetName then
        GetName = EnumUtil.GenerateNameTranslation(enum);
        EnumGetNameCache[enum] = GetName;
    end
    return GetName(value);
end

------------

StarNav.Utils = Utils;