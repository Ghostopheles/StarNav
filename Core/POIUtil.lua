local E = StarNav.Enum;
local Settings = StarNav.Settings;
local QuestUtil = StarNav.QuestUtil;

local POI_TYPE = E.PointOfInterestType;

------------

---@param uiMapID number
---@return table<StarNav.PointOfInterestType, number[]> areaPOIIDs
local function GetAreaPOIIDsForMap(uiMapID)
    local poiIDs = {};
    poiIDs[POI_TYPE.Generic] = C_AreaPoiInfo.GetAreaPOIForMap(uiMapID);
    poiIDs[POI_TYPE.Delve] = C_AreaPoiInfo.GetDelvesForMap(uiMapID);
    poiIDs[POI_TYPE.DragonRace] = C_AreaPoiInfo.GetDragonridingRacesForMap(uiMapID);
    poiIDs[POI_TYPE.Event] = C_AreaPoiInfo.GetEventsForMap(uiMapID);
    poiIDs[POI_TYPE.QuestHub] = C_AreaPoiInfo.GetQuestHubsForMap(uiMapID);

    return poiIDs;
end

------------

---@class StarNav.PointOfInterestData
---@field ID number
---@field Name string
---@field Type StarNav.PointOfInterestType
---@field MapPosition Vector2DType
---@field WorldPosition Vector2DType
---@field AtlasName string?
---@field TextureKit string?
---@field TextureIndex number?
---@field ShouldGlow boolean?
---@field SubText string? Text to display beneath the name of the POI
---@field Misc table? A table containing any miscellaneous data - specific to the type of POI

---@class StarNav.POICache
local POICache = {
    AreaPOI = {},
    Quests = {},
    QuestLines = {},
    Instances = {}
};

function POICache:InvalidateAreaPOI()
    self.AreaPOI = {};
end

function POICache:InvalidateQuests()
    self.Quests = {};
end

function POICache:InvalidateQuestLines()
    self.QuestLines = {};
end

---@param uiMapID number
---@return StarNav.PointOfInterestData[]?
function POICache:GetAreaPOIForMap(uiMapID)
    if self.AreaPOI[uiMapID] then
        return self.AreaPOI[uiMapID];
    end

    local areaPoiIDs = GetAreaPOIIDsForMap(uiMapID);
    local data = {};
    for poiType, poiIDs in pairs(areaPoiIDs) do
        for _, id in pairs(poiIDs) do
            local info = C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, id);

            local mapPosition = info.position;
            local _, worldPosition = C_Map.GetWorldPosFromMapPos(uiMapID, mapPosition);

            ---@type StarNav.PointOfInterestData
            local poiData = {
                ID = id,
                Name = info.name,
                Type = poiType,
                MapPosition = mapPosition,
                WorldPosition = worldPosition,
                AtlasName = info.atlasName,
                TextureKit = info.uiTextureKit,
                TextureIndex = info.textureIndex,
                ShouldGlow = info.shouldGlow,
            };
            tinsert(data, poiData);
        end
    end

    self.AreaPOI[uiMapID] = data;
    return data;
end

---@param uiMapID number
---@return StarNav.PointOfInterestData[]?
function POICache:GetQuestsForMap(uiMapID)
    if self.Quests[uiMapID] then
        return self.Quests[uiMapID];
    end

    local questsInfo = {};
    questsInfo[POI_TYPE.Quest] = C_QuestLog.GetQuestsOnMap(uiMapID);
    questsInfo[POI_TYPE.TaskQuest] = C_TaskQuest.GetQuestsOnMap(uiMapID);

    local data = {};
    for poiType, quests in pairs(questsInfo) do
        for _, quest in pairs(quests) do
            local mapPosition = CreateVector2D(quest.x, quest.y);
            local _, worldPosition = C_Map.GetWorldPosFromMapPos(uiMapID, mapPosition);

            local questID = quest.questID;
            local questName = QuestUtil.GetQuestName(questID);
            local atlasName = QuestUtil.GetAtlasForQuest(questID);
            local miscInfo = {
                QuestTagType = quest.questTagType,
            };
            if poiType == POI_TYPE.TaskQuest then
                miscInfo.SecondsLeft = C_TaskQuest.GetQuestTimeLeftSeconds(questID);
            end

            ---@type StarNav.PointOfInterestData
            local poiData = {
                ID = questID,
                Name = questName,
                Type = poiType,
                AtlasName = atlasName,
                MapPosition = mapPosition,
                WorldPosition = worldPosition,
                Misc = miscInfo,
            };
            tinsert(data, poiData);
        end
    end

    self.Quests[uiMapID] = data;
    return data;
