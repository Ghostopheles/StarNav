---@class StarNav.Pools
local Pools = {};

local DEFAULT_FONTSTRING_FONT = "GameFontWhite";
local DEFAULT_FONTSTRING_LAYER = "ARTWORK";

---@param parent FrameScriptObject
---@param font string?
---@param layer string?
function Pools.CreateFontStringPool(parent, font, layer)
    font = font or DEFAULT_FONTSTRING_FONT;
    layer = layer or DEFAULT_FONTSTRING_LAYER;
    local function CreateFontString()
        local fontString = parent:CreateFontString(nil, layer, font);
        return fontString;
    end

    local function ResetFontString(_, fontString)
        fontString:SetText("");
    end

    return CreateObjectPool(CreateFontString, ResetFontString);
end

------------

StarNav.Pools = Pools;