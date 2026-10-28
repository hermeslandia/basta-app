--!strict
-- roblox/src/shared/CategoriesConfig.luau
-- Configuración de categorías de ¡BASTA! y banco de letras

local CategoriesConfig = {
	Alphabet = {
		"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
		"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
	},
	
	DefaultCategories = {
		{ id = "nombre", label = "Nombre", timeLimit = 60 },
		{ id = "apellido", label = "Apellido", timeLimit = 60 },
		{ id = "pais", label = "País / Ciudad", timeLimit = 60 },
		{ id = "animal", label = "Animal", timeLimit = 60 },
		{ id = "fruta", label = "Fruta / Flor", timeLimit = 60 },
		{ id = "cosa", label = "Cosa / Objeto", timeLimit = 60 },
	},
	
	-- Efectos arrojables para el público en las gradas
	AudienceItems = {
		TOMATO = {
			name = "Tomate Podrido",
			priceCoins = 10,
			splatDuration = 3.5,
			sound = "rbxassetid://9114223170"
		},
		CAKE = {
			name = "Pastelazo de Crema",
			priceCoins = 25,
			splatDuration = 5.0,
			sound = "rbxassetid://9114223200"
		},
		CONFETTI_CANNON = {
			name = "Cañón de Confeti",
			priceCoins = 15,
			sound = "rbxassetid://9114223300"
		},
		AIR_HORN = {
			name = "Bocina de Aire (Trolling)",
			priceCoins = 30,
			sound = "rbxassetid://9114223400"
		}
	}
}

return CategoriesConfig
