modifier_disconnect_invulnerable = {
	GetTexture = function() return "modifier_invulnerable" end,
	CheckState = function() return { [MODIFIER_STATE_INVULNERABLE] = true } end,
}
