**Summary (one line, for the CurseForge "Summary" field):**

Shows in the tooltip whether a stack is worth listing at the auction house, after undercut, AH cut and deposit.

---

**Description (paste below into the CurseForge description, Markdown):**

# Worth Listing

![AI: Used](https://img.shields.io/badge/AI-USED-orange)

**Is this stack worth listing, or should I just vendor it?**

You know the feeling: the auction house shows a slightly higher price than the vendor, you list the item, someone undercuts you, the auction expires, and your deposit is gone. Do that twice and you would have been better off at the vendor.

**Worth Listing** answers that question right in the item tooltip, for the whole stack under your mouse.

```
Worth Listing (stack of 11, 24h)
  Vendor                        11c
  Auction house (5c each)       52c
  Deposit (live)                1s
  Profit if sold                +41c
  Loss if unsold                -1s
  Break-even: failed attempts   0
```

## What the lines mean

- **Vendor**: what the vendor pays for the whole stack
- **Auction house**: your listing price per item (lowest price minus your undercut) and what you actually receive for the stack after the AH cut
- **Deposit**: the listing fee for this stack. *live* = exact value from the game, *saved* = remembered from your last auction house visit, *estimated* = calculated
- **Profit if sold**: how much more you get than from the vendor
- **Loss if unsold**: the deposit you lose if the auction expires
- **Break-even: failed attempts**: how often the auction may expire before the lost deposits have eaten your extra profit. **0** (red) means one failed auction already makes it worse than vendoring. If the auction house pays less than the vendor anyway, it simply says **Vendor it!**

## Features

- Calculates the **whole stack**, no more mental math
- Uses **your real listing price**: undercut the same way as Auctionator, by percent, by a fixed amount, or not at all
- Reads the **exact deposits** of all your bag items automatically when you open the auction house and remembers them
- **Learns** the minimum deposit and the deposit rate by itself, so it keeps up when Blizzard changes them
- Options page under **Options → AddOns → Worth Listing**, or type **/wl**
- **English and German**, more languages welcome

## Requirements

Prices come from **Auctionator** (recommended); Auctioneer is supported as a fallback. Scan the auction house once so prices are available.

**Tip:** open the auction house once. Worth Listing reads the exact deposits of everything in your bags, so it knows them even after you close the auction house.

## Commands

- **/wl**: open the options
- **/wl status**: print the current settings
- **/wl hours 24**: auction duration (2, 8 or 24 on WoW Forever)
- **/wl min &lt;copper&gt;**: minimum deposit
- **/wl reset**: forget saved deposits
- **/wl on** / **/wl off**: show or hide the tooltip block

## Translations, bugs and ideas

Source code, issue tracker and translation guide: **https://github.com/Daniel-Leinberger/WorthListing**

Want Worth Listing in your language? Copy one locale file, translate it and open a pull request. It takes about ten minutes.
