local function NormalizeAngle(degrees)
    return (degrees % 360 + 360) % 360;
end

local AreaPOICache = {};
local f = CreateFrame("Frame");
f:SetScript("OnEvent", function()
    AreaPOICache = {};
end);
f:RegisterEvent("AREA_POIS_UPDATED");

------------

---@class StarNav
StarNav = {};

function StarNav.GetPointsOfInterestForMap(uiMapID)
    local posX, posY = UnitPosition("player");
    if not (posX and posY) then
        return;
    end

    local areaPOIIDs = AreaPOICache[uiMapID];
    if not areaPOIIDs or #areaPOIIDs == 0 then
        AreaPOICache[uiMapID] = C_AreaPoiInfo.GetAreaPOIForMap(uiMapID);
        for _, id in ipairs(C_AreaPoiInfo.GetDelvesForMap(uiMapID)) do
            tinsert(AreaPOICache[uiMapID], id);
        end
        for _, id in ipairs(C_AreaPoiInfo.GetDragonridingRacesForMap(uiMapID)) do
            tinsert(AreaPOICache[uiMapID], id);
        end
        for _, id in ipairs(C_AreaPoiInfo.GetEventsForMap(uiMapID)) do
            tinsert(AreaPOICache[uiMapID], id);
        end
        for _, id in ipairs(C_AreaPoiInfo.GetQuestHubsForMap(uiMapID)) do
            tinsert(AreaPOICache[uiMapID], id);
        end

        areaPOIIDs = AreaPOICache[uiMapID];
    end

    local headingToPOI = {};
    for i=1, #areaPOIIDs do
        local poiID = areaPOIIDs[i];
        local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, poiID);
        if poiInfo then
            local poiPosition = poiInfo.position;
            local _, worldPos = C_Map.GetWorldPosFromMapPos(uiMapID, poiPosition);
            local deltaX = worldPos.x - posX;
            local deltaY = worldPos.y - posY;
            -- atan2 returns the angle in DEGREES (not to be confused with math.atan2 which returns the angle in radians)
            local angleToPoi = atan2(deltaY, deltaX);
            local normalizedAngleToPoi = NormalizeAngle(angleToPoi);
            angleToPoi = Round(normalizedAngleToPoi);
            if not headingToPOI[angleToPoi] then
                headingToPOI[angleToPoi] = {};
            end

            local poiData = {
                ID = poiID,
                Name = poiInfo.name,
                Position = poiPosition,
                TextureIndex = poiInfo.textureIndex,
                AtlasName = poiInfo.atlasName,
                TextureKit = poiInfo.uiTextureKit,
                ShouldGlow = poiInfo.shouldGlow,
                NonRoundedAngle = normalizedAngleToPoi,
                WorldPosition = worldPos,
            };
            tinsert(headingToPOI[angleToPoi], poiData);
        end
    end

    return headingToPOI;
end

function StarNav.GetPointsOfInterestForCurrentMap()
    local uiMapID = C_Map.GetBestMapForUnit("player");
    if not uiMapID then
        return;
    end

    return StarNav.GetPointsOfInterestForMap(uiMapID);
end