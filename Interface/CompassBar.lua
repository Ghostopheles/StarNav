local Events = StarNav.Events;
local Registry = StarNav.Registry;
local Settings = StarNav.Settings;

local LAF = LibStub:GetLibrary("LibAdvFlight-1.0");

local COMPASS_FOV = 180; -- in degrees
local HALF_FOV = COMPASS_FOV / 2; -- in degrees
local MINOR_LINE_INCREMENT = 5; -- degrees between minor lines
local MAJOR_LINE_INCREMENT = 15; -- degrees between major line

local POI_ICON_SIZE = 32;
local POI_ICON_MAX_DISTANCE = 800;
local POI_ICON_MIN_SCALE = 0.5;
local POI_ICON_MAX_SCALE = 1;
local POI_ICON_MIN_ALPHA = 0.25;
local POI_ICON_MAX_ALPHA = 1;

local DEFAULT_LINE_THICKNESS = 1;
local DEFAULT_LINE_LAYER = "ARTWORK";

local DEFAULT_COLOR = CreateColorFromHexString("ff618ac7");

local function GetLineColor()
    local setting = Settings.GetSetting("STARNAV_CompassColor");
    if setting then
        return CreateColorFromHexString(setting);
    else
        return DEFAULT_COLOR;
    end
end

---@param parent FrameScriptObject
---@param thickness number?
local function CreateLinePool(parent, thickness)
    thickness = thickness or DEFAULT_LINE_THICKNESS;
    local color = GetLineColor();
    local layer = DEFAULT_LINE_LAYER;
    local function CreateLine()
        local line = parent:CreateLine(nil, layer);
        line:SetThickness(thickness);
        line:SetColorTexture(color:GetRGBA());
        return line;
    end

    return CreateObjectPool(CreateLine);
end

local DEFAULT_FONTSTRING_FONT = "GameFontWhite";
local DEFAULT_FONTSTRING_LAYER = "ARTWORK";

---@param parent FrameScriptObject
---@param font string?
---@param layer string?
local function CreateFontStringPool(parent, font, layer)
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

local function NormalizeAngle(degrees)
    return (degrees % 360 + 360) % 360;
end

------------

local MAJOR_LINE_HEIGHT = 30;
local MAJOR_LINE_THICKNESS = 2;

local MINOR_LINE_HEIGHT = 15;
local MINOR_LINE_THICKNESS = 1;

local POI_LABEL_BUFFER = 3; -- degrees between heading and POI direction to show label
local ATLAS_WITH_TEXTURE_KIT_PREFIX = "%s-%s";

CompassBarMixin = {};

function CompassBarMixin:OnLoad()
    local lineColor = GetLineColor();
    self.Line:SetColorTexture(lineColor:GetRGBA());

    self.MajorLinePool = CreateLinePool(self, MAJOR_LINE_THICKNESS);
    self.MinorLinePool = CreateLinePool(self, MINOR_LINE_THICKNESS);
    self.LabelFontStringPool = CreateFontStringPool(self);
    self.AreaPOIIconPool = CreateTexturePool(self, "ARTWORK", nil, nil, function(_, texture)
        texture:SetTexture(nil);
    end);

    -- draw a little box around our 'current heading' text
    self.HeadingBorderLines = {};
    local function MakeLine()
        local line = self:CreateLine(nil, "ARTWORK");
        line:SetColorTexture(lineColor:GetRGBA());
        line:SetThickness(1.5);
        tinsert(self.HeadingBorderLines, line);
        return line;
    end

    local sideOffsetY = 3;
    local lineL = MakeLine();
    lineL:SetStartPoint("TOPLEFT", self.CurrentHeadingText, 0, sideOffsetY);
    lineL:SetEndPoint("BOTTOMLEFT", self.CurrentHeadingText, 0, -sideOffsetY);

    local rightOffsetX = 2;
    local lineR = MakeLine();
    lineR:SetStartPoint("TOPRIGHT", self.CurrentHeadingText, rightOffsetX, sideOffsetY);
    lineR:SetEndPoint("BOTTOMRIGHT", self.CurrentHeadingText, rightOffsetX, -sideOffsetY);

    local topOffsetLeftX = 1;
    local topOffsetRightX = 2;
    local lineT = MakeLine();
    lineT:SetStartPoint("TOPLEFT", self.CurrentHeadingText, -topOffsetLeftX, sideOffsetY);
    lineT:SetEndPoint("TOPRIGHT", self.CurrentHeadingText, topOffsetRightX, sideOffsetY);

    -- fade animation
    self.FadeAnim = self:CreateAnimationGroup();
    local fade = self.FadeAnim:CreateAnimation("Alpha");
    fade:SetTarget(self);
    fade:SetOrder(0);
    fade:SetDuration(0.5);
    fade:SetFromAlpha(0);
    fade:SetToAlpha(1);
    fade:SetScript("OnPlay", function() if not self.FadeAnim:IsReverse() then self:Show(); end end);
    fade:SetScript("OnFinished", function() if self.FadeAnim:IsReverse() then self:Hide(); end end);

    -- events
    self:RegisterEvent("PLAYER_ENTERING_WORLD");

    LAF.RegisterCallback(LAF.Events.ADV_FLYING_ENABLE_STATE_CHANGED, self.OnAdvFlyingEnableStateChanged, self);

    Registry:RegisterCallback(Events.SETTING_CHANGED, self.OnSettingChanged, self);
