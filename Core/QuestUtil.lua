local QUEST_CLASS = Enum.QuestClassification;
local QUEST_CLASS_TO_ATLAS = {
    [QUEST_CLASS.Normal] = {
        ReadyForTurnIn = "QuestTurnin",
        Trivial = "TrivialQuests",
        Normal = "SmallQuestBang"
    },
    [QUEST_CLASS.Campaign] = {
        ReadyForTurnIn = "Quest-Campaign-TurnIn",
        Trivial = "Quest-Campaign-Available-Trivial",
        Normal = "Quest-Campaign-Available"
    },
    [QUEST_CLASS.Important] = {
        ReadyForTurnIn = "quest-important-turnin",
        Trivial = "quest-important-available-trivial",
        Normal = "quest-important-available",
    },
    [QUEST_CLASS.Legendary] = {
        ReadyForTurnIn = "quest-legendary-turnin",
        Trivial = "quest-legendary-available-trivial",
        Normal = "quest-legendary-available"
    },
    [QUEST_CLASS.Recurring] = {
        ReadyForTurnIn = "quest-recurring-turnin",
        Trivial = "quest-recurring-trivial",
        Normal = "quest-recurring-available"
    },
    [QUEST_CLASS.Calling] = {
        ReadyForTurnIn = "Quest-DailyCampaign-TurnIn",
        Normal = "Quest-DailyCampaign-Available"
    },
    [QUEST_CLASS.Meta] = {
        ReadyForTurnIn = "quest-wrapper-turnin",
        Trivial = "quest-wrapper-trivial",
        Normal = "quest-wrapper-available"
    },
    [QUEST_CLASS.WorldQuest] = {
        Normal = "worldquest-questmarker-epic",
    }
};

------------

---@class StarNav.QuestUtil
local QuestUtil = {};

---@param questID number
---@return string questName
function QuestUtil.GetQuestName(questID)
    return C_TaskQuest.GetQuestInfoByQuestID(questID) or C_QuestLog.GetTitleForQuestID(questID);
end

---Returns an atlas name for the given questID
---@param questID number
---@return string atlasName
function QuestUtil.GetAtlasForQuest(questID)
    local isTrivial = C_QuestLog.IsQuestTrivial(questID);
    local readyForTurnIn = C_QuestLog.ReadyForTurnIn(questID);
    local classification = C_QuestInfoSystem.GetQuestClassification(questID);

    local atlasInfo = QUEST_CLASS_TO_ATLAS[classification];
    if atlasInfo then
        if readyForTurnIn and atlasInfo.ReadyForTurnIn then
            return atlasInfo.ReadyForTurnIn;
        end

        if isTrivial and atlasInfo.Trivial then
            return atlasInfo.Trivial;
        end

        return atlasInfo.Normal;
    end

    return "QuestBlob";
end

------------

StarNav.QuestUtil = QuestUtil;