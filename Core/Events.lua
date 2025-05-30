---@class StarNav.Events
local Events = {
    SETTING_CHANGED = "SETTING_CHANGED"
};

local Registry = CreateFromMixins(CallbackRegistryMixin);
Registry:OnLoad();
Registry:GenerateCallbackEvents(GetKeysArray(Events));

------------

StarNav.Events = Events;
StarNav.Registry = Registry;