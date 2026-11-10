# Worth Listing

![AI: Used](https://img.shields.io/badge/AI-USED-orange)

A World of Warcraft add-on that answers one question right in the item tooltip:
**is this stack worth listing at the auction house, or should I just sell it to a vendor?**

Listing an item costs a deposit, and you lose that deposit every time the auction
expires unsold. Worth Listing puts the vendor value, your real auction proceeds and
the deposit side by side, for the whole stack you are hovering.

```
Worth Listing (stack of 11, 24h)
  Vendor                        11c
  Auction house (5c each)       52c
  Deposit (live)                1s
  Profit if sold                +41c
  Loss if unsold                -1s
  Break-even: failed attempts   0
```

**Break-even: failed attempts** tells you how often the auction may expire before the
lost deposits have eaten the extra profit over the vendor. `0` means a single failed
auction already leaves you worse off than the vendor.

## Features

- Works on the whole stack under your mouse, not just one item
- Uses your real listing price: lowest price minus your undercut (same as Auctionator, percent, fixed or off), minus the AH cut
- Exact deposit straight from the game while the auction house is open, remembered afterwards
- Learns the minimum deposit and the deposit rate by itself, so it keeps up with changes
- Options page under **Options → AddOns → Worth Listing**
- English and German

## Requirements

Prices come from [Auctionator](https://www.curseforge.com/wow/addons/auctionator)
(recommended). Auctioneer is supported as a fallback. Scan the auction house once so
prices are available.

## Usage

Hover an item in your bags. Open the auction house once and hover your items to let
the add-on learn the exact deposits.

| Command | Effect |
|---|---|
| `/wl` | Open the options page |
| `/wl status` | Print current settings |
| `/wl hours <12\|24>` | Auction duration |
| `/wl min <copper>` | Minimum deposit |
| `/wl fee <percent>` | Deposit in % of vendor price |
| `/wl cut <percent>` | AH cut on sale |
| `/wl reset` | Forget saved deposits |
| `/wl on` / `/wl off` | Show or hide the tooltip block |

## Translations

All strings live in [`Locales/`](Locales). English (`enUS.lua`) is the base; any
string a translation leaves out falls back to English.

To add a language:

1. Copy `Locales/deDE.lua` to your locale, e.g. `Locales/frFR.lua`
2. Change the locale code in the first line
3. Translate the strings
4. Add the file to `WorthListing.toc` below `Locales\deDE.lua`
5. Open a pull request

## Bugs and ideas

Please use the [issue tracker](https://github.com/Daniel-Leinberger/WorthListing/issues).

## License

[MIT](LICENSE)
