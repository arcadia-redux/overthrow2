base_game_perk = class({})

function base_game_perk:IsHidden() return false end
function base_game_perk:IsPurgable() return false end
function base_game_perk:IsPurgeException() return false end
function base_game_perk:RemoveOnDeath() return false end

function base_game_perk:GetPerkValue(const, level_counter, bonus_per_level)
	local hero_lvl = self:GetParent():GetLevel()
	return math.floor(hero_lvl/level_counter)*bonus_per_level+const
end
