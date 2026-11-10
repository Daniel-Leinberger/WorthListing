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
local TEXT_WIDTH = 520     -- explanations wrap at this width
local GAP_SECTION = -28    -- before a new section heading
local CHECK_ROW = 24       -- height of one checkbox row
local CHECK_COLUMN = 270   -- left edge of the second checkbox column

local page, content, scroll, category
local widgets = {}

local function Refresh()
  if not page or not WorthListingDB then return end
  local db = WorthListingDB
  local rate = db.rates[db.hours] or 0

  widgets.show:SetChecked(db.show)
  for key, box in pairs(widgets.tooltips) do box:SetChecked(db.tooltips[key]) end
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

-- Checkbox with a label to its right
local function Checkbox(text, onClick)
  local box = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
  box:SetScript("OnClick", function(self) onClick(self:GetChecked() and true or false) end)
  local label = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  label:SetPoint("LEFT", box, "RIGHT", 4, 0)
  label:SetText(text)
  return box
end

-- Small grey explanation that wraps
local function Description(text, anchor, y)
  local fs = Label(text, anchor, y or -4, "GameFontDisableSmall")
  fs:SetWidth(TEXT_WIDTH)
  fs:SetWordWrap(true)
  return fs
end

-- Heading, explanation and number box for one setting; returns heading and explanation
local function Field(anchor, y, heading, description, key)
  local label = Label(heading, anchor, y)
  local desc = Description(description, label)
  widgets[key] = NumberBox(desc, 80, key)
  return label, desc
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

  -- Main switch
  local show = Checkbox(L.OPT_SHOW, function(on) WorthListingDB.show = on end)
  show:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", -4, -14)
  widgets.show = show

  -- Duration
  local hoursLabel = Label(L.OPT_DURATION, show, -14, nil, 4) -- undo the checkbox's -4 offset
  local hourEntries = {}
  for _, hours in ipairs(ns.DURATIONS) do hourEntries[#hourEntries + 1] = { hours, hours .. "h", 60 } end
  local firstHour
  widgets.hours, firstHour = ButtonRow(hoursLabel, hourEntries, ns.SetHours)

  -- Undercut
  local undercutLabel = Label(L.OPT_UNDERCUT, firstHour, -18)
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

  -- Where to show the block: one checkbox per tooltip type, two columns
  local whereLabel = Label(L.OPT_WHERE, percentLabel, GAP_FIELD + GAP_SECTION, "GameFontNormalLarge")
  local whereHint = Description(L.OPT_WHERE_HINT, whereLabel, -6)
  widgets.tooltips = {}
  local rows = math.ceil(#ns.TOOLTIP_TYPES / 2)
  for i, key in ipairs(ns.TOOLTIP_TYPES) do
    local box = Checkbox(L["TT_" .. key:upper()], function(on) WorthListingDB.tooltips[key] = on end)
    local column, row = math.floor((i - 1) / rows), (i - 1) % rows
    box:SetPoint("TOPLEFT", whereHint, "BOTTOMLEFT", -4 + column * CHECK_COLUMN, -8 - row * CHECK_ROW)
    widgets.tooltips[key] = box
  end
  local lastRow = widgets.tooltips[ns.TOOLTIP_TYPES[rows]]
  local spacer = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  spacer:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 4, 0)
  local _, firstWhere = ButtonRow(spacer, {
    { true, L.OPT_ALL_ON, 80 },
    { false, L.OPT_ALL_OFF, 80 },
    { "default", L.OPT_DEFAULT, 80 },
  }, function(value)
    if value == "default" then ns.ResetTooltips() else ns.SetAllTooltips(value) end
  end)

  -- Advanced: fees (learned automatically, normally left alone)
  local advanced = Label(L.OPT_ADVANCED, firstWhere, GAP_SECTION, "GameFontNormalLarge")
  local advancedHint = Description(L.OPT_ADVANCED_HINT, advanced, -6)

  local _, minDesc = Field(advancedHint, GAP_ROW, L.OPT_MIN, L.OPT_MIN_DESC, "min")
  widgets.minMoney = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  widgets.minMoney:SetPoint("LEFT", widgets.min, "RIGHT", 10, 0)

  local rateDesc
  widgets.rateLabel, rateDesc = Field(minDesc, GAP_FIELD, "", L.OPT_RATE_DESC, "rate")
  local _, cutDesc = Field(rateDesc, GAP_FIELD, L.OPT_CUT, L.OPT_CUT_DESC, "cut")

  -- Current state
  local statusTitle = Label(L.OPT_STATUS, cutDesc, GAP_FIELD + GAP_SECTION)
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
