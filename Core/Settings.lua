local Events = StarNav.Events;
local Registry = StarNav.Registry;

if not StarNavConfig then
    StarNavConfig = {};
end

local CATEGORY = Settings.RegisterVerticalLayoutCategory("StarNav");
Settings.RegisterAddOnCategory(CATEGORY);

local function OnSettingChanged(_, setting, value)
    local variable = setting:GetVariable();
    Registry:TriggerEvent(Events.SETTING_CHANGED, variable, value);
end

local function RegisterSetting(variable, name, defaultValue)
    local variableType = type(defaultValue);
    local setting = Settings.RegisterAddOnSetting(CATEGORY, variable, variable, StarNavConfig, variableType, name, defaultValue);

    Settings.SetOnValueChangedCallback(variable, OnSettingChanged);

    return setting;
end

local function CreateHeader(name)
    local initializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", { name = name });
    local layout = SettingsPanel:GetLayout(CATEGORY);
    layout:AddInitializer(initializer);

    return initializer;
end

local function CreateCheckbox(setting, tooltip)
    return Settings.CreateCheckbox(CATEGORY, setting, tooltip);
end

local function CreateColorPicker(setting, tooltip)
    local data = Settings.CreateSettingInitializerData(setting, {}, tooltip);
    local initializer = Settings.CreateSettingInitializer("StarNavColorSwatchSettingTemplate", data);
    local layout = SettingsPanel:GetLayout(CATEGORY);
    layout:AddInitializer(initializer);
    return initializer;
end

------------

---@class StarNav.Settings
StarNav.Settings = {};

function StarNav.Settings.GetSetting(variable)
    return Settings.GetSetting(variable):GetValue();
end

function StarNav.Settings.GetSettingObject(variable)
    return Settings.GetSetting(variable);
end

------------

CreateHeader("Appearance");
do
    local variable = "STARNAV_CompassColor";
    local name = "Compass Color";
    local tooltip = "Color of the compass on screen";
    local defaultValue = "ff618ac7";

    local setting = RegisterSetting(variable, name, defaultValue);
    CreateColorPicker(setting, tooltip);
end

CreateHeader("Filters");
do
    local variable = "STARNAV_ShowQuests";
    local name = "Show Quests";
    local tooltip = "Show quests on the compass display";
    local defaultValue = true;

    local setting = RegisterSetting(variable, name, defaultValue);
    CreateCheckbox(setting, tooltip);
end

do
    local variable = "STARNAV_ShowAreaPOI";
    local name = "Show Points of Interest";
    local tooltip = "Show points of interest on the compass display";
    local defaultValue = true;

    local setting = RegisterSetting(variable, name, defaultValue);
    CreateCheckbox(setting, tooltip);
end

