-- Ultra Music · Cargador
-- 1) Detecta el idioma, 2) descarga (o reutiliza) su archivo de textos, 3) abre el reproductor.
-- Los idiomas son archivos JSON (solo datos). Se guardan en DeltaMusica/Idiomas/ y funcionan sin internet después.
--
-- Forzar un idioma (opcional), antes de ejecutar este script:   getgenv().DeltaMusicaIdiomaForzado = "en"
-- Códigos disponibles ahora: es, en, zh, fr

local BASE = "https://raw.githubusercontent.com/literal234xzha-cpu/musica-delta-idiomas/main/"
-- Dónde está el reproductor. Pon aquí el enlace raw de tu script (ya ofuscado) o déjalo vacío
-- para usar el archivo local DeltaMusica/Reproductor.lua
local REPRODUCTOR_URL = ""
local REPRODUCTOR_LOCAL = "DeltaMusica/Reproductor.lua"

local RAIZ, CARPETA = "DeltaMusica", "DeltaMusica/Idiomas"
local IDIOMA_PREDETERMINADO = "en" -- si el del jugador no está disponible
local MAX_BYTES = 40000

local req = request or http_request or (syn and syn.request)
if not (writefile and readfile and isfile and makefolder and isfolder) then
	warn("[Ultra Music] Tu executor no soporta archivos")
	return
end
if not isfolder(RAIZ) then pcall(makefolder, RAIZ) end
if not isfolder(CARPETA) then pcall(makefolder, CARPETA) end

local HttpService = game:GetService("HttpService")

local function decodificar(texto)
	local ok, d = pcall(function() return HttpService:JSONDecode(texto) end)
	if ok and type(d) == "table" then return d end
end

local function bajar(ruta)
	if not req then return nil end
	local ok, res = pcall(req, { Url = BASE .. ruta, Method = "GET" })
	if not ok or type(res) ~= "table" or res.StatusCode ~= 200 then return nil end
	local cuerpo = res.Body
	if type(cuerpo) ~= "string" or #cuerpo == 0 or #cuerpo > MAX_BYTES then return nil end
	return cuerpo
end

-- Idioma del jugador: "es-es" / "en_us" / "zh-cn" -> "es" / "en" / "zh"
local function idiomaDelJugador()
	local forzado = getgenv and getgenv().DeltaMusicaIdiomaForzado
	if type(forzado) == "string" and forzado ~= "" then return forzado:lower() end
	if isfile(RAIZ .. "/idioma.txt") then
		local ok, t = pcall(readfile, RAIZ .. "/idioma.txt")
		t = ok and type(t) == "string" and t:gsub("%s", ""):lower() or ""
		if t ~= "" then return t end
	end
	local ok, loc = pcall(function() return game:GetService("LocalizationService").RobloxLocaleId end)
	if ok and type(loc) == "string" then
		local cod = loc:lower():match("^(%a+)")
		if cod then return cod end
	end
	return IDIOMA_PREDETERMINADO
end

-- 1) Índice de idiomas: de internet si se puede, o el guardado
local indice
do
	local cuerpo = bajar("idiomas.json")
	local d = cuerpo and decodificar(cuerpo)
	if d and type(d.idiomas) == "table" then
		indice = d
		pcall(writefile, CARPETA .. "/idiomas.json", cuerpo)
	elseif isfile(CARPETA .. "/idiomas.json") then
		local ok, t = pcall(readfile, CARPETA .. "/idiomas.json")
		d = ok and decodificar(t)
		if d and type(d.idiomas) == "table" then indice = d end
	end
end

local function buscarEntrada(cod)
	if not indice then return nil end
	for _, e in ipairs(indice.idiomas) do
		if type(e) == "table" and e.codigo == cod and type(e.archivo) == "string" then return e end
	end
end

-- 2) Elegir idioma y asegurar su archivo
local cod = idiomaDelJugador()
if not cod:match("^%a%a?%a?$") then cod = IDIOMA_PREDETERMINADO end
local entrada = buscarEntrada(cod)
if not entrada then
	cod = IDIOMA_PREDETERMINADO
	entrada = buscarEntrada(cod)
end

local usarIdioma = "es" -- el reproductor lleva el español incrustado
if entrada and entrada.archivo:match("^[%w_%-]+%.json$") then
	local ruta = CARPETA .. "/" .. entrada.archivo
	local versionLocal = 0
	local tengo = false
	if isfile(ruta) then
		local ok, t = pcall(readfile, ruta)
		local d = ok and decodificar(t)
		if d and type(d.textos) == "table" then
			tengo = true
			versionLocal = tonumber(d.version) or 0
		end
	end
	local versionNueva = tonumber(entrada.version) or 1
	if not tengo or versionLocal < versionNueva then
		local cuerpo = bajar(entrada.archivo)
		local d = cuerpo and decodificar(cuerpo)
		if d and type(d.textos) == "table" then
			pcall(writefile, ruta, cuerpo)
			tengo = true
		end
	end
	if tengo then usarIdioma = cod end
end
if getgenv then getgenv().DeltaMusicaIdioma = usarIdioma end

-- 3) Abrir el reproductor
local codigo
if REPRODUCTOR_URL ~= "" and req then
	local ok, res = pcall(req, { Url = REPRODUCTOR_URL, Method = "GET" })
	if ok and type(res) == "table" and res.StatusCode == 200 and type(res.Body) == "string" then codigo = res.Body end
end
if not codigo and isfile(REPRODUCTOR_LOCAL) then
	local ok, t = pcall(readfile, REPRODUCTOR_LOCAL)
	if ok and type(t) == "string" then codigo = t end
end
if not codigo then
	warn("[Ultra Music] No encuentro el reproductor. Pon su enlace en REPRODUCTOR_URL o guárdalo como " .. REPRODUCTOR_LOCAL)
	return
end
local fn, err = loadstring(codigo)
if not fn then
	warn("[Ultra Music] El reproductor no compila: " .. tostring(err))
	return
end
fn()
