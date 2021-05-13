require("common/game_perks/base_game_perk")

buff_amplify = class(base_game_perk)
function buff_amplify:GetTexture() return "perkIcons/buff_amplify" end
buff_amplify.OnCreated = function(self)
	if not IsServer() then return end
	local parent = self:GetParent()
	parent.buff_amplify = self.v
end

buff_amplify_t0 = class(buff_amplify) 
buff_amplify_t0.v = 1.1
buff_amplify_t1 = class(buff_amplify) 
buff_amplify_t1.v = 1.2
buff_amplify_t2 = class(buff_amplify) 
buff_amplify_t2.v = 1.4
