-- Tooltip lines for bag items: compares the vendor price with the auction
-- house proceeds (after undercut and AH cut) for the whole stack and accounts
-- for the deposit that is lost when the auction does not sell.
--
-- Deposit:
--   AH open   -> exact value from the game for every bag item and duration, saved for later
--   AH closed -> saved value, otherwise estimate: max(minimum, vendor price * rate)
--   Minimum and rate are learned from every exact value.

local ADDON, ns = ...
local L = ns.L
local DB_VERSION = 3

local COPPER_PER_SILVER = COPPER_PER_SILVER or 100
local MAX_PERCENT = 99   -- upper limit for AH cut and undercut, keeps proceeds positive
local SAFE_FAILS = 3     -- break-even from this many failed attempts on is shown green

-- The game numbers auction durations 1, 2, 3. What they mean depends on the client:
-- WoW Forever uses 2/8/24 hours, retail-style clients 12/24/48.
local FOREVER_INTERFACE_FIRST, FOREVER_INTERFACE_LAST = 16000, 19999
local interface = select(4, GetBuildInfo()) or 0
local IS_FOREVER = interface >= FOREVER_INTERFACE_FIRST and interface <= FOREVER_INTERFACE_LAST
local DURATIONS = IS_FOREVER and { 2, 8, 24 } or { 12, 24, 48 }
local DEFAULT_RATES = IS_FOREVER and { [2] = 5, [8] = 20, [24] = 60 }
  or { [12] = 15, [24] = 30, [48] = 60 }

local DURATION_INDEX = {}
for index, hours in ipairs(DURATIONS) do DURATION_INDEX[hours] = index end

local defaults = {
  cut = 5,                      -- share the AH keeps on sale, in %
  hours = 24,                   -- auction duration
  min = COPPER_PER_SILVER,      -- minimum deposit in copper
  rates = DEFAULT_RATES,        -- deposit in % of vendor price per duration
  deposits = {},                -- saved exact deposits: "itemID:count:hours" -> copper
  undercutMode = "auctionator", -- "auctionator", "percent", "fixed" or "none"
  undercutPercent = 5,          -- undercut by x % (mode "percent")
  undercutFixed = 1,            -- undercut by x copper per item (mode "fixed")
  show = true,
}

-- Allowed range for every number the player can set (chat and options page)
local LIMITS = {
  min = { 0, math.huge, true },        -- { lowest, highest, whole numbers only }
  rate = { 0, math.huge },
  cut = { 0, MAX_PERCENT },
  undercutPercent = { 0, MAX_PERCENT },
  undercutFixed = { 0, math.huge, true },
}

local function PercentOf(value, percent)
  return value * percent / 100
end

local function PercentShare(part, whole)
  return part * 100 / whole
end

