local args = {
	{
		hookPosition = vector.create(792.3786010742188, 256.1499938964844, 619.2352905273438),
		name = "Zombie Shark",
		rarity = "Rare",
		weight = 59878.1
	}
}
game:GetService("ReplicatedStorage"):WaitForChild("FishingSystem"):WaitForChild("FishGiver"):FireServer(unpack(args))
