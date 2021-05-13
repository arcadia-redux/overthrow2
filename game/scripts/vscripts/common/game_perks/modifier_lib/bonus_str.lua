require("common/game_perks/base_game_perk")

bonus_str = class(base_game_perk)

function bonus_str:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS } end
function bonus_str:GetTexture() return "perkIcons/bonus_str" end
function bonus_str:GetModifierBonusStats_Strength()
	return self:GetPerkValue(self.v[1], self.v[2], self.v[3])
end

bonus_str_t0 = class(bonus_str)
bonus_str_t1 = class(bonus_str)
bonus_str_t2 = class(bonus_str)

function bonus_str_t0:OnCreated() self.v = {0, 1, 0.5} end
function bonus_str_t1:OnCreated() self.v = {0, 1, 1} end
function bonus_str_t2:OnCreated() self.v = {0, 1, 2} end