-- Pick the client's API once instead of on every tooltip
local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local GetBagLink = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink
local GetBagCount = (C_Container and C_Container.GetContainerItemInfo)
  and function(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    return info and info.stackCount
  end
  or function(bag, slot) return select(2, GetContainerItemInfo(bag, slot)) end
local GetNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
local LAST_BAG = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 -- backpack is bag 0

local ahOpen = false

-- Calls a price add-on safely; returns a positive price or nil
local function TryPrice(fn, ...)
  if not fn then return end
  local ok, value = pcall(fn, ...)
  if ok and type(value) == "number" and value > 0 then return value end
end

-- Market value per item: Auctionator first, then Auctioneer
local function GetMarketPrice(link)
  local auctionator = Auctionator and Auctionator.API and Auctionator.API.v1
  local auctioneer = AucAdvanced and AucAdvanced.API
  return TryPrice(auctionator and auctionator.GetAuctionPriceByItemLink, ADDON, link)
    or TryPrice(auctioneer and auctioneer.GetMarketValue, link)
end

-- Our listing price per item: lowest price minus undercut
local function GetListingPrice(market)
  local db = WorthListingDB
  local price
  if db.undercutMode == "auctionator" then
    local selling = Auctionator and Auctionator.Selling
    if selling and selling.CalculateItemPriceFromPrice then
      local ok, value = pcall(selling.CalculateItemPriceFromPrice, market)
      if ok and type(value) == "number" then price = value end
    end
  elseif db.undercutMode == "percent" then
    price = market - PercentOf(market, db.undercutPercent)
  elseif db.undercutMode == "fixed" then
    price = market - db.undercutFixed
  end
  return math.max(1, math.floor(price or market))
end

-- Undercut description for the options page and chat
function ns.UndercutText()
  local db = WorthListingDB
  if db.undercutMode == "percent" then
    return L.UNDERCUT_PERCENT:format(db.undercutPercent)
  elseif db.undercutMode == "fixed" then
    return L.UNDERCUT_FIXED:format(ns.Money(db.undercutFixed))
  elseif db.undercutMode == "auctionator" then
    local ok, text = pcall(function()
      local C = Auctionator.Config
      if C.Get(C.Options.AUCTION_SALES_PREFERENCE) == C.SalesTypes.PERCENTAGE then
        return ("%s %%"):format(C.Get(C.Options.UNDERCUT_PERCENTAGE))
      end
      return ns.Money(C.Get(C.Options.UNDERCUT_STATIC_VALUE))
    end)
    return ("%s (%s)"):format(L.UNDERCUT_AUCTIONATOR, ok and text or L.NOT_FOUND)
  end
  return L.UNDERCUT_NONE
end

-- Exact deposit from the game (only works while the auction house is open)
local function QueryDeposit(bag, slot, itemID, count, hours)
  local duration = DURATION_INDEX[hours]
  if not ahOpen or not duration or not C_AuctionHouse or not ItemLocation then return end
  local ok, deposit = pcall(function()
    local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if not C_Item.DoesItemExist(location) then return end
    if C_AuctionHouse.GetItemCommodityStatus(location) == Enum.ItemCommodityStatus.Commodity then
      return C_AuctionHouse.CalculateCommodityDeposit(itemID, duration, count)
    end
    return C_AuctionHouse.CalculateItemDeposit(location, duration, count)
  end)
  if ok and type(deposit) == "number" then return deposit end
end

-- Learn the minimum or the rate of a duration from an exact value
local function Learn(deposit, vendor, hours)
  local db = WorthListingDB
  if deposit < db.min then
    db.min = deposit
  elseif deposit > db.min and vendor > 0 then
    db.rates[hours] = PercentShare(deposit, vendor)
  end
end

local function DepositKey(itemID, count, hours)
  return ("%d:%d:%d"):format(itemID, count, hours)
end

-- Asks the game for the exact deposit, saves it and learns from it; nil if not available
local function RecordDeposit(bag, slot, itemID, vendor, count, hours)
  local exact = QueryDeposit(bag, slot, itemID, count, hours)
  if exact then
    WorthListingDB.deposits[DepositKey(itemID, count, hours)] = exact
    Learn(exact, vendor, hours)
  end
  return exact
end

local function ItemID(link)
  return tonumber(link:match("item:(%d+)"))
end

-- Deposit and where it came from
local function GetDeposit(bag, slot, link, vendor, count)
  local db = WorthListingDB
  local itemID = ItemID(link)
  if itemID then
    local exact = RecordDeposit(bag, slot, itemID, vendor, count, db.hours)
    if exact then return exact, L.SOURCE_LIVE end
    local saved = db.deposits[DepositKey(itemID, count, db.hours)]
    if saved then return saved, L.SOURCE_SAVED end
  end
  local estimate = math.floor(PercentOf(vendor, db.rates[db.hours] or 0))
  return math.max(db.min, estimate), L.SOURCE_ESTIMATED
end

-- Reads the exact deposits of every sellable bag item for all durations,
-- so the tooltip knows them without hovering each item first
local function ScanBags()
  if not ahOpen then return end
  for bag = 0, LAST_BAG do
    for slot = 1, GetNumSlots(bag) or 0 do
      local link = GetBagLink(bag, slot)
      local itemID = link and ItemID(link)
      local sellPrice = itemID and select(11, GetInfo(link))
      if sellPrice and sellPrice > 0 then
        local count = math.max(1, GetBagCount(bag, slot) or 1)
        for _, hours in ipairs(DURATIONS) do
          RecordDeposit(bag, slot, itemID, sellPrice * count, count, hours)
        end
      end
    end
  end
end

local ZERO = "0|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"

-- The money formatting function has different names depending on the client
local CoinString = GetMoneyString
  or (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString)
  or GetCoinTextureString

local function Money(copper, signed)
  copper = math.floor(copper + 0.5)
  local text = copper == 0 and ZERO or CoinString(math.abs(copper))
  if copper < 0 then return "-" .. text end
  if signed and copper > 0 then return "+" .. text end
  return text
end
ns.Money = Money

local COLOR = {
  good = { 0.2, 1, 0.2 },
  bad = { 1, 0.3, 0.3 },
  warn = { 1, 0.82, 0 },
  muted = { 0.7, 0.7, 0.7 },
  value = { 1, 1, 1 },
  label = { 0.8, 0.8, 0.8 },
}
local INDENT = "  "

local function Line(tt, left, right, color)
  local lr, lg, lb = unpack(COLOR.label)
  local r, g, b = unpack(color or COLOR.value)
  tt:AddDoubleLine(INDENT .. left, right, lr, lg, lb, r, g, b)
end

local function AddLines(tt, bag, slot)
  local db = WorthListingDB
  if not db or not db.show then return end
  local link = GetBagLink(bag, slot)
  if not link then return end
  local market = GetMarketPrice(link)
  -- Item data not loaded yet: show nothing rather than wrong numbers
  local sellPrice = select(11, GetInfo(link))
  if not market or not sellPrice then return end
  local count = math.max(1, GetBagCount(bag, slot) or 1)

  local vendor = sellPrice * count
  local deposit, source = GetDeposit(bag, slot, link, vendor, count)
  local listing = GetListingPrice(market)
  local proceeds = math.floor(listing * count - PercentOf(listing * count, db.cut))
  local gain = proceeds - vendor

  tt:AddLine(" ")
  tt:AddLine(L.HEADER:format(ns.TITLE, count, db.hours), unpack(COLOR.warn))
  Line(tt, L.VENDOR, Money(vendor))
  Line(tt, L.AUCTION:format(Money(listing)), Money(proceeds))
  Line(tt, L.DEPOSIT:format(source), Money(deposit), COLOR.muted)
  Line(tt, L.PROFIT_SOLD, Money(gain, true), gain > 0 and COLOR.good or COLOR.bad)
  Line(tt, L.LOSS_UNSOLD, Money(-deposit), deposit > 0 and COLOR.bad or COLOR.muted)

  if gain <= 0 then
    Line(tt, L.VERDICT, L.VERDICT_VENDOR, COLOR.bad)
  elseif deposit <= 0 then
    Line(tt, L.BREAK_EVEN, L.UNLIMITED, COLOR.good)
  else
    -- How often the auction may expire before the deposits eat up the profit
    local fails = math.floor(gain / deposit)
    local color = fails >= SAFE_FAILS and COLOR.good or (fails >= 1 and COLOR.warn or COLOR.bad)
    Line(tt, L.BREAK_EVEN, tostring(fails), color)
  end
  tt:Show()
end

if TooltipDataProcessor and C_TooltipInfo then
  -- Modern tooltip path: also survives the tooltip being rebuilt
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt)
    if tt ~= GameTooltip then return end
    local info = tt.info or tt.processingInfo
    if info and info.getterName == "GetBagItem" and info.getterArgs and not info.excludeLines then
      AddLines(tt, unpack(info.getterArgs))
    end
  end)
