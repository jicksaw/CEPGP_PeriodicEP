CEPGP_PeriodicEP =
    LibStub("AceAddon-3.0"):NewAddon("CEPGP_PeriodicEP", "AceConsole-3.0", "AceTimer-3.0", "AceEvent-3.0")
local WakeupListener = {}
local L = LibStub("AceLocale-3.0"):GetLocale("CEPGP_PeriodicEP", true)

local options = {
    name = "CEPGP Periodic EP",
    type = "group",
    args = {
        status = {
            type = "description",
            fontSize = "medium",
            order = 0,
            name = function()
                return CEPGP_PeriodicEP.db.profile.enabled and "" or L["Plugin not enabled in the plugin manager"]
            end
        },
        show = {
            type = "execute",
            name = L["Show"],
            desc = L["Opens the options menu"],
            func = function()
                InterfaceOptionsFrame_OpenToCategory(CEPGP_PeriodicEP.optionsFrame)
                InterfaceOptionsFrame_OpenToCategory(CEPGP_PeriodicEP.optionsFrame)
            end,
            guiHidden = true
        },
        start = {
            type = "execute",
            name = "Start/Resume",
            desc = "Resumes the ticking EP",
            order = 10,
            disabled = function()
                return CEPGP_PeriodicEP.tickerState == "running" or not CEPGP_PeriodicEP:IsEnabled()
            end,
            func = function()
                if CEPGP_PeriodicEP.tickerState == "stopped" then
                    CEPGP_PeriodicEP:TickerStart()
                elseif CEPGP_PeriodicEP.tickerState == "paused" then
                    CEPGP_PeriodicEP:TickerResume()
                end
            end
        },
        pause = {
            type = "execute",
            name = "Pause",
            desc = "Pauses the ticking EP",
            order = 11,
            disabled = function()
                return CEPGP_PeriodicEP.tickerState ~= "running"
            end,
            func = function()
                CEPGP_PeriodicEP:TickerPause()
            end
        },
        toggle = {
            type = "execute",
            name = "Toggle",
            desc = "Starts or pauses the ticking EP",
            guiHidden = true,
            func = function()
                if CEPGP_PeriodicEP.tickerState == "stopped" then
                    CEPGP_PeriodicEP:TickerStart()
                elseif CEPGP_PeriodicEP.tickerState == "paused" then
                    CEPGP_PeriodicEP:TickerResume()
                elseif CEPGP_PeriodicEP.tickerState == "running" then
                    CEPGP_PeriodicEP:TickerPause()
                end
            end
        },
        periodic_ep = {
            type = "group",
            name = "Periodic EP",
            order = 0,
            args = {
                period = {
                    type = "range",
                    name = L["Period"],
                    desc = L["Time between EP ticks (1–120, minutes)"],
                    min = 1,
                    max = 120,
                    softMax = 30,
                    step = 1,
                    get = function()
                        return CEPGP_PeriodicEP.db.profile.period
                    end,
                    set = function(info, input)
                        CEPGP_PeriodicEP.db.profile.period = input
                    end
                },
                amount = {
                    type = "range",
                    name = L["Amount"],
                    desc = L["EP awarded per tick (0–9999)"],
                    min = 0,
                    max = 9999,
                    softMax = 1000,
                    step = 1,
                    bigStep = 10,
                    get = function()
                        return CEPGP_PeriodicEP.db.profile.amount
                    end,
                    set = function(info, input)
                        CEPGP_PeriodicEP.db.profile.amount = input
                    end
                }
            }
        },
        reminder = {
            type = "group",
            name = "Start Reminder",
	    get = function(info, key)
		return CEPGP_PeriodicEP.db.profile.warnIfNotRunning[key]
	    end,
	    set = function(info, key, value)
		CEPGP_PeriodicEP.db.profile.warnIfNotRunning[key] = value
	    end,
            args = {
                desc = {
                    type = "description",
                    order = 0,
                    name = L["Remind to start Periodic EP in an instance"]
                },
		vanilla = {
		    type = "multiselect",
		    name = "Vanilla",
		    values = {
			[249] = "Onyxia",
			[409] = "Molten Core",
			[469] = "Blackwing Lair",
			[309] = "Zul'gurub",
			[509] = "Ruins of Ahn'Qiraj (AQ20)",
			[531] = "Temple of Ahn'Qiraj (AQ40)",
			[533] = "Naxxramas"
		    },
		},
		tbc = {
		    type = "multiselect",
		    name = "The Burning Crusade",
		    values = {
			[532] = "Karazhan",
			[565] = "Gruul's Lair",
			[544] = "Magtheridon's Lair",
			[548] = "Serpentshrine Cavern",
			[550] = "Tempest Keep",
			[534] = "Hyjal Summit",
			[564] = "Black Temple",
			[580] = "Sunwell Plateau",
		    },
		},
	    }
	}
    }
}

