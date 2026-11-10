-- Page under Options -> AddOns

local ADDON, ns = ...
local L = ns.L

local page, category
local widgets = {}

local function Refresh()
  if not page or not WorthListingDB then return end
  local db = WorthListingDB
  local rate = db.rates[db.hours] or 0

  widgets.show:SetChecked(db.show)
  for hours, button in pairs(widgets.hours) do
    button:SetEnabled(db.hours ~= hours)
  end
  widgets.min:SetText(tostring(db.min))
  widgets.minMoney:SetText(ns.Money(db.min))
  widgets.rateLabel:SetText(L.OPT_RATE:format(db.hours))
  widgets.rate:SetText(("%.1f"):format(rate))
  widgets.cut:SetText(tostring(db.cut))
  for mode, button in pairs(widgets.modes) do
    button:SetEnabled(db.undercutMode ~= mode)
  end
  widgets.undercutPercent:SetText(tostring(db.undercutPercent))
  widgets.undercutFixed:SetText(tostring(db.undercutFixed))

  local known = 0
  for _ in pairs(db.deposits) do known = known + 1 end
  widgets.status:SetText(table.concat({
    L.STATUS_DURATION:format(db.hours),
    L.STATUS_MIN:format(ns.Money(db.min)),
    L.STATUS_RATE:format(rate),
    L.STATUS_CUT:format(db.cut),
    L.STATUS_UNDERCUT:format(ns.UndercutText()),
    L.STATUS_KNOWN:format(known),
  }, "\n"))
end

local function Label(text, anchor, x, y, font)
  local fs = page:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
  fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, y or -16)
  fs:SetJustifyH("LEFT")
  fs:SetText(text)
  return fs
end

-- Number field: takes the value on Enter or when the field loses focus
local function NumberBox(anchor, width, onCommit)
  local box = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
  box:SetSize(width, 20)
  box:SetAutoFocus(false)
  box:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 6, -6)
  local function commit(self)
    local num = tonumber((self:GetText():gsub(",", ".")))
    if num and num >= 0 then onCommit(num) end
    Refresh()
  end
  box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  box:SetScript("OnEditFocusLost", commit)
  return box
end

-- Button that grows with its text, so longer translations fit
local function Button(text, minWidth, onClick)
  local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
  b:SetText(text)
  local textWidth = b.GetTextWidth and b:GetTextWidth()
  b:SetSize(math.max(minWidth, (textWidth or 0) + 24), 22)
  b:SetScript("OnClick", function() onClick() Refresh() end)
  return b
end