else
  hooksecurefunc(GameTooltip, "SetBagItem", AddLines)
end

-- Settings ------------------------------------------------------------------

local function Copy(value)
  return type(value) == "table" and CopyTable(value) or value
end

-- Sets a player-adjustable number within its limits; returns the stored value.
-- "rate" means the deposit rate of the current duration.
function ns.Set(key, value)
  local low, high, whole = unpack(LIMITS[key])
  value = math.min(high, math.max(low, value))
  if whole then value = math.floor(value) end
  if key == "rate" then
    WorthListingDB.rates[WorthListingDB.hours] = value
  else
    WorthListingDB[key] = value
  end
  return value
end

function ns.SetHours(hours)
  if not DURATION_INDEX[hours] then return false end
  WorthListingDB.hours = hours
  return true
end

-- Forget learned deposits; keeps the player's other settings
function ns.ResetLearned()
  for _, key in ipairs({ "deposits", "min", "rates" }) do
    WorthListingDB[key] = Copy(defaults[key])
  end
end

-- Everything back to defaults
function ns.ResetAll()
  for key, value in pairs(defaults) do
    WorthListingDB[key] = Copy(value)
  end
end

local function InitDB()
  WorthListingDB = WorthListingDB or {}
  local db = WorthListingDB
  if (db.version or 0) < 3 then
    -- Up to version 2, Forever deposits were queried for 8h instead of 24h:
    -- saved deposits and learned rates are wrong
    db.deposits, db.rates = nil, nil
  end
  for key, value in pairs(defaults) do
    if db[key] == nil then db[key] = Copy(value) end
  end
  if not DURATION_INDEX[db.hours] then db.hours = defaults.hours end
  db.version = DB_VERSION
