-- Tooltip lines for bag items: compares the vendor price with the auction
-- house proceeds (after undercut and AH cut) for the whole stack and accounts
-- for the deposit that is lost when the auction does not sell.
--
-- Deposit:
--   AH open   -> exact value from the game, saved for later
--   AH closed -> saved value, otherwise estimate: max(minimum, vendor price * rate)
--   Minimum and rate are learned from every exact value.

local ADDON, ns = ...
local L = ns.L
local DB_VERSION = 2

local defaults = {
  cut = 5,       -- share the AH keeps on sale, in %
  hours = 24,    -- auction duration
  min = 100,     -- minimum deposit in copper
  rates = { [12] = 15, [24] = 30, [48] = 60 }, -- deposit in % of vendor price per duration
  deposits = {}, -- saved exact deposits: "itemID:count:hours" -> copper
  undercutMode = "auctionator", -- "auctionator", "percent", "fixed" or "none"
  undercutPercent = 5,          -- undercut by x % (mode "percent")
  undercutFixed = 1,            -- undercut by x copper per item (mode "fixed")
  show = true,
}

local DURATION_INDEX = { [12] = 1, [24] = 2, [48] = 3 }

local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo

local ahOpen = false

local function GetBagLink(bag, slot)
  if C_Container and C_Container.GetContainerItemLink then
    return C_Container.GetContainerItemLink(bag, slot)
  end
  return GetContainerItemLink(bag, slot)
end

local function GetBagCount(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local info = C_Container.GetContainerItemInfo(bag, slot)
    return info and info.stackCount
  end
  local _, count = GetContainerItemInfo(bag, slot)
  return count
end

-- Market value per item: Auctionator first, then Auctioneer
local function GetMarketPrice(link)
  if Auctionator and Auctionator.API and Auctionator.API.v1
     and Auctionator.API.v1.GetAuctionPriceByItemLink then
    local ok, value = pcall(Auctionator.API.v1.GetAuctionPriceByItemLink, ADDON, link)
    if ok and value and value > 0 then return value end
  end
  if AucAdvanced and AucAdvanced.API and AucAdvanced.API.GetMarketValue then
    local ok, value = pcall(AucAdvanced.API.GetMarketValue, link)
    if ok and value and value > 0 then return value end
  end
end

-- Our listing price per item: lowest price minus undercut
local function GetListingPrice(market)
  local db = WorthListingDB
  local price
  if db.undercutMode == "auctionator" then
    if Auctionator and Auctionator.Selling and Auctionator.Selling.CalculateItemPriceFromPrice then
      local ok, value = pcall(Auctionator.Selling.CalculateItemPriceFromPrice, market)
      if ok and type(value) == "number" then price = value end
    end
  elseif db.undercutMode == "percent" then
    price = market * (100 - db.undercutPercent) / 100
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
local function QueryDeposit(bag, slot, itemID, count)
  if not ahOpen or not C_AuctionHouse or not ItemLocation then return end
  local duration = DURATION_INDEX[WorthListingDB.hours]
  if not duration then return end
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

-- Learn the minimum or the rate from an exact value
local function Learn(deposit, raw)
  if deposit < WorthListingDB.min then
    WorthListingDB.min = deposit
  elseif deposit > WorthListingDB.min and raw > 0 then
    WorthListingDB.rates[WorthListingDB.hours] = deposit * 100 / raw
  end
end

-- Deposit and where it came from
local function GetDeposit(bag, slot, link, sellPrice, count)
  local itemID = tonumber(link:match("item:(%d+)"))
  local key = ("%s:%d:%d"):format(itemID or link, count, WorthListingDB.hours)
  local raw = sellPrice * count

  local exact = itemID and QueryDeposit(bag, slot, itemID, count)
  if exact then
    WorthListingDB.deposits[key] = exact
    Learn(exact, raw)
    return exact, L.SOURCE_LIVE
  end
  if WorthListingDB.deposits[key] then
    return WorthListingDB.deposits[key], L.SOURCE_SAVED
  end
  local rate = WorthListingDB.rates[WorthListingDB.hours] or 0
  return math.max(WorthListingDB.min, math.floor(raw * rate / 100)), L.SOURCE_ESTIMATED
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

local GREEN, RED, YELLOW, GREY, WHITE = { 0.2, 1, 0.2 }, { 1, 0.3, 0.3 }, { 1, 0.82, 0 }, { 0.7, 0.7, 0.7 }, { 1, 1, 1 }

local function Line(tt, left, right, color)
  local r, g, b = unpack(color or WHITE)
  tt:AddDoubleLine("  " .. left, right, 0.8, 0.8, 0.8, r, g, b)
end

-- Pure calculation without the tooltip (testable)
local function Calculate(sellPrice, listing, count, deposit, cut)
  local vendor = sellPrice * count
  local ahNet = math.floor(listing * count * (1 - cut / 100))
  local gain = ahNet - vendor
  local fails
  if gain > 0 and deposit > 0 then
    -- How often the auction may expire before the deposits eat up the profit
    fails = math.floor(gain / deposit)
  end
  return vendor, ahNet, gain, fails
end

local function AddLines(tt, bag, slot)
  if not WorthListingDB or not WorthListingDB.show then return end
  local link = GetBagLink(bag, slot)
  if not link then return end
  local market = GetMarketPrice(link)
  if not market then return end
  local sellPrice = select(11, GetInfo(link)) or 0
  local count = GetBagCount(bag, slot)
  count = (count and count > 0) and count or 1

  local deposit, source = GetDeposit(bag, slot, link, sellPrice, count)
  local listing = GetListingPrice(market)
  local vendor, ahNet, gain, fails = Calculate(sellPrice, listing, count, deposit, WorthListingDB.cut)

  tt:AddLine(" ")
  tt:AddLine(L.HEADER:format(ns.TITLE, count, WorthListingDB.hours), 1, 0.82, 0)
  Line(tt, L.VENDOR, Money(vendor))
  Line(tt, L.AUCTION:format(Money(listing)), Money(ahNet))
  Line(tt, L.DEPOSIT:format(source), Money(deposit), GREY)
  Line(tt, L.PROFIT_SOLD, Money(gain, true), gain > 0 and GREEN or RED)
  Line(tt, L.LOSS_UNSOLD, Money(-deposit), deposit > 0 and RED or GREY)

  if gain <= 0 then
    Line(tt, L.VERDICT, L.VERDICT_VENDOR, RED)
  elseif not fails then
    Line(tt, L.BREAK_EVEN, L.UNLIMITED, GREEN)
  else
    local color = fails >= 3 and GREEN or (fails >= 1 and YELLOW or RED)
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

local function InitDB()
  WorthListingDB = WorthListingDB or {}
  if (WorthListingDB.version or 1) < 2 then
    -- Version 1 used 48h and a single rate
    WorthListingDB.hours = nil
    WorthListingDB.rate = nil
  end
  for k, v in pairs(defaults) do
    if WorthListingDB[k] == nil then
      WorthListingDB[k] = type(v) == "table" and CopyTable(v) or v
    end
  end
  WorthListingDB.version = DB_VERSION
end

local function ResetLearned()
  WorthListingDB.deposits = {}
  WorthListingDB.min = defaults.min
  WorthListingDB.rates = CopyTable(defaults.rates)
end

ns.defaults = defaults
ns.DURATION_INDEX = DURATION_INDEX
ns.ResetLearned = ResetLearned

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
frame:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == ADDON then
    InitDB()
    if ns.BuildOptions then ns.BuildOptions() end
  elseif event == "AUCTION_HOUSE_SHOW" then
    ahOpen = true
  elseif event == "AUCTION_HOUSE_CLOSED" then
    ahOpen = false
  end
end)

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(("|cffffd100%s:|r %s"):format(ns.TITLE, msg))
end

