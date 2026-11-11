# Worth Listing

![AI: Used](https://img.shields.io/badge/AI-USED-orange)

A World of Warcraft add-on that answers one question right in the item tooltip:
**is this stack worth listing at the auction house, or should I just sell it to a vendor?**

Made for **WoW Forever**.

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
lost deposits have eaten the extra profit over the vendor. `0` (red) means a single
failed auction already leaves you worse off than the vendor, 1–2 is yellow, 3 or more
green. If the auction house pays less than the vendor anyway, it says **Vendor it!**

## Features

- Works on the whole stack under your mouse, not just one item
- Shows in every item tooltip: bags, bank, auction house and Auctionator, merchant, loot, quest rewards, mail, trade, chat links and more; one checkbox per place. Where the amount is unknown (e.g. chat links) it calculates with one item
- Uses your real listing price: lowest price minus your undercut (same as Auctionator, percent, fixed or off), minus the AH cut
- Exact deposits of all bag items read automatically when you open the auction house, remembered afterwards
- Learns the minimum deposit and the deposit rate by itself, so it keeps up with changes
- Options page under **Options → AddOns → Worth Listing**, with every setting explained
- English and German

## Requirements

Prices come from [Auctionator](https://www.curseforge.com/wow/addons/auctionator).
Scan the auction house once so prices are available. If Auctionator is missing, the
add-on falls back to Auctioneer; that path has not been tested in the game yet.

## Usage

Hover any item. Whenever you open the auction house, the add-on reads the exact
deposits of all items in your bags, so the tooltip knows them afterwards too.
Choose where the block appears under **Where to show** on the options page.

| Command | Effect |
|---|---|
| `/wl` | Open the options page |
| `/wl status` | Print current settings |
| `/wl hours <hours>` | Auction duration (2, 8 or 24 on WoW Forever) |
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
