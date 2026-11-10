# Changelog

## v1.0.1

- Fix: on WoW Forever the deposit was calculated for 8 hours instead of 24 hours. Forever uses the durations 2/8/24 hours, other clients 12/24/48; the add-on now picks the right set for your client
- Saved deposits and learned rates from v1.0.0 are reset once, because they came from the wrong duration
- Options page shows all three durations of your client
- Values from chat commands are now checked the same way as on the options page (e.g. AH cut at most 99 %, no negative amounts)
- Shows nothing instead of wrong numbers while item data is still loading
- "Defaults" on the options page now resets every setting
- Options page scrolls when it does not fit; the scroll bar only appears when needed

## v1.0.0

First public release.

- Tooltip block for bag items: vendor value, auction proceeds after undercut and AH cut, deposit, profit if sold, loss if unsold and break-even (failed attempts)
- Exact deposit from the game while the auction house is open, saved for later; estimate otherwise
- Learns the minimum deposit and the deposit rate automatically
- Undercut: same as Auctionator, percent, fixed amount or off
- Options page under Options → AddOns, slash command `/wl`
- English and German
