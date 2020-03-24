function GPM_Init()
	Timers:CreateTimer(function()
		local all_heroes = HeroList:GetAllHeroes()
		for _, hero in pairs(all_heroes) do
			if hero:IsRealHero() and hero:IsControllableByAnyPlayer() and hero.bonusGpmForPerkPerMinute then
				hero:ModifyGold(hero.bonusGpmForPerkPerMinute, false, 0)
			end
		end
		return 60
	end)
end
