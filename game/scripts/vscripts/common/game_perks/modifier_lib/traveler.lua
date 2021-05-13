require("common/game_perks/base_game_perk")

traveler = class(base_game_perk)
function traveler:GetTexture() return "perkIcons/traveler" end

traveler.OnCreated = function(self)
	if not IsServer() then return end
	self:GetParent():AddItemByName("item_teleport_perk_" .. self.v)
end

traveler_t0 = class(traveler)
traveler_t0.v = 0
traveler_t1 = class(traveler)
traveler_t1.v = 1
traveler_t2 = class(traveler)
traveler_t2.v = 2
