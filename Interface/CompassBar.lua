local Events = StarNav.Events;
local POIUtil = StarNav.POIUtil;
local MathUtil = StarNav.MathUtil;
local Registry = StarNav.Registry;
local Settings = StarNav.Settings;

local LAF = LibStub:GetLibrary("LibAdvFlight-1.0");

local COMPASS_UPDATE_DEADZONE = 0.25;
local COMPASS_FOV = 180; -- in degrees
local HALF_FOV = COMPASS_FOV / 2; -- in degrees

local MAJOR_LINE_INCREMENT = 15; -- degrees between major line
local MAJOR_LINE_HEIGHT = 30;
local MAJOR_LINE_THICKNESS = 2;

local MINOR_LINE_INCREMENT = 5; -- degrees between minor lines
local MINOR_LINE_HEIGHT = 15;
local MINOR_LINE_THICKNESS = 1;

local POI_ICON_SIZE = 32;
local POI_ICON_MAX_DISTANCE = 1000;
local POI_ICON_MIN_SCALE = 0.5;
local POI_ICON_MAX_SCALE = 1;
local POI_ICON_MIN_ALPHA = 0.25;
local POI_ICON_MAX_ALPHA = 1;
local POI_ICON_DECAY_FACTOR = 3;
local POI_ICON_PADDING = 20;

local POI_FOCUS_BUFFER = 10; -- degrees between heading and POI direction to show label
local POI_FOCUS_DISTANCE = 0.35; -- distance normalized from 0-1
local POI_FOCUS_LABEL_FORMAT = "%s [%dm]";

local ATLAS_WITH_TEXTURE_KIT_PREFIX = "%s-%s";

local DEFAULT_LINE_THICKNESS = 1;
local DEFAULT_LINE_LAYER = "ARTWORK";

local function GetLineColor()
    local setting = Settings.GetSetting("STARNAV_CompassColor");
    if setting then
        return CreateColorFromHexString(setting);
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

------------

StarNavCompassBarMixin = {};

function StarNavCompassBarMixin:OnLoad()
    local lineColor = GetLineColor();
    self.Line:SetColorTexture(lineColor:GetRGBA());

    self.MajorLinePool = CreateLinePool(self, MAJOR_LINE_THICKNESS);
    self.MinorLinePool = CreateLinePool(self, MINOR_LINE_THICKNESS);
    self.IconPool = CreateTexturePool(self, "ARTWORK", nil, nil, function(_, texture)
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
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA");

    LAF.RegisterCallback(LAF.Events.ADV_FLYING_ENABLE_STATE_CHANGED, self.OnAdvFlyingEnableStateChanged, self);

    Registry:RegisterCallback(Events.SETTING_CHANGED, self.OnSettingChanged, self);
end

function StarNavCompassBarMixin:OnUpdate(deltaTime)
    self:Update();
end

function StarNavCompassBarMixin:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...);
    end
end

function StarNavCompassBarMixin:PLAYER_ENTERING_WORLD(isInitialLoad, isReloading)
    if (isInitialLoad or isReloading) and Settings.GetSetting("STARNAV_ShowOnlyWhileDragonriding") then
        local canGlide = LAF.IsAdvFlyEnabled();
        if canGlide and not self:IsShown() then
            self:Show();
        elseif not canGlide and self:IsShown() then
            self:Hide();
        end
    end
end

function StarNavCompassBarMixin:ZONE_CHANGED_NEW_AREA()
    if IsInInstance() then
        self:FadeOut();
    else
        self:FadeIn();
    end
end

function StarNavCompassBarMixin:OnAdvFlyingEnableStateChanged(canGlide)
    if not Settings.GetSetting("STARNAV_ShowOnlyWhileDragonriding") then
        return;
    end

    self:UpdateVisibility();
end

local UPDATE_ON = {
    ["STARNAV_ShowAreaPOI"] = true,
    ["STARNAV_ShowQuests"] = true,
    ["STARNAV_ShowQuestLines"] = true,
    ["STARNAV_ShowInstances"] = true,
}

function StarNavCompassBarMixin:OnSettingChanged(variable, value)
    if variable == "STARNAV_CompassColor" then
        local color = CreateColorFromHexString(value);
        self:UpdateColors(color);
    elseif UPDATE_ON[variable] then
        local forceUpdate = true;
        self:Update(forceUpdate);
    elseif variable == "STARNAV_ShowOnlyWhileDragonriding" then
        self:UpdateVisibility();
    end
end

function StarNavCompassBarMixin:UpdateVisibility()
    if Settings.GetSetting("STARNAV_ShowOnlyWhileDragonriding") then
        local canGlide = LAF.IsAdvFlyEnabled();
        if canGlide and not self:IsShown() then
            self:FadeIn();
        elseif not canGlide and self:IsShown() then
            self:FadeOut();
        end
    elseif not self:IsShown() then
        self:FadeIn();
    end
end

function StarNavCompassBarMixin:UpdateColors(color)
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

function StarNavCompassBarMixin:FadeIn()
    self.FadeAnim:Play();
end

function StarNavCompassBarMixin:FadeOut()
    self.FadeAnim:Play(true);
end

function StarNavCompassBarMixin:GetCurrentHeading()
    local facing = GetPlayerFacing();
    if not facing then
        return 0;
    end

    local heading = math.deg(facing);
    return heading;
end

function StarNavCompassBarMixin:ShouldUpdate()
    return self:IsShown() and self:IsVisible();
end