end

function CompassBarMixin:OnUpdate(deltaTime)
    self:Update();
end

function CompassBarMixin:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...);
    end
end

function CompassBarMixin:PLAYER_ENTERING_WORLD(isInitialLoad, isReloading)
    if isInitialLoad or isReloading then
        local canGlide = LAF.IsAdvFlyEnabled();
        if canGlide and not self:IsShown() then
            self:Show();
        elseif not canGlide and self:IsShown() then
            self:Hide();
        end
    end
end

function CompassBarMixin:OnAdvFlyingEnableStateChanged(canGlide)
    if canGlide then
        self:FadeIn();
    else
        self:FadeOut();
    end
end

function CompassBarMixin:OnSettingChanged(variable, value)
    if variable == "STARNAV_CompassColor" then
        local color = CreateColorFromHexString(value);
        self:UpdateColors(color);
    elseif variable == "STARNAV_ShowQuests" or variable == "STARNAV_ShowAreaPOI" then
        local forceUpdate = true;
        self:Update(forceUpdate);
    end
end

function CompassBarMixin:UpdateColors(color)
    self.Line:SetColorTexture(color:GetRGBA());
    for line in self.MajorLinePool:EnumerateActive() do
        line:SetColorTexture(color:GetRGBA());
    end
    for line in self.MinorLinePool:EnumerateActive() do
        line:SetColorTexture(color:GetRGBA());
    end
    for _, line in ipairs(self.HeadingBorderLines) do
        line:SetColorTexture(color:GetRGBA());
    end
end

function CompassBarMixin:FadeIn()
    self.FadeAnim:Play();
end

function CompassBarMixin:FadeOut()
    self.FadeAnim:Play(true);
end

function CompassBarMixin:GetCurrentHeading()
    local facing = GetPlayerFacing();
    if not facing then
        return 0;
    end

    local heading = math.deg(facing);
    return heading;
end

function CompassBarMixin:ShouldUpdate()
    return self:IsShown() and self:IsVisible();
end

