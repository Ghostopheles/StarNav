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

------------

StarNavFocusBoxMixin = {};

function StarNavFocusBoxMixin:OnLoad()
    -- resize layout stuff
    self.minimumWidth = 125;
    self.minimumHeight = 75;
    self.heightPadding = 5;

    self.LabelFontStringPool = CreateFontStringPool(self);
    self.FontStringCache = {};

    -- layout stuff
    local direction = GridLayoutMixin.Direction.BottomToTop;
    local stride = 5;
    local paddingX, paddingY = 0, 5;
    self.GridLayout = AnchorUtil.CreateGridLayout(direction, stride, paddingX, paddingY);
    self.InitialAnchor = AnchorUtil.CreateAnchor("TOP", self.FocusArt, "BOTTOM", 0, 0);

    -- fade animation
    self.FadeAnim = self:CreateAnimationGroup();
    local fade = self.FadeAnim:CreateAnimation("Alpha");
    fade:SetTarget(self);
    fade:SetOrder(0);
    fade:SetDuration(0.25);
    fade:SetFromAlpha(0);
    fade:SetToAlpha(1);
    fade:SetScript("OnPlay", function() if not self.FadeAnim:IsReverse() then self:Show(); end end);
    fade:SetScript("OnFinished", function() if self.FadeAnim:IsReverse() then self:Hide(); end end);
end

function StarNavFocusBoxMixin:FadeIn()
    self.FadeAnim:Play();
end

function StarNavFocusBoxMixin:FadeOut()
    self.FadeAnim:Play(true);
end

function StarNavFocusBoxMixin:Update()
    self:Reset();
    if not self.FocusedLabels or #self.FocusedLabels == 0 then
        if self:IsShown() then
            self:FadeOut();
        end
        return;
    end

    if not self:IsShown() or not self:IsVisible() then
        self:FadeIn();
    end

    local labels = {};
    for _, text in ipairs(self.FocusedLabels) do
        local label = self.LabelFontStringPool:Acquire();
        label:SetText(text);
        tinsert(labels, label);
    end

    AnchorUtil.GridLayout(labels, self.InitialAnchor, self.GridLayout);
    self:MarkDirty();

    self.FocusedLabels = nil;
end

function StarNavFocusBoxMixin:Focus(labels)
    self.FocusedLabels = labels;
    self:Update();
end

function StarNavFocusBoxMixin:Reset()
    self.LabelFontStringPool:ReleaseAll();
end