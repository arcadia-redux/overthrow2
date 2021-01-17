function ProgressTracker:OnAncientKilled(event_data, definition, player_entry, kv, hero)
	if event_data.attacker ~= hero then return end
	--print("[QUEST PROGRESS] Ancient killed!")

	ProgressTracker:UpdateProgress(player_entry, definition, 1)
	return true
end


function ProgressTracker:OnCreepKilled(event_data, definition, player_entry, kv, hero)
	if event_data.attacker ~= hero then return end
	--print("[QUEST PROGRESS] Creep killed!")

	ProgressTracker:UpdateProgress(player_entry, definition, 1)
	return true
end


function ProgressTracker:OnBossKilled(event_data, definition, player_entry, kv, hero)
	if event_data.attacker ~= hero then return end
	--print("[QUEST PROGRESS] Boss killed!")

	ProgressTracker:UpdateProgress(player_entry, definition, 1)
	return true
end


function ProgressTracker:OnRoshanKilled(event_data, definition, player_entry, kv, hero)
	if event_data.attacker ~= hero then return end
	--print("[QUEST PROGRESS] Roshan Killed!")

	ProgressTracker:UpdateProgress(player_entry, definition, 1)
	return true
end


function ProgressTracker:OnHeroDamageDealt(event_data, definition, player_entry, kv, hero)
	if event_data.attacker ~= hero then return end
	--print("[QUEST PROGRESS] "..event_data.damage.."Hero damage dealt!")

	ProgressTracker:UpdateProgress(player_entry, definition, event_data.damage)
	return true
end


function ProgressTracker:OnGameWon(event_data, definition, player_entry, kv, hero)
	if event_data.team ~= hero:GetTeam() then return end
	--print("[QUEST PROGRESS] Game Won!")

	ProgressTracker:UpdateProgress(player_entry, definition, 1)
	return true
end


function ProgressTracker:OnDuelWon(event_data, definition, player_entry, kv, hero)
	if (event_data.hero and event_data.hero == hero) or (event_data.team and event_data.team == hero:GetTeam()) then
		--print("[QUEST PROGRESS] Duel Won!")

		ProgressTracker:UpdateProgress(player_entry, definition, 1)
		return true
	end
end


function ProgressTracker:OnBetGoldWon(event_data, definition, player_entry, kv, hero)
	if event_data.winner ~= hero then return end
	--print("[QUEST PROGRESS] "..event_data.gold.." bet gold won!")

	ProgressTracker:UpdateProgress(player_entry, definition, event_data.gold)
	return true
end


function ProgressTracker:OnRetrainingTomeConsumed(event_data, definition, player_entry, kv, hero)
	if event_data.caster ~= hero then return end
	--print("[QUEST PROGRESS] Retraining tome consumed!")

	ProgressTracker:UpdateProgress(player_entry, definition, 1)
	return true
end


ProgressTracker.AttributeTomeNames = {
	item_book_of_strength = true,
	item_book_of_agility = true,
	item_book_of_intelligence = true,
	item_book_of_strength_2 = true,
	item_book_of_agility_2 = true,
	item_book_of_intelligence_2 = true
}

function ProgressTracker:OnAttributeTomeConsumed(event_data, definition, player_entry, kv, hero)
	if event_data.unit ~= hero then return end

	if event_data.ability and ProgressTracker.AttributeTomeNames[event_data.ability:GetAbilityName()] then
		--print("[QUEST PROGRESS] Attribute tome consumed! +"..event_data.ability:GetSpecialValueFor("bonus_stat").."attributes")

		ProgressTracker:UpdateProgress(player_entry, definition, event_data.ability:GetSpecialValueFor("bonus_stat"))
		return true
	end
end
