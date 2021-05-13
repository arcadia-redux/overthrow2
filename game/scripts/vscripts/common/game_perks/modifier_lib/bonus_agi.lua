require("common/game_perks/base_game_perk")

bonus_agi = class(base_game_perk)

function bonus_agi:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_AGILITY_BONUS } end
function bonus_agi:GetTexture() return "perkIcons/bonus_agi" end
function bonus_agi:GetModifierBonusStats_Agility()
	return self:GetPerkValue(self.v[1], self.v[2], self.v[3])
end

bonus_agi_t0 = class(bonus_agi)
bonus_agi_t1 = class(bonus_agi)
bonus_agi_t2 = class(bonus_agi)

function bonus_agi_t0:OnCreated() self.v = {0, 1, 0.5} end
function bonus_agi_t1:OnCreated() self.v = {0, 1, 1} end
function bonus_agi_t2:OnCreated() self.v = {0, 1, 2} end
