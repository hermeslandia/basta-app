--!strict
-- roblox/src/server/GameManager.server.luau
-- Controlador Maestro del Show de TV en el Servidor

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameStateEnums = require(Shared:WaitForChild("GameStateEnums"))
local CategoriesConfig = require(Shared:WaitForChild("CategoriesConfig"))

local currentState = GameStateEnums.States.LOBBY
local currentLetter = ""
local currentRound = 1
local maxRounds = 3

local contestants: { [Player]: boolean } = {}
local audience: { [Player]: boolean } = {}

print("🎬 [¡BASTA! El Show de TV] Servidor inicializado con éxito.")

-- Función para elegir letra al azar
local function sortearLetra(): string
	local index = math.random(1, #CategoriesConfig.Alphabet)
	return CategoriesConfig.Alphabet[index]
end

-- Asignación de roles al entrar al estudio
Players.PlayerAdded:Connect(function(player: Player)
	print("👤 Jugador ingresó al estudio: " .. player.Name)
	-- Por defecto, los primeros 6 entran a la mesa, el resto va a las gradas
	if #Players:GetPlayers() <= 6 and currentState == GameStateEnums.States.LOBBY then
		contestants[player] = true
		print("   -> Asignado como CONCURSANTE en mesa.")
	else
		audience[player] = true
		print("   -> Asignado como PÚBLICO en gradas (con acceso a tomates).")
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	contestants[player] = nil
	audience[player] = nil
end)
