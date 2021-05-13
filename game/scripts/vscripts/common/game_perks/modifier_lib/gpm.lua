require("common/game_perks/base_game_perk")

gpm = class(base_game_perk)

function gpm:GetTexture() return "perkIcons/gpm" end

gpm_t0 = class(gpm)
gpm_t1 = class(gpm)
gpm_t2 = class(gpm)

function gpm_t0:OnCreated() self:GetParent().bonusGpmForPerkPerMinute = 50 end
function gpm_t1:OnCreated() self:GetParent().bonusGpmForPerkPerMinute = 100 end
function gpm_t2:OnCreated() self:GetParent().bonusGpmForPerkPerMinute = 150 end
