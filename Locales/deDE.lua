if GetLocale() ~= "deDE" then return end

-- German translation. Strings left out here are shown in English.

local _, ns = ...
local L = ns.L

-- Tooltip
L.HEADER = "%s (%d Stück, %dh)"
L.VENDOR = "Händler"
L.AUCTION = "Auktionshaus (je %s)"
L.DEPOSIT = "Einstellgebühr (%s)"
L.SOURCE_LIVE = "live"
L.SOURCE_SAVED = "gemerkt"
L.SOURCE_ESTIMATED = "geschätzt"
L.PROFIT_SOLD = "Gewinn bei Verkauf"
L.LOSS_UNSOLD = "Verlust ohne Verkauf"
L.VERDICT = "Fazit"
L.VERDICT_VENDOR = "Händler!"
L.BREAK_EVEN = "Break-Even: Fehlversuche"
L.UNLIMITED = "unbegrenzt"

-- Undercut description
L.UNDERCUT_PERCENT = "%s %% unter dem niedrigsten Preis"
L.UNDERCUT_FIXED = "%s pro Stück unter dem niedrigsten Preis"
L.UNDERCUT_AUCTIONATOR = "Wie Auctionator"
L.NOT_FOUND = "nicht gefunden"
L.UNDERCUT_NONE = "Keine (niedrigster Preis)"

-- Chat
L.CHAT_FEE_SET = "Einstellgebühr (%dh) = %s %% vom Händlerpreis"
L.CHAT_MIN_SET = "Mindest-Einstellgebühr = %s"
L.CHAT_CUT_SET = "AH-Anteil = %s %%"
L.CHAT_HOURS_SET = "Laufzeit = %dh"
L.CHAT_RESET = "Gemerkte Gebühren gelöscht, Minimum und Sätze zurückgesetzt."
L.CHAT_SHOW_ON = "Tooltip an"
L.CHAT_SHOW_OFF = "Tooltip aus"
L.CHAT_STATUS = "Laufzeit %dh, Gebühr %.1f %% (mind. %s), AH-Anteil %s %%"
L.CHAT_UNDERCUT = "Unterbieten: %s"
L.CHAT_HELP = "%s (Optionen)  |  status  |  stunden <%s>  |  min <Kupfer>  |  gebuehr <Prozent>  |  anteil <Prozent>  |  reset  |  an  |  aus"

-- Options page
L.OPT_SUBTITLE = "Zeigt im Tooltip, ob sich ein Stack im Auktionshaus lohnt."
L.OPT_SHOW = "Im Tooltip anzeigen"
L.OPT_DURATION = "Laufzeit der Auktion"
L.OPT_MIN = "Mindest-Einstellgebühr (in Kupfer)"
L.OPT_RATE = "Gebühr in %% vom Händlerpreis (%dh)"
L.OPT_CUT = "AH-Anteil beim Verkauf (in %)"
L.OPT_UNDERCUT = "Unterbieten des niedrigsten Preises"
L.MODE_AUCTIONATOR = "Wie Auctionator"
L.MODE_PERCENT = "Prozent"
L.MODE_FIXED = "Fixwert"
L.MODE_NONE = "Aus"
L.OPT_PERCENT = "Prozent (in %)"
L.OPT_FIXED = "Fixwert (in Kupfer pro Stück)"
L.OPT_ADVANCED = "Erweitert: Gebühren"
L.OPT_ADVANCED_HINT = "Diese Werte lernt Worth Listing selbst: Sobald du das Auktionshaus öffnest, liest es "
  .. "die genauen Einstellgebühren aller Items in deinen Taschen aus. Normalerweise musst du hier nichts "
  .. "ändern. Korrigiere sie nur, wenn die Einstellgebühr im Tooltip von der im Auktionshaus abweicht."
L.OPT_MIN_DESC = "Die niedrigste Einstellgebühr, die das Auktionshaus verlangt, egal wie billig das Item ist."
L.OPT_RATE_DESC = "Die Einstellgebühr ist dieser Anteil vom Händlerpreis des Stacks und steigt mit der "
  .. "Laufzeit. Damit schätzt das Add-on die Gebühr, bis es den genauen Betrag kennt."
L.OPT_CUT_DESC = "Der Anteil vom Verkaufspreis, den das Auktionshaus einbehält, wenn deine Auktion verkauft wird."
L.OPT_STATUS = "Aktueller Stand"
L.STATUS_DURATION = "Laufzeit: |cffffffff%dh|r"
L.STATUS_MIN = "Mindest-Einstellgebühr: %s"
L.STATUS_RATE = "Gebühr: |cffffffff%.1f %%|r vom Händlerpreis"
L.STATUS_CUT = "AH-Anteil beim Verkauf: |cffffffff%s %%|r"
L.STATUS_UNDERCUT = "Unterbieten: |cffffffff%s|r"
L.STATUS_KNOWN = "Gemerkte echte Gebühren: |cffffffff%d|r"
L.OPT_RESET = "Gemerkte Gebühren zurücksetzen"
L.OPT_BUILD_ERROR = "Optionsseite konnte nicht erstellt werden: %s"
