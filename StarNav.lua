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

local function GetAngleToPosition(pos1, pos2)
    local deltaX = pos2.x - pos1.x;
    local deltaY = pos2.y - pos1.y;
    -- atan2 returns the angle in DEGREES (not to be confused with math.atan2 which returns the angle in radians)
    local angleToPoi = atan2(deltaY, deltaX);
    local normalizedAngleToPoi = NormalizeAngle(angleToPoi);
    local roundedAngleToPoi = Round(normalizedAngleToPoi);

    return roundedAngleToPoi, normalizedAngleToPoi;
end

local function GetEnumValueName(enum, value)
    local GetName = EnumUtil.GenerateNameTranslation(enum);
    return GetName(value);
end

local function GetAtlasForQuestID(questID)
    local atlasName;
    local readyForTurnIn = C_QuestLog.ReadyForTurnIn(questID);

    local classification = C_QuestInfoSystem.GetQuestClassification(questID);
    if classification == Enum.QuestClassification.Meta then
        atlasName = "questlog-questtypeicon-Wrapper";
        if readyForTurnIn then
            atlasName = atlasName .. "turnin";
        end
        return atlasName;
    end

    local questLineInfo = C_QuestLine.GetQuestLineInfo(questID);
    if questLineInfo and questLineInfo.isQuestStart and questLineInfo.isLocalStory then
        atlasName = "questlog-storylineicon";
        return atlasName;
    end

    local valueName = GetEnumValueName(Enum.QuestClassification, classification);
    atlasName = format("questlog-questtypeicon-%s", valueName:lower());
    if readyForTurnIn then
        atlasName = atlasName .. "turnin";
    end

    return atlasName;
end

local QuestsDone = {};

local function ShouldShowQuest(quest, uiMapID)
    if quest.isHidden then
        return false;
    end

    local questID = quest.questID;
    if QuestsDone[questID] then
        return false;
    end

    local questLineInfo = C_QuestLine.GetQuestLineInfo(questID, uiMapID);
    if questLineInfo and (questLineInfo.isAccountCompleted or questLineInfo.isHidden or not questLineInfo.isQuestStart) then
        return false;
    end

    if C_QuestLog.IsQuestFlaggedCompleted(questID) then
        return false;
    end

    return true;
end

local function ProcessQuests(tbl, quests, uiMapID, playerPosition)
    for _, quest in pairs(quests) do
        if ShouldShowQuest(quest) then
            local questPosition = CreateVector2D(quest.x, quest.y);
            local _, worldPos = C_Map.GetWorldPosFromMapPos(uiMapID, questPosition);
            local roundedAngleToPoi, normalizedAngleToPoi = GetAngleToPosition(playerPosition, worldPos);
            if not tbl[roundedAngleToPoi] then
                tbl[roundedAngleToPoi] = {};
            end

            local classification = C_QuestInfoSystem.GetQuestClassification(quest.questID);
            local name;
            if classification == Enum.QuestClassification.Meta then
                name = quest.questName;
            elseif quest.questLineName then
                name = quest.isLocalStory and quest.questLineName or quest.questName;
            end
            if not name then
                name = quest.questName;
            end
            if not name then
                name = QuestUtils_GetQuestName(quest.questID);
            end

            local atlasName = GetAtlasForQuestID(quest.questID);
            if not atlasName and quest.isLocalStory then
                atlasName = "QuestLog-tab-icon-quest";
            end

            local poiData = {
                ID = quest.questID,
                Name = name,
                Position = questPosition,
                AtlasName = atlasName,
                WorldPosition = worldPos,
                NonRoundedAngle = normalizedAngleToPoi,
            };
            tinsert(tbl[roundedAngleToPoi], poiData);
            QuestsDone[quest.questID] = true;
        end
    end
end

------------

---@class StarNav
StarNav = {};

function StarNav.GetPointsOfInterestForMap(uiMapID)
    local posX, posY = UnitPosition("player");
    local playerPosition = CreateVector2D(posX, posY);
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
            local roundedAngleToPoi, normalizedAngleToPoi = GetAngleToPosition(playerPosition, worldPos);
            if not headingToPOI[roundedAngleToPoi] then
                headingToPOI[roundedAngleToPoi] = {};
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
            tinsert(headingToPOI[roundedAngleToPoi], poiData);
        end
    end

    QuestsDone = {};

    -- quests
    local quests = C_QuestLog.GetQuestsOnMap(uiMapID);
    ProcessQuests(headingToPOI, quests, uiMapID, playerPosition);

    -- task quests
    local taskQuests = C_TaskQuest.GetQuestsOnMap(uiMapID);
    ProcessQuests(headingToPOI, taskQuests, uiMapID, playerPosition);

    -- questlines
    local questlines = C_QuestLine.GetAvailableQuestLines(uiMapID);
    ProcessQuests(headingToPOI, questlines, uiMapID, playerPosition);

    return headingToPOI;
end

function StarNav.GetPointsOfInterestForCurrentMap()
    local uiMapID = C_Map.GetBestMapForUnit("player");
    if not uiMapID then
        return;
    end

    return StarNav.GetPointsOfInterestForMap(uiMapID);
end