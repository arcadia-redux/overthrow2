require("common/game_perks/base_game_perk")

spell_amp = class(base_game_perk)

function spell_amp:DeclareFunctions() return { MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE } end
function spell_amp:GetTexture() return "perkIcons/spell_amp" end
function spell_amp:GetModifierSpellAmplify_Percentage() return self.v end

spell_amp_t0 = class(spell_amp)
spell_amp_t1 = class(spell_amp)
spell_amp_t2 = class(spell_amp)

function spell_amp_t0:OnCreated() self.v = 5 end
function spell_amp_t1:OnCreated() self.v = 10 end
function spell_amp_t2:OnCreated() self.v = 20 end