function CompassBarMixin:Update(forceUpdate)
    if not self:ShouldUpdate() and not forceUpdate then
        return;
    end

    local currentHeading = self:GetCurrentHeading();
    if not currentHeading then
        return;
    end

    self.MajorLinePool:ReleaseAll();
    self.MinorLinePool:ReleaseAll();
    self.LabelFontStringPool:ReleaseAll();
    self.AreaPOIIconPool:ReleaseAll();

    local spacing_per_deg = self:GetWidth() / COMPASS_FOV;
    local pois = StarNav.GetPointsOfInterestForCurrentMap();
    if not pois and not forceUpdate then
        return;
    end
    for heading = 0, 359 do
        local delta = NormalizeAngle(heading - currentHeading);
        if delta <= HALF_FOV or delta >= (360 - HALF_FOV) then
            local offset_degrees = (delta > 180) and (delta - 360) or delta;
            local offsetX = offset_degrees * spacing_per_deg;

            if heading % MAJOR_LINE_INCREMENT == 0 then
                local line = self.MajorLinePool:Acquire();
                line:SetStartPoint("CENTER", -offsetX, 0);
                line:SetEndPoint("CENTER", -offsetX, -MAJOR_LINE_HEIGHT);

                --local label = self.LabelFontStringPool:Acquire();
                --label:SetText(heading);
                --label:SetPoint("TOP", line, "BOTTOM", 0, -5);
            elseif heading % MINOR_LINE_INCREMENT == 0 then
                local line = self.MinorLinePool:Acquire();
                line:SetStartPoint("CENTER", -offsetX, 0);
                line:SetEndPoint("CENTER", -offsetX, -MINOR_LINE_HEIGHT);
            end

            if pois and pois[heading] then
                local lastIcon, lastData;
                local distance, normalizedDistance;
                for i=1, #pois[heading] do
                    local poiData = pois[heading][i];
                    local poiPosition = poiData.WorldPosition;
                    local playerX, playerY = UnitPosition("player");
                    distance = self:CalculateDistanceToPOI(
                        poiPosition.x, poiPosition.y, playerX, playerY
                    );
                    if distance <= POI_ICON_MAX_DISTANCE then
                        local icon = self.AreaPOIIconPool:Acquire();
                        local angle_delta = NormalizeAngle(poiData.NonRoundedAngle - currentHeading);
                        local offset_angle_degrees = (angle_delta > 180) and (angle_delta - 360) or angle_delta;
                        local offset = offset_angle_degrees * spacing_per_deg;
                        icon:SetPoint("CENTER", self, "CENTER", -offset, -(MAJOR_LINE_HEIGHT + 20));
                        icon:SetSize(POI_ICON_SIZE, POI_ICON_SIZE);
                        if poiData.TextureIndex then
                            icon:SetTexture("Interface/Minimap/POIIcons");
                            icon:SetTexCoord(C_Minimap.GetPOITextureCoords(poiData.TextureIndex));
                        elseif poiData.AtlasName then
                            local atlasName = poiData.AtlasName;
                            if poiData.TextureKitPrefix then
                                atlasName = ATLAS_WITH_TEXTURE_KIT_PREFIX:format(poiData.TextureKitPrefix, atlasName);
                            end
                            icon:SetAtlas(atlasName, false);
                        end

                        normalizedDistance = self:NormalizePOIDistance(distance);
                        local scale = self:CalculatePOIScaleFromDistance(normalizedDistance);
                        icon:SetScale(scale);

                        local alpha = self:CalculatePOIAlphaFromDistance(normalizedDistance);
                        icon:SetAlpha(alpha);

                        icon:Show();
                        lastIcon = icon;
                        lastData = poiData;
                    end
                end
                if math.abs(heading - currentHeading) < POI_LABEL_BUFFER and
                        lastIcon and lastData and
                        (normalizedDistance and normalizedDistance < 0.25) then
                    local label = self.LabelFontStringPool:Acquire();
                    label:SetText(lastData.Name);
                    label:SetPoint("TOP", lastIcon, "BOTTOM", 0, -5);
                end
            end
        end
    end

    self.CurrentHeadingText:SetFormattedText("%d", currentHeading);
end

function CompassBarMixin:NormalizePOIDistance(distance)
    return math.min(distance / POI_ICON_MAX_DISTANCE, 1);
end

function CompassBarMixin:CalculateDistanceToPOI(poiX, poiY, playerX, playerY)
    local dx = poiX - playerX;
    local dy = poiY - playerY;
    return math.sqrt(dx * dx + dy * dy);
end

function CompassBarMixin:CalculatePOIScaleFromDistance(normalizedDistance)
    return POI_ICON_MAX_SCALE - (POI_ICON_MAX_SCALE - POI_ICON_MIN_SCALE) * normalizedDistance;
end

function CompassBarMixin:CalculatePOIAlphaFromDistance(normalizedDistance)
    return POI_ICON_MAX_ALPHA - (POI_ICON_MAX_ALPHA - POI_ICON_MIN_ALPHA) * normalizedDistance;
end