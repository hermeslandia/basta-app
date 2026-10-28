--!strict
-- roblox/src/server/HostPresenter.server.luau
-- Controlador de Don Basta (El Conductor / Presentador de TV)

local HostPresenter = {}

local DIALOGOS_BIENVENIDA = {
	"¡Damas y caballeros, bienvenidos al show más emocionante de Roblox: ¡BASTA!!",
	"¡Preparen sus cerebros y sus dedos rápidos, porque la ruleta no perdona!",
	"¡Un saludo al público en las gradas! ¡Y por favor, no me arrojen nada podrido hoy!"
}

local DIALOGOS_TOMATE_GOLPE = {
	"¡Oye! ¿Quién fue el gracioso que me arrojó ese tomate?",
	"¡Mi traje de diseñador! ¡Seguridad, vigilen las gradas!",
	"¡Vaya puntería! Al menos espero que fuera tomate orgánico..."
}

local DIALOGOS_BASTA_PULSADO = {
	"¡ALTO EL FUEGO! ¡Alguien acaba de golpear el botón de BASTA!",
	"¡Diez segundos en el reloj! ¡Terminen de escribir o aténganse a las consecuencias!"
}

function HostPresenter.decir(mensaje: string)
	print("🎤 [Don Basta]: " .. mensaje)
	-- Aquí se emitirá al chat o cartel flotante de Don Basta sobre su cabeza
end

function HostPresenter.reaccionarAGolpeDeTomate()
	local mensaje = DIALOGOS_TOMATE_GOLPE[math.random(1, #DIALOGOS_TOMATE_GOLPE)]
	HostPresenter.decir(mensaje)
end

function HostPresenter.anunciarBasta()
	local mensaje = DIALOGOS_BASTA_PULSADO[math.random(1, #DIALOGOS_BASTA_PULSADO)]
	HostPresenter.decir(mensaje)
end

return HostPresenter
