require("common/game_perks/base_game_perk")

linken = class(base_game_perk)
function linken:GetTexture() return "perkIcons/linken" end

linken.OnCreated = function(self)
	if not IsServer() then return end
	self:GetParent():AddItemByName("item_linken_perk_" .. self.v)
end

linken_t0 = class(linken)
linken_t0.v = 0
linken_t1 = class(linken)
linken_t1.v = 1
linken_t2 = class(linken)
linken_t2.v = 2
