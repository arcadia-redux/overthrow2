require("common/game_perks/base_game_perk")

bonus_all_stats = class(base_game_perk)

function bonus_all_stats:DeclareFunctions()
	return { 
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS, 
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, 
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
	}
end

function bonus_all_stats:GetTexture() return "perkIcons/bonus_all_stats" end

function bonus_all_stats:GetModifierBonusStats_Agility() return self:GetPerkValue(self.v[1], self.v[2], self.v[3]) end
function bonus_all_stats:GetModifierBonusStats_Intellect() return self:GetPerkValue(self.v[1], self.v[2], self.v[3]) end
function bonus_all_stats:GetModifierBonusStats_Strength() return self:GetPerkValue(self.v[1], self.v[2], self.v[3]) end

bonus_all_stats_t0 = class(bonus_all_stats)
bonus_all_stats_t1 = class(bonus_all_stats)
bonus_all_stats_t2 = class(bonus_all_stats)

function bonus_all_stats_t0:OnCreated() self.v = {0, 1, 0.25} end
function bonus_all_stats_t1:OnCreated() self.v = {0, 1, 0.5} end
function bonus_all_stats_t2:OnCreated() self.v = {0, 1, 1} end
