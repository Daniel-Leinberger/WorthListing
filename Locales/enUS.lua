-- English base strings. Every other locale only overrides these;
-- any string a translation leaves out falls back to English.
--
-- Adding a language: copy deDE.lua, change the locale code in the first
-- line, translate the strings and add the file to the .toc.

local _, ns = ...

ns.TITLE = "Worth Listing"

ns.L = {
  -- Tooltip
  HEADER = "%s (stack of %d, %dh)",
  VENDOR = "Vendor",
  AUCTION = "Auction house (%s each)",
  DEPOSIT = "Deposit (%s)",
  SOURCE_LIVE = "live",
  SOURCE_SAVED = "saved",
  SOURCE_ESTIMATED = "estimated",
  PROFIT_SOLD = "Profit if sold",
  LOSS_UNSOLD = "Loss if unsold",
  VERDICT = "Verdict",
  VERDICT_VENDOR = "Vendor it!",
  BREAK_EVEN = "Break-even: failed attempts",
  UNLIMITED = "unlimited",

  -- Undercut description
  UNDERCUT_PERCENT = "%s %% below the lowest price",
  UNDERCUT_FIXED = "%s per item below the lowest price",
  UNDERCUT_AUCTIONATOR = "Same as Auctionator",
  NOT_FOUND = "not found",
  UNDERCUT_NONE = "None (lowest price)",

  -- Chat
  CHAT_FEE_SET = "Deposit (%dh) = %s %% of vendor price",
  CHAT_MIN_SET = "Minimum deposit = %s",
  CHAT_CUT_SET = "AH cut = %s %%",
  CHAT_HOURS_SET = "Duration = %dh",
  CHAT_RESET = "Saved deposits cleared, minimum and rates reset.",
  CHAT_SHOW_ON = "Tooltip on",
  CHAT_SHOW_OFF = "Tooltip off",
  CHAT_STATUS = "Duration %dh, deposit %.1f %% (min. %s), AH cut %s %%",
  CHAT_UNDERCUT = "Undercut: %s",
  CHAT_HELP = "%s (options)  |  status  |  hours <%s>  |  min <copper>  |  fee <percent>  |  cut <percent>  |  reset  |  on  |  off",

  -- Options page
  OPT_SUBTITLE = "Shows in the tooltip whether a stack is worth listing at the auction house.",
  OPT_SHOW = "Show in tooltip",
  OPT_DURATION = "Auction duration",
  OPT_MIN = "Minimum deposit (in copper)",
  OPT_RATE = "Deposit in %% of vendor price (%dh)",
  OPT_CUT = "AH cut on sale (in %)",
  OPT_UNDERCUT = "Undercut the lowest price",
  MODE_AUCTIONATOR = "Same as Auctionator",
  MODE_PERCENT = "Percent",
  MODE_FIXED = "Fixed",
  MODE_NONE = "Off",
  OPT_PERCENT = "Percent (in %)",
  OPT_FIXED = "Fixed (copper per item)",
  OPT_WHERE = "Where to show",
  OPT_WHERE_HINT = "Choose in which tooltips the block appears. Where the amount is unknown "
    .. "(e.g. chat links), it calculates with one item.",
  OPT_ALL_ON = "All on",
  OPT_ALL_OFF = "All off",
  OPT_DEFAULT = "Default",
  TT_BAGS = "Bags",
  TT_BANK = "Bank",
  TT_CHARACTER = "Equipped items",
  TT_AUCTION = "Auction house (incl. Auctionator)",
  TT_MERCHANT = "Merchant (buy and buyback)",
  TT_LOOT = "Loot and loot rolls",
  TT_QUEST = "Quest rewards",
  TT_MAIL = "Mail",
  TT_TRADE = "Trade window",
  TT_CRAFTING = "Professions",
  TT_CHAT = "Chat links",
  TT_OTHER = "Everything else (e.g. other add-ons)",
  TT_COMPARISON = "Comparison tooltips",
  OPT_ADVANCED = "Advanced: fees",
  OPT_ADVANCED_HINT = "Worth Listing learns these values by itself: whenever you open the auction house, "
    .. "it reads the exact deposits of all items in your bags. You normally do not need to change them. "
    .. "Only correct them if the deposit in the tooltip differs from the one the auction house shows.",
  OPT_MIN_DESC = "The lowest deposit the auction house charges, however cheap the item is.",
  OPT_RATE_DESC = "The deposit is this share of the stack's vendor price and grows with the auction "
    .. "duration. Used to estimate the deposit until the add-on has seen the exact amount.",
  OPT_CUT_DESC = "The share of the sale price the auction house keeps when your auction sells.",
  OPT_STATUS = "Current state",
  STATUS_DURATION = "Duration: |cffffffff%dh|r",
  STATUS_MIN = "Minimum deposit: %s",
  STATUS_RATE = "Deposit: |cffffffff%.1f %%|r of vendor price",
  STATUS_CUT = "AH cut on sale: |cffffffff%s %%|r",
  STATUS_UNDERCUT = "Undercut: |cffffffff%s|r",
  STATUS_KNOWN = "Saved real deposits: |cffffffff%d|r",
  OPT_RESET = "Reset saved deposits",
  OPT_BUILD_ERROR = "Could not create the options page: %s",
}