end

ns.DURATIONS = DURATIONS

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == ADDON then
    InitDB()
    if ns.BuildOptions then ns.BuildOptions() end
  elseif event == "AUCTION_HOUSE_SHOW" or event == "AUCTION_HOUSE_CLOSED" then
    ahOpen = event == "AUCTION_HOUSE_SHOW"
    ScanBags()
  elseif event == "BAG_UPDATE_DELAYED" then
    ScanBags() -- only does something while the auction house is open
  end
end)

-- Chat ----------------------------------------------------------------------

function ns.Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(("|cffffd100%s:|r %s"):format(ns.TITLE, msg))
end
local Print = ns.Print

-- English commands, German ones kept as aliases
local ALIASES = { gebuehr = "fee", anteil = "cut", stunden = "hours", an = "on", aus = "off" }

-- Number commands: setting key and the message that confirms it
local NUMBER_COMMANDS = {
  fee = { "rate", function(v) return L.CHAT_FEE_SET:format(WorthListingDB.hours, v) end },
  min = { "min", function(v) return L.CHAT_MIN_SET:format(Money(v)) end },
  cut = { "cut", function(v) return L.CHAT_CUT_SET:format(v) end },
}

SLASH_WORTHLISTING1 = "/worthlisting"
SLASH_WORTHLISTING2 = "/wl"
SlashCmdList.WORTHLISTING = function(input)
  local cmd, arg = strsplit(" ", (input or ""):lower(), 2)
  cmd = ALIASES[cmd] or cmd
  local num = tonumber(arg)
  local numberCommand = NUMBER_COMMANDS[cmd]
  if numberCommand and num then
    Print(numberCommand[2](ns.Set(numberCommand[1], num)))
  elseif cmd == "hours" and num and ns.SetHours(num) then
    Print(L.CHAT_HOURS_SET:format(num))
  elseif cmd == "reset" then
    ns.ResetLearned()
    Print(L.CHAT_RESET)
  elseif cmd == "on" or cmd == "off" then
    WorthListingDB.show = cmd == "on"
    Print(WorthListingDB.show and L.CHAT_SHOW_ON or L.CHAT_SHOW_OFF)
  elseif cmd == "" and ns.OpenOptions and ns.OpenOptions() then
    return
  else
    local db = WorthListingDB
    Print(L.CHAT_STATUS:format(db.hours, db.rates[db.hours] or 0, Money(db.min), db.cut))
    Print(L.CHAT_UNDERCUT:format(ns.UndercutText()))
    Print(L.CHAT_HELP:format(SLASH_WORTHLISTING2, table.concat(DURATIONS, "|")))
  end
end