end

---@param uiMapID number
---@return StarNav.PointOfInterestData[]?
function POICache:GetQuestLinesForMap(uiMapID)
    if self.QuestLines[uiMapID] then
        return self.QuestLines[uiMapID];
    end

    local data = {};
    local questLines = C_QuestLine.GetAvailableQuestLines(uiMapID);
    for _, questLine in pairs(questLines) do
        local mapPosition = CreateVector2D(questLine.x, questLine.y);
        local _, worldPosition = C_Map.GetWorldPosFromMapPos(uiMapID, mapPosition);

        local questID = questLine.questID;
        local questName = questLine.isLocalStory and questLine.questLineName or QuestUtil.GetQuestName(questID);
        local atlasName = QuestUtil.GetAtlasForQuest(questID);
        local miscInfo = {
            QuestLineID = questLine.questLineID,
            FloorLocation = questLine.floorLocation
        };

        ---@type StarNav.PointOfInterestData
        local poiData = {
            ID = questID,
            Name = questName,
            Type = POI_TYPE.QuestLine,
            AtlasName = atlasName,
            MapPosition = mapPosition,
            WorldPosition = worldPosition,
            Misc = miscInfo,
        };
        tinsert(data, poiData);
    end

    self.QuestLines[uiMapID] = data;
    return data;
end

function POICache:GetInstancesForMap(uiMapID)
    if self.Instances[uiMapID] then
        return self.Instances[uiMapID];
    end

    local data = {};
    local entrances = C_EncounterJournal.GetDungeonEntrancesForMap(uiMapID);
    for _, entrance in pairs(entrances) do
        local mapPosition = entrance.position;
        local _, worldPosition = C_Map.GetWorldPosFromMapPos(uiMapID, mapPosition);

        local misc = {
            JournalInstanceID = entrance.journalInstanceID
        };

        ---@type StarNav.PointOfInterestData
        local poiData = {
            ID = entrance.areaPoiID,
            Name = entrance.name,
            Type = POI_TYPE.Instance,
            AtlasName = entrance.atlasName,
            MapPosition = mapPosition,
            WorldPosition = worldPosition,
            Misc = misc
        };
        tinsert(data, poiData);
    end

    self.Instances[uiMapID] = data;
    return data;
end

------------

local f = CreateFrame("Frame");
f:SetScript("OnEvent", function(_, event)
    if event == "AREA_POIS_UPDATED" then
        POICache:InvalidateAreaPOI();
    elseif event == "QUEST_LOG_UPDATE" or event == "SUPER_TRACKING_CHANGED" then
        POICache:InvalidateQuests();
        POICache:InvalidateQuestLines();
    end
end);
f:RegisterEvent("AREA_POIS_UPDATED");
f:RegisterEvent("QUEST_POI_UPDATE");

------------

---@class StarNav.POIUtil
local POIUtil = {};

---@param uiMapID number?
---@return StarNav.PointOfInterestData[]?
function POIUtil.GetPointsOfInterestForMap(uiMapID)
    if not uiMapID then
        return;
    end

    local pointsOfInterest = {};
    if Settings.GetSetting("STARNAV_ShowAreaPOI") then
        tAppendAll(pointsOfInterest, POICache:GetAreaPOIForMap(uiMapID));
    end
    if Settings.GetSetting("STARNAV_ShowQuests") then
        tAppendAll(pointsOfInterest, POICache:GetQuestsForMap(uiMapID));
    end
    if Settings.GetSetting("STARNAV_ShowQuestLines") then
        tAppendAll(pointsOfInterest, POICache:GetQuestLinesForMap(uiMapID));
    end
    if Settings.GetSetting("STARNAV_ShowInstances") then
        tAppendAll(pointsOfInterest, POICache:GetInstancesForMap(uiMapID));
    end

    return pointsOfInterest;
end

---@return StarNav.PointOfInterestData[]?
function POIUtil.GetPointsOfInterestForCurrentMap()
    local uiMapID = C_Map.GetBestMapForUnit("player");
    return POIUtil.GetPointsOfInterestForMap(uiMapID);
end

------------

StarNav.POIUtil = POIUtil;