local format = string.format

local oldThreat = 0

local EPTLog = CreateFrame('Frame')
EPTLog:RegisterEvent('PLAYER_REGEN_DISABLED')

function EPTLog:MessageOutput(inputMessage)
	DEFAULT_CHAT_FRAME:AddMessage(format('|cffDAFF8A[Threat Logger]|r %s', inputMessage))
end

function EPTLog:PLAYER_REGEN_DISABLED(event)
	-- player has entered combat
	oldThreat = 0

	self:UnregisterEvent('PLAYER_REGEN_DISABLED')

	self:RegisterEvent('PLAYER_REGEN_ENABLED')
	self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
	self:RegisterEvent('UNIT_THREAT_LIST_UPDATE')
end

function EPTLog:PLAYER_REGEN_ENABLED(event)
	-- player has left combat
	self:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
	self:UnregisterEvent('UNIT_THREAT_LIST_UPDATE')
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')

	self:RegisterEvent('PLAYER_REGEN_DISABLED')
end

function EPTLog:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if UnitGUID('player') == srcGUID then
		-- only parse stuff the player does
		local spellInfo, hitCrit, Amount

		if eventtype == 'SWING_DAMAGE' then
			local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...

			spellInfo = 'Melee'
			hitcrit = critical and 'crit' or 'hit'
			Amount = amount or 0
		elseif eventtype == 'SPELL_DAMAGE' or
			eventtype == 'SPELL_PERIODIC_DAMAGE' then
			local spellid, spellname, spellschool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = ...

			spellInfo = format('%s(%d)', spellname, spellid)
			hitcrit = critical and 'crit' or 'hit'
			Amount = amount or 0
		end

		if spellInfo then
			self:MessageOutput(format('%s %s for %s damage', spellInfo, hitcrit, tostring(Amount)))
		end
	end
end

function EPTLog:UNIT_THREAT_LIST_UPDATE(event)
	local _, _, _, _, threatValue = UnitDetailedThreatSituation('player', 'target')
	if threatValue then
		threatValue = threatValue / 100
		local threatdiff = threatValue - oldThreat
		if threatdiff ~= 0 then self:MessageOutput(format('Threat is %s', tostring(threatdiff))) end
		oldThreat = threatValue
	end
end

EPTLog:SetScript('OnEvent', function(self, event, ...)
	self[event](self, event, ...)
end)