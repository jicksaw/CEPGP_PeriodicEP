local L = LibStub("AceLocale-3.0"):GetLocale("CEPGP_PeriodicEP", true)

function CEPGP_PeriodicEP:RegisterWarnings()
    StaticPopupDialogs["PERIODIC_EP_NOT_STARTED"] = {
	text = L["Start periodic EP?"],
	button1 = "Yes",
	button2 = "No",
	OnAccept = function()
	    CEPGP_PeriodicEP:TickerStart()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
    }

    self:RegisterEvent("PLAYER_ENTERING_WORLD", "EnteredInstance")
    -- Call it once in case we're already in an instance
    self:EnteredInstance()
end

function CEPGP_PeriodicEP:EnteredInstance()
    local _, type, _, _, _, _, _, instanceID = GetInstanceInfo()
    if self.db.profile.warnIfNotRunning[instanceID] and self.tickerState ~= "running" then
	StaticPopup_Show("PERIODIC_EP_NOT_STARTED")
    end
end