local function Build()
  page = CreateFrame("Frame", "WorthListingOptionsPage", UIParent)
  page:Hide()

  local title = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText(ns.TITLE)
  local sub = Label(L.OPT_SUBTITLE, title, 0, -8, "GameFontHighlightSmall")

  -- Show in tooltip
  local show = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
  show:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", -4, -14)
  show:SetScript("OnClick", function(self) WorthListingDB.show = self:GetChecked() and true or false end)
  local showText = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  showText:SetPoint("LEFT", show, "RIGHT", 4, 0)
  showText:SetText(L.OPT_SHOW)
  widgets.show = show

  -- Duration
  local hoursLabel = Label(L.OPT_DURATION, show, 4, -14)
  widgets.hours = {}
  local prev
  for _, hours in ipairs({ 12, 24 }) do
    local b = Button(hours .. "h", 60, function() WorthListingDB.hours = hours end)
    if prev then
      b:SetPoint("LEFT", prev, "RIGHT", 6, 0)
    else
      b:SetPoint("TOPLEFT", hoursLabel, "BOTTOMLEFT", 0, -6)
    end
    widgets.hours[hours] = b
    prev = b
  end

  -- Minimum deposit
  local minLabel = Label(L.OPT_MIN, widgets.hours[12], 0, -18)
  widgets.min = NumberBox(minLabel, 80, function(num) WorthListingDB.min = math.floor(num) end)
  widgets.minMoney = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  widgets.minMoney:SetPoint("LEFT", widgets.min, "RIGHT", 10, 0)

  -- Deposit rate
  widgets.rateLabel = Label("", minLabel, 0, -40)
  widgets.rate = NumberBox(widgets.rateLabel, 80, function(num) WorthListingDB.rates[WorthListingDB.hours] = num end)

  -- AH cut
  local cutLabel = Label(L.OPT_CUT, widgets.rateLabel, 0, -40)
  widgets.cut = NumberBox(cutLabel, 80, function(num) WorthListingDB.cut = num end)

  -- Undercut
  local undercutLabel = Label(L.OPT_UNDERCUT, cutLabel, 0, -40)
  widgets.modes = {}
  prev = nil
  for _, entry in ipairs({
    { "auctionator", L.MODE_AUCTIONATOR, 120 },
    { "percent", L.MODE_PERCENT, 80 },
    { "fixed", L.MODE_FIXED, 80 },
    { "none", L.MODE_NONE, 50 },
  }) do
    local mode = entry[1]
    local b = Button(entry[2], entry[3], function() WorthListingDB.undercutMode = mode end)
    if prev then
      b:SetPoint("LEFT", prev, "RIGHT", 6, 0)
    else
      b:SetPoint("TOPLEFT", undercutLabel, "BOTTOMLEFT", 0, -6)
    end
    widgets.modes[mode] = b
    prev = b
  end

  local percentLabel = Label(L.OPT_PERCENT, widgets.modes.auctionator, 0, -12, "GameFontHighlightSmall")
  widgets.undercutPercent = NumberBox(percentLabel, 60, function(num) WorthListingDB.undercutPercent = math.min(num, 99) end)
  local fixedLabel = Label(L.OPT_FIXED, percentLabel, 0, 0, "GameFontHighlightSmall")
  fixedLabel:ClearAllPoints()
  fixedLabel:SetPoint("LEFT", percentLabel, "LEFT", 160, 0)
  widgets.undercutFixed = NumberBox(fixedLabel, 60, function(num) WorthListingDB.undercutFixed = math.floor(num) end)

  local hint = Label(L.OPT_HINT, percentLabel, 0, -40, "GameFontDisableSmall")

  -- Current state
  local statusTitle = Label(L.OPT_STATUS, hint, 0, -20)
  widgets.status = Label("", statusTitle, 0, -8, "GameFontHighlight")
  widgets.status:SetSpacing(4)

  local reset = Button(L.OPT_RESET, 240, function() ns.ResetLearned() end)
  reset:SetPoint("TOPLEFT", widgets.status, "BOTTOMLEFT", 0, -16)

  page:SetScript("OnShow", Refresh)
  page.OnCommit = function() end
  page.OnRefresh = Refresh
  page.OnDefault = function()
    ns.ResetLearned()
    WorthListingDB.hours = ns.defaults.hours
    WorthListingDB.cut = ns.defaults.cut
    WorthListingDB.show = ns.defaults.show
    WorthListingDB.undercutMode = ns.defaults.undercutMode
    WorthListingDB.undercutPercent = ns.defaults.undercutPercent
    WorthListingDB.undercutFixed = ns.defaults.undercutFixed
    Refresh()
  end

  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    category = Settings.RegisterCanvasLayoutCategory(page, ns.TITLE)
    Settings.RegisterAddOnCategory(category)
  elseif InterfaceOptions_AddCategory then
    page.name = ns.TITLE
    InterfaceOptions_AddCategory(page)
  end
end

function ns.BuildOptions()
  if page then return end
  local ok, err = pcall(Build)
  if not ok then
    DEFAULT_CHAT_FRAME:AddMessage(("|cffffd100%s:|r "):format(ns.TITLE) .. L.OPT_BUILD_ERROR:format(tostring(err)))
  end
end

-- Opens the page; returns false if that is not possible (then /wl prints the state in chat)
function ns.OpenOptions()
  if not category or not Settings or not Settings.OpenToCategory then return false end
  local id = category.GetID and category:GetID() or category.ID
  local ok = pcall(Settings.OpenToCategory, id)
  return ok
end