local LAST_HEADING;
function StarNavCompassBarMixin:Update(forceUpdate)
    if not self:ShouldUpdate() and not forceUpdate then
        return;
    end

    if IsInInstance() then
        self:FadeOut();
        return;
    end

    local currentHeading = self:GetCurrentHeading();
    if not currentHeading then
        self:FadeOut();
        return;
    end

    if LAST_HEADING
        and math.abs(currentHeading - LAST_HEADING) < COMPASS_UPDATE_DEADZONE
        and not IsPlayerMoving()
        and not forceUpdate then
        return;
    else
        LAST_HEADING = currentHeading;
    end

    local playerPosX, playerPosY = UnitPosition("player");
    if not (playerPosX and playerPosY) then
        self:FadeOut();
        return;
    end
    local playerWorldPosition = CreateVector2D(playerPosX, playerPosY);

    local function ShouldBeVisible(poiData)
        local worldPos = poiData.WorldPosition;

        local distance = MathUtil.GetDistanceToPosition(playerWorldPosition, worldPos);
        if distance > POI_ICON_MAX_DISTANCE then
            return false;
        end

        local angleToPOI = MathUtil.GetAngleToPosition(playerWorldPosition, worldPos);
        local angleDelta = MathUtil.GetAngleDelta(currentHeading, angleToPOI);
        if math.abs(angleDelta) > HALF_FOV then
            return false;
        end

        return true;
    end

    self.MajorLinePool:ReleaseAll();
    self.MinorLinePool:ReleaseAll();
    self.IconPool:ReleaseAll();

    local pixelsPerDegree = self:GetWidth() / COMPASS_FOV;

    -- draw the compass lines first
    for heading = 1, 360 do
        local angleDelta = MathUtil.GetAngleDelta(currentHeading, heading);
        if math.abs(angleDelta) <= HALF_FOV then
            local offsetX = -(angleDelta * pixelsPerDegree);
            if heading % MAJOR_LINE_INCREMENT == 0 then
                local line = self.MajorLinePool:Acquire();
                line:SetStartPoint("CENTER", offsetX, 0);
                line:SetEndPoint("CENTER", offsetX, -MAJOR_LINE_HEIGHT);
            elseif heading % MINOR_LINE_INCREMENT == 0 then
                local line = self.MinorLinePool:Acquire();
                line:SetStartPoint("CENTER", offsetX, 0);
                line:SetEndPoint("CENTER", offsetX, -MINOR_LINE_HEIGHT);
            end
        end
    end

    local pois = POIUtil.GetPointsOfInterestForCurrentMap();
    if not pois then
        return;
    end

    local labelsToFocus = {};
    for _, poiData in pairs(pois) do
        if ShouldBeVisible(poiData) then
            local worldPos = poiData.WorldPosition;
            local angleToPOI = MathUtil.GetAngleToPosition(playerWorldPosition, worldPos);
            local angleDelta = MathUtil.GetAngleDelta(currentHeading, angleToPOI);
            local offsetX = -(angleDelta * pixelsPerDegree);
            local offsetY = -(MAJOR_LINE_HEIGHT + POI_ICON_PADDING);

            local icon = self.IconPool:Acquire();
            icon:SetPoint("CENTER", self, "CENTER", offsetX, offsetY);
            icon:SetSize(POI_ICON_SIZE, POI_ICON_SIZE);

            if poiData.AtlasName then
                local atlasName = poiData.AtlasName;
                if poiData.TextureKit then
                    atlasName = ATLAS_WITH_TEXTURE_KIT_PREFIX:format(poiData.TextureKit, atlasName);
                end
                icon:SetAtlas(atlasName, false);
            elseif poiData.TextureIndex then
                icon:SetTexture("Interface/Minimap/POIIcons");
                icon:SetTexCoord(C_Minimap.GetPOITextureCoords(poiData.TextureIndex));
            end

            local distance = MathUtil.GetDistanceToPosition(playerWorldPosition, worldPos);
            local normalizedDistance = self:NormalizePOIDistance(distance);
            local scale = self:CalculatePOIScaleFromDistance(normalizedDistance);
            icon:SetScale(scale);

            local alpha = self:CalculatePOIAlphaFromDistance(normalizedDistance);
            icon:SetAlpha(alpha);

            icon:Show();

            if (math.abs(angleDelta) < POI_FOCUS_BUFFER) and (normalizedDistance < POI_FOCUS_DISTANCE) then
                local text = POI_FOCUS_LABEL_FORMAT:format(poiData.Name, distance);
                tinsert(labelsToFocus, text);
            end
        end
    end

    self.FocusBox:Focus(labelsToFocus);
    self.CurrentHeadingText:SetFormattedText("%d", currentHeading);
end

function StarNavCompassBarMixin:NormalizePOIDistance(distance)
    return math.min(distance / POI_ICON_MAX_DISTANCE, 1);
end

function StarNavCompassBarMixin:CalculatePOIScaleFromDistance(normalizedDistance)
    local decay = math.exp(-normalizedDistance * POI_ICON_DECAY_FACTOR);
    return POI_ICON_MIN_SCALE + (POI_ICON_MAX_SCALE - POI_ICON_MIN_SCALE) * decay;
end

function StarNavCompassBarMixin:CalculatePOIAlphaFromDistance(normalizedDistance)
    local decay = math.exp(-normalizedDistance * POI_ICON_DECAY_FACTOR);
    return POI_ICON_MIN_ALPHA + (POI_ICON_MAX_ALPHA - POI_ICON_MIN_ALPHA) * decay;
end