local defaults = {
    profile = {
        enabled = false,
        period = 15,
        amount = 5,
        warnIfNotRunning = {}
    }
}

function CEPGP_PeriodicEP:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("CEPGP_PeriodicEP_DB", defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("CEPGP_PeriodicEP", options, {"pep", "periodicep"})

    self.optionsFrame =
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("CEPGP_PeriodicEP", L["CEPGP Periodic EP"])
    self.optionsFrame.default = function()
        self:SetDefaultOptions()
    end

    self:SetEnabledState(self.db.profile.enabled and IsInRaid("LE_PARTY_CATEGORY_HOME") and IsMasterLooter())
    CEPGP_addPlugin("CEPGP_PeriodicEP", self.optionsFrame, self.db.profile.enabled, self.ToggleEnabled)

    -- Plugin is only enabled when in a raid
    -- This uses a separate namespace to avoid being automatically unregistered when the addon is disabled
    self.RegisterEvent(WakeupListener, "GROUP_ROSTER_UPDATE")
end

function CEPGP_PeriodicEP:OnEnable()
    self:Print("Enabled")
    if not start_periodic_ep_button then
        start_periodic_ep_button = CreateFrame("Button", nil, CEPGP_raid, "GameMenuButtonTemplate")
        start_periodic_ep_button:SetText("Start Periodic EP")
        start_periodic_ep_button:SetWidth(120)
        start_periodic_ep_button:SetHeight(21)
        start_periodic_ep_button:SetPoint("BOTTOMRIGHT", -10, 25)
        start_periodic_ep_button:SetScript(
            "OnClick",
            function()
                PlaySound(799)
                CEPGP_PeriodicEP:TickerStart()
            end
        )
    end

    if not pause_periodic_ep_button then
        pause_periodic_ep_button = CreateFrame("Button", nil, CEPGP_raid, "GameMenuButtonTemplate")
        pause_periodic_ep_button:SetText("Pause Periodic EP")
        pause_periodic_ep_button:SetWidth(120)
        pause_periodic_ep_button:SetHeight(21)
        pause_periodic_ep_button:SetPoint("BOTTOMRIGHT", -10, 25)
        pause_periodic_ep_button:SetScript(
            "OnClick",
            function()
                PlaySound(799)
                CEPGP_PeriodicEP:TickerPause()
            end
        )
    end

    pause_periodic_ep_button:Hide()
    start_periodic_ep_button:Show()

    self:RegisterWarnings()

    self.tickerState = "stopped"
end

function CEPGP_PeriodicEP:OnDisable()
    self:Print("Disabled")
    if self.tickerTimer then
        self:CancelTimer(self.tickerTimer)
    end
    StaticPopup_Hide("PERIODIC_EP_NOT_STARTED")
end

-- This uses a separate namespace to avoid being automatically unregistered when the addon is disabled
function WakeupListener.GROUP_ROSTER_UPDATE()
    if not CEPGP_PeriodicEP.db.profile.enabled then
        return
    end

    if IsInRaid("LE_PARTY_CATEGORY_HOME") and IsMasterLooter() and not CEPGP_PeriodicEP:IsEnabled() then
        CEPGP_PeriodicEP:Enable()
    elseif (not IsInRaid("LE_PARTY_CATEGORY_HOME") or not IsMasterLooter()) and CEPGP_PeriodicEP:IsEnabled() then
        CEPGP_PeriodicEP:Disable()
    end
end

-- Callback from CEPGP plugin management panel
function CEPGP_PeriodicEP.ToggleEnabled()
    CEPGP_PeriodicEP.db.profile.enabled = not CEPGP_PeriodicEP.db.profile.enabled
    if CEPGP_PeriodicEP.db.profile.enabled then
        if IsInRaid("LE_PARTY_CATEGORY_HOME") then
            CEPGP_PeriodicEP:Enable()
        end
    else
        CEPGP_PeriodicEP:Disable()
    end
end

function CEPGP_PeriodicEP:SetDefaultOptions()
    self.db:ResetDB()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("CEPGP_PeriodicEP") -- TODO: Test if necessary
    self:Print("All profiles reset")
end
