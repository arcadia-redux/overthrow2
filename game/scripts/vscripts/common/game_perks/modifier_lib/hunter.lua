require("common/game_perks/base_game_perk")

hunter = class(base_game_perk)

function hunter:DeclareFunctions() return { MODIFIER_EVENT_ON_TAKEDAMAGE } end
function hunter:GetTexture() return "perkIcons/hunter" end

function hunter:OnTakeDamage(params)
	if self:GetParent() ~= params.attacker then return end
	if params.damage <= 0 then return end
	if not params.unit:IsCreep()  then return end
	
	ApplyDamage({
		victim = params.unit,
		attacker = params.attacker,
		damage = params.damage * self.v,
		damage_type = params.damage_type,
		damage_flags = params.damage_flags or 0,
		ability = params.inflictor or nil,
	})
end

hunter_t0 = class(hunter)
hunter_t1 = class(hunter)
hunter_t2 = class(hunter)

function hunter_t0:OnCreated() self.v = 0.1 end
function hunter_t1:OnCreated() self.v = 0.2 end
function hunter_t2:OnCreated() self.v = 0.4 end
