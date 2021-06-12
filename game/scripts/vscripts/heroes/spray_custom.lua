spray_custom = {}

function spray_custom:OnSpellStart()
	local playerId = self:GetCaster():GetPlayerOwnerID()

	local hero = PlayerResource:GetSelectedHeroEntity( playerId )
	local data = WearFunc[CHC_ITEM_TYPE_SPRAYS][playerId]

	if not hero or not data then
		return
	end

	local pos = self:GetCursorPosition()

	if (pos-hero:GetAbsOrigin()):Length2D() > self:GetCastRange(hero:GetOrigin(), hero) then
		self:EndCooldown()
		return
	end

	if data.particle then
		ParticleManager:DestroyParticle( data.particle, true )
		ParticleManager:ReleaseParticleIndex( data.particle )
	end

	local effect = ParticleManager:CreateParticle(
		"particles/sprays/spray_placement.vpcf",
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleControl( effect, 0, pos )

	local spray = ParticleManager:CreateParticle(
		BP_Inventory.item_definitions[data.item_name].Particles["1"].ParticleName,
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleControl( spray, 0, pos )
	ParticleManager:SetParticleControl( spray, 1, Vector( 196, 99999, 0 ) )

	EmitSoundOnLocationWithCaster( pos, "Spraywheel.Paint", hero )

	data.particle = spray
end
