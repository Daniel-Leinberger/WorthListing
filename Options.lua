-- Page under Options -> AddOns

local ADDON, ns = ...
local L = ns.L

-- Layout (pixels)
local MARGIN = 16          -- page edge
local GAP_SMALL = -6       -- label -> its control
local GAP_ROW = -16        -- between rows inside a section
local GAP_FIELD = -40      -- label of the next number field (leaves room for the box above)
local BUTTON_HEIGHT = 22
local BUTTON_PADDING = 24  -- text width + padding = button width
local BOX_HEIGHT = 20
local SCROLLBAR_SPACE = 28 -- room on the right for the scroll bar

local page, content, scroll, category
local widgets = {}

local function Refresh()
  if not page or not WorthListingDB then return end
  local db = WorthListingDB
  local rate = db.rates[db.hours] or 0

  widgets.show:SetChecked(db.show)
  for hours, button in pairs(widgets.hours) do button:SetEnabled(db.hours ~= hours) end
  for mode, button in pairs(widgets.modes) do button:SetEnabled(db.undercutMode ~= mode) end
  widgets.min:SetText(tostring(db.min))
  widgets.minMoney:SetText(ns.Money(db.min))
  widgets.rateLabel:SetText(L.OPT_RATE:format(db.hours))
  widgets.rate:SetText(("%.1f"):format(rate))
  widgets.cut:SetText(tostring(db.cut))
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

-- Fits the content frame to its widgets and shows the scroll bar only when needed
local function UpdateScroll()
  local top, bottom = content:GetTop(), widgets.last:GetBottom()
  if not top or not bottom then return end
  content:SetWidth(scroll:GetWidth())
  content:SetHeight(top - bottom + MARGIN)
  local needed = content:GetHeight() > scroll:GetHeight()
  if scroll.ScrollBar then scroll.ScrollBar:SetShown(needed) end
  if not needed then scroll:SetVerticalScroll(0) end
end

local function Label(text, anchor, y, font, x)
  local fs = content:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
  fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, y or GAP_ROW)
  fs:SetJustifyH("LEFT")
  fs:SetText(text)
  return fs
end

-- Number field for one setting (see ns.Set); takes the value on Enter or when it loses focus
local function NumberBox(anchor, width, key)
  local box = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
  box:SetSize(width, BOX_HEIGHT)
  box:SetAutoFocus(false)
  box:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -GAP_SMALL, GAP_SMALL)
  box:SetScript("OnEnterPressed", box.ClearFocus)
  box:SetScript("OnEscapePressed", box.ClearFocus)
  box:SetScript("OnEditFocusLost", function(self)
    local num = tonumber((self:GetText():gsub(",", ".")))
    if num then ns.Set(key, num) end
    Refresh()
  end)
  return box
end

-- Button that grows with its text, so longer translations fit
local function Button(text, minWidth, onClick)
  local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
  b:SetText(text)
  local textWidth = b.GetTextWidth and b:GetTextWidth() or 0
  b:SetSize(math.max(minWidth, textWidth + BUTTON_PADDING), BUTTON_HEIGHT)
  b:SetScript("OnClick", function() onClick() Refresh() end)
  return b
end

-- Row of buttons below a label; entries are { value, text, minWidth }.
-- Returns value -> button and the first button (to anchor what follows).
local function ButtonRow(label, entries, onClick)
  local buttons, first, prev = {}, nil, nil
  for _, entry in ipairs(entries) do
    local value = entry[1]
    local b = Button(entry[2], entry[3], function() onClick(value) end)
    if prev then
      b:SetPoint("LEFT", prev, "RIGHT", -GAP_SMALL, 0)
    else
      b:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, GAP_SMALL)
      first = b
    end
    buttons[value], prev = b, b
  end
  return buttons, first
end