-- English commands, German ones kept as aliases
local ALIASES = { gebuehr = "fee", anteil = "cut", stunden = "hours", an = "on", aus = "off" }

SLASH_WORTHLISTING1 = "/worthlisting"
SLASH_WORTHLISTING2 = "/wl"
SlashCmdList.WORTHLISTING = function(input)
  local cmd, arg = strsplit(" ", (input or ""):lower(), 2)
  cmd = ALIASES[cmd] or cmd
  local num = tonumber(arg)
  if cmd == "fee" and num then
    WorthListingDB.rates[WorthListingDB.hours] = num
    Print(L.CHAT_FEE_SET:format(WorthListingDB.hours, num))
  elseif cmd == "min" and num then
    WorthListingDB.min = num
    Print(L.CHAT_MIN_SET:format(Money(num)))
  elseif cmd == "cut" and num then
    WorthListingDB.cut = num
    Print(L.CHAT_CUT_SET:format(num))
  elseif cmd == "hours" and DURATION_INDEX[num] then
    WorthListingDB.hours = num
    Print(L.CHAT_HOURS_SET:format(num))
  elseif cmd == "reset" then
    ResetLearned()
    Print(L.CHAT_RESET)
  elseif cmd == "on" or cmd == "off" then
    WorthListingDB.show = (cmd == "on")
    Print(WorthListingDB.show and L.CHAT_SHOW_ON or L.CHAT_SHOW_OFF)
  elseif cmd == "" and ns.OpenOptions and ns.OpenOptions() then
    return
  else
    local rate = WorthListingDB.rates[WorthListingDB.hours] or 0
    Print(L.CHAT_STATUS:format(WorthListingDB.hours, rate, Money(WorthListingDB.min), WorthListingDB.cut))
    Print(L.CHAT_UNDERCUT:format(ns.UndercutText()))
    Print(L.CHAT_HELP:format(SLASH_WORTHLISTING2))
  end
end
