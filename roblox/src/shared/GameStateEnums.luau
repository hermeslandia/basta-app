--!strict
-- roblox/src/shared/GameStateEnums.luau
-- Estados del ciclo de vida del Show de TV en Roblox

local GameStateEnums = {
	States = {
		LOBBY = "LOBBY",                     -- Esperando jugadores en el estudio
		INTRO_ROUND = "INTRO_ROUND",         -- El Presentador presenta a los concursantes
		SPINNING_WHEEL = "SPINNING_WHEEL",   -- La ruleta 3D gigante gira en el techo
		PLAYING = "PLAYING",                 -- Concursantes escriben, público interactúa
		BASTA_CALLED = "BASTA_CALLED",       -- Alguien pulsó el botón rojo (alarma + 10s)
		VOTING = "VOTING",                   -- Votación en la pantalla gigante LED
		ROUND_RECAP = "ROUND_RECAP",         -- Puntuación de la ronda
		GAME_OVER_PODIUM = "GAME_OVER_PODIUM"-- Premiación con confeti en el podio
	},
	
	PlayerRoles = {
		CONTESTANT = "CONTESTANT", -- En la mesa central compitiendo
		AUDIENCE = "AUDIENCE",     -- En las gradas con tomates y confeti
		VIP = "VIP"                -- En el palco de honor
	}
}

return GameStateEnums
