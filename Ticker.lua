function CEPGP_PeriodicEP:TickerStart()
  if self.tickerState ~= "stopped" then
    return
  end

  self.tickerState = "running"
  start_periodic_ep_button:Hide()
  pause_periodic_ep_button:Show()

  self:CancelTimer(self.tickerTimer)
  self.tickerTimer = self:ScheduleRepeatingTimer(self.TickerTimerCallback, self.db.profile.period * 60, self)

  local message =
    "Periodic EP started: " .. self.db.profile.amount .. " EP every " .. self.db.profile.period .. " minutes"
  CEPGP_sendChatMessage(message, CEPGP.Channel)
end

function CEPGP_PeriodicEP:TickerPause()
  if self.tickerState ~= "running" then
    return
  end

  self.tickerState = "paused"
  pause_periodic_ep_button:Disable()

  self.ticker_timer_remaining = self:TimeLeft(self.tickerTimer)
  self.ticker_timer_leftover = self.db.profile.period * 60 - self.ticker_timer_remaining
  self:CancelTimer(self.tickerTimer)
  periodic_ep_ticker_paused_dialog:Show()

  local message = "Periodic EP paused"
  CEPGP_sendChatMessage(message, CEPGP.Channel)
end

function CEPGP_PeriodicEP:TickerResume()
  if self.tickerState ~= "paused" then
    return
  end

  self.tickerState = "running"
  pause_periodic_ep_button:Enable()

  self.tickerTimer = self:ScheduleTimer(self.TickerTimerResumeCallback, self.ticker_timer_remaining, self)
  periodic_ep_ticker_paused_dialog:Hide()

  local message = "Periodic EP resumed"
  CEPGP_sendChatMessage(message, CEPGP.Channel)
end

function CEPGP_PeriodicEP:TickerStop()
  if self.tickerState ~= "paused" then
    return
  end

  self.tickerState = "stopped"
  pause_periodic_ep_button:Hide()
  pause_periodic_ep_button:Enable()
  start_periodic_ep_button:Show()

  periodic_ep_ticker_paused_dialog:Hide()
  periodic_ep_ticker_stopped_dialog:Show()
end

function CEPGP_PeriodicEP:TickerAwardLeftover(minutes)
  start_periodic_ep_button:Enable()
  periodic_ep_ticker_stopped_dialog:Hide()

  if minutes <= 0 then
    CEPGP_sendChatMessage("Periodic EP stopped", CEPGP.Channel)
    return
  end

  local EP = floor(minutes * (self.db.profile.amount / self.db.profile.period) + 0.5)
  CEPGP_AddRaidEP(EP, "Periodic EP stopped")
  if STANDBYEP and tonumber(STANDBYPERCENT) > 0 then
    CEPGP_addStandbyEP(EP * (tonumber(STANDBYPERCENT) / 100), nil, "Periodic EP")
  end
end

function CEPGP_PeriodicEP:TickerTimerCallback()
  CEPGP_AddRaidEP(self.db.profile.amount, "Periodic EP")
  if STANDBYEP and tonumber(STANDBYPERCENT) > 0 then
    CEPGP_addStandbyEP(self.db.profile.amount * (tonumber(STANDBYPERCENT) / 100), nil, "Periodic EP")
  end
end

function CEPGP_PeriodicEP:TickerTimerResumeCallback()
  CEPGP_AddRaidEP(self.db.profile.amount, "Periodic EP")
  if STANDBYEP and tonumber(STANDBYPERCENT) > 0 then
    CEPGP_addStandbyEP(self.db.profile.amount * (tonumber(STANDBYPERCENT) / 100), nil, "Periodic EP")
  end
  self.tickerTimer = self:ScheduleRepeatingTimer(self.TickerTimerCallback, self.db.profile.period * 60, self)
end