local function Build()
  page = CreateFrame("Frame", "WorthListingOptionsPage", UIParent)
  page:Hide()

  -- Everything sits in a scroll frame; the scroll bar only shows when the content is taller than the page
  scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, -4)
  scroll:SetPoint("BOTTOMRIGHT", -SCROLLBAR_SPACE, 4)
  scroll.scrollBarHideable = true
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(1, 1)
  scroll:SetScrollChild(content)

  local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", MARGIN, -MARGIN)
  title:SetText(ns.TITLE)
  local sub = Label(L.OPT_SUBTITLE, title, -8, "GameFontHighlightSmall")

  -- Show in tooltip
  local show = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
  show:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", -4, -14)
  show:SetScript("OnClick", function(self) WorthListingDB.show = self:GetChecked() and true or false end)
  local showText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  showText:SetPoint("LEFT", show, "RIGHT", 4, 0)
  showText:SetText(L.OPT_SHOW)
  widgets.show = show

  -- Duration
  local hoursLabel = Label(L.OPT_DURATION, show, -14, nil, 4) -- undo the checkbox's -4 offset
  local hourEntries = {}
  for _, hours in ipairs(ns.DURATIONS) do hourEntries[#hourEntries + 1] = { hours, hours .. "h", 60 } end
  local firstHour
  widgets.hours, firstHour = ButtonRow(hoursLabel, hourEntries, ns.SetHours)

  -- Deposit
  local minLabel = Label(L.OPT_MIN, firstHour, -18)
  widgets.min = NumberBox(minLabel, 80, "min")
  widgets.minMoney = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  widgets.minMoney:SetPoint("LEFT", widgets.min, "RIGHT", 10, 0)

  widgets.rateLabel = Label("", minLabel, GAP_FIELD)
  widgets.rate = NumberBox(widgets.rateLabel, 80, "rate")

  local cutLabel = Label(L.OPT_CUT, widgets.rateLabel, GAP_FIELD)
  widgets.cut = NumberBox(cutLabel, 80, "cut")

  -- Undercut
  local undercutLabel = Label(L.OPT_UNDERCUT, cutLabel, GAP_FIELD)
  local firstMode
  widgets.modes, firstMode = ButtonRow(undercutLabel, {
    { "auctionator", L.MODE_AUCTIONATOR, 120 },
    { "percent", L.MODE_PERCENT, 80 },
    { "fixed", L.MODE_FIXED, 80 },
    { "none", L.MODE_NONE, 50 },
  }, function(mode) WorthListingDB.undercutMode = mode end)

  local percentLabel = Label(L.OPT_PERCENT, firstMode, -12, "GameFontHighlightSmall")
  widgets.undercutPercent = NumberBox(percentLabel, 60, "undercutPercent")
  local fixedLabel = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  fixedLabel:SetPoint("LEFT", percentLabel, "LEFT", 160, 0)
  fixedLabel:SetText(L.OPT_FIXED)
  widgets.undercutFixed = NumberBox(fixedLabel, 60, "undercutFixed")

  local hint = Label(L.OPT_HINT, percentLabel, GAP_FIELD, "GameFontDisableSmall")

  -- Current state
  local statusTitle = Label(L.OPT_STATUS, hint, -20)
  widgets.status = Label("", statusTitle, -8, "GameFontHighlight")
  widgets.status:SetSpacing(4)

  local reset = Button(L.OPT_RESET, 240, ns.ResetLearned)
  reset:SetPoint("TOPLEFT", widgets.status, "BOTTOMLEFT", 0, GAP_ROW)
  widgets.last = reset

  page:SetScript("OnShow", function()
    Refresh()
    UpdateScroll()
    -- positions are only known after the first layout pass
    if C_Timer then C_Timer.After(0, UpdateScroll) end
  end)
  scroll:SetScript("OnSizeChanged", UpdateScroll)
  page.OnCommit = function() end
  page.OnRefresh = Refresh
  page.OnDefault = function() ns.ResetAll() Refresh() end

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
  if not ok then ns.Print(L.OPT_BUILD_ERROR:format(tostring(err))) end
end

-- Opens the page; returns false if that is not possible (then /wl prints the state in chat)
function ns.OpenOptions()
  if not category or not Settings or not Settings.OpenToCategory then return false end
  local id = category.GetID and category:GetID() or category.ID
  return (pcall(Settings.OpenToCategory, id))
end
