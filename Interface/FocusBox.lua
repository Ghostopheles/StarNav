local Pools = StarNav.Pools;

------------

StarNavFocusBoxMixin = {};

function StarNavFocusBoxMixin:OnLoad()
    -- resize layout stuff
    self.minimumWidth = 125;
    self.minimumHeight = 87;
    self.widthPadding = 8;
    self.heightPadding = 8;

    self.LabelFontStringPool = Pools.CreateFontStringPool(self);
    self.FontStringCache = {};

    -- layout stuff
    local direction = GridLayoutMixin.Direction.BottomToTop;
    local stride = 50;
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
        label.ignoreInLayout = false;
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
    for label in self.LabelFontStringPool:EnumerateActive() do
        label:ClearAllPoints();
        label.ignoreInLayout = true;
        self.LabelFontStringPool:Release(label);
    end
end