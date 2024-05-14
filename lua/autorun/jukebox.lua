local color_white, CLIENT, pairs = _G.color_white, _G.CLIENT, _G.pairs
do
	local AddCSLuaFile, CompileFile, Material, isstring, setfenv, SERVER, pcall = _G.AddCSLuaFile, _G.CompileFile, _G.Material, _G.isstring, _G.setfenv, _G.SERVER, _G.pcall
	local Register = scripted_ents.Register
	local LowerKeyNames = table.LowerKeyNames
	local Exists = file.Exists
	local MD5 = util.MD5
	hook.Add("InitPostEntity", "Jukebox::Init", function()
		local defaultMaterialPath = Material("icon16/music.png", "mips vertexlitgeneric"):GetName()
		local _list_0 = file.Find("jukebox/*", "LUA")
		for _index_0 = 1, #_list_0 do
			local fileName = _list_0[_index_0]
			if SERVER then
				AddCSLuaFile("jukebox/" .. fileName)
			end
			local func = CompileFile("jukebox/" .. fileName)
			if not func then
				print("[Music Player] Failed to compile 'jukebox/" .. fileName .. "'")
				return
			end
			local env = { }
			setfenv(func, env)
			local success, result = pcall(func)
			if not success then
				print("[Music Player] Failed to call 'jukebox/" .. fileName .. "': " .. result)
				return
			end
			if istable(result) then
				for key, value in pairs(result) do
					env[key] = value
				end
			end
			local info = LowerKeyNames(env)
			local title = info.title
			if not isstring(title) then
				print("[Music Player] Invalid album title: " .. tostring(title))
				return
			end
			local artwork = info.artwork
			if not isstring(artwork) then
				print("[Music Player] Invalid artwork: " .. tostring(artwork))
				return
			end
			artwork = "jukebox/" .. artwork
			local artist = info.artist
			if not isstring(artist) then
				artist = nil
			end
			local base = {
				ScriptedEntityType = "jukebox",
				Category = "#ukdev.jukebox",
				Author = artist or "unknown",
				Base = "music_disc",
				Spawnable = true,
				Album = title
			}
			if Exists("materials/" .. artwork, "GAME") then
				base.MaterialPath = Material(artwork, "vertexlitgeneric mips"):GetName()
				if CLIENT then
					base.IconOverride = artwork
				end
			else
				base.MaterialPath = defaultMaterialPath
				if CLIENT then
					base.IconOverride = "icon16/music.png"
				end
			end
			local tracks = info.tracks
			for index = 1, #tracks do
				local metatable = { }
				for key, value in pairs(base) do
					metatable[key] = value
				end
				local track = tracks[index]
				if CLIENT then
					metatable.PrintName = track.title
				end
				local filepath = track.filepath
				if Exists("sound/" .. filepath, "GAME") then
					metatable.FilePath = filepath
					Register(metatable, "md_" .. MD5(filepath))
				end
			end
		end
		if g_SpawnMenu and g_SpawnMenu:IsValid() then
			timer.Simple(0.5, function()
				return RunConsoleCommand("spawnmenu_reload")
			end)
		end
		return
	end)
end
if CLIENT then
	local red = Color(255, 50, 50, 255)
	local black = Color(0, 0, 0, 255)
	local GetStored = scripted_ents.GetStored
	local GetPhrase = language.GetPhrase
	local BOTTOM, TOP = _G.BOTTOM, _G.TOP
	local Create = vgui.Create
	local gsub = string.gsub
	local translate
	translate = function(str)
		return gsub(str, "#([%w_.-]+)", GetPhrase)
	end
	local openMenu
	openMenu = function(self)
		local menu = DermaMenu()
		menu:AddOption("#spawnmenu.menu.copy", function()
			SetClipboardText(self:GetSpawnName())
			return
		end):SetIcon("icon16/page_copy.png")
		if isfunction(self.OpenMenuExtra) then
			self:OpenMenuExtra(menu)
		end
		menu:Open()
		return
	end
	local doClick
	doClick = function(self)
		RunConsoleCommand("gm_spawnsent", self:GetSpawnName())
		surface.PlaySound("ui/buttonclickrelease.wav")
		return
	end
	local openMenuExtra
	openMenuExtra = function(self, menu)
		menu:AddOption("#spawnmenu.menu.spawn_with_toolgun", function()
			RunConsoleCommand("creator_name", self:GetSpawnName())
			RunConsoleCommand("gmod_tool", "creator")
			RunConsoleCommand("creator_type", "0")
			return
		end):SetIcon("icon16/brick_add.png")
		return
	end
	return spawnmenu.AddContentType("jukebox", function(container, obj)
		if not (container and container:IsValid()) then
			return
		end
		local className = obj.spawnname
		if not className then
			return
		end
		local title = obj.nicename
		if not title then
			return
		end
		local metatable = GetStored(className).t
		if metatable.Device then
			local devices = container.devices
			if not (devices and (function()
				local _base_0 = devices
				local _fn_0 = _base_0.IsValid
				return _fn_0 and function(...)
					return _fn_0(_base_0, ...)
				end
			end)()) then
				devices = Create("DIconLayout")
				container.devices = devices
				container:Add(devices)
				devices:Dock(TOP)
				local label = Create("DLabel", devices)
				devices.Label = label
				label:Dock(TOP)
				label:SetText("#ukdev.devices")
				label:SetFont("ContentHeader")
				label:SetContentAlignment(4)
				label:SizeToContents()
				label:SetTextColor(color_white)
			end
			local icon = devices:Add("SpawnIcon")
			icon:SetModel(metatable.ModelPath or "models/props_lab/citizenradio.mdl")
			icon:SetTooltip(title)
			icon.GetSpawnName = function()
				return className
			end
			local size = ScreenScale(32)
			icon:SetSize(size, size)
			icon.OpenMenuExtra = openMenuExtra
			icon.OpenMenu = openMenu
			icon.DoClick = doClick
			local label = icon:Add("DLabel")
			icon.Label = label
			label:Dock(BOTTOM)
			label:SetText(obj.nicename)
			label:SetContentAlignment(2)
			label:DockMargin(4, 0, 4, 4)
			label:SetExpensiveShadow(1, black)
			label:SetTextColor(metatable.AdminOnly and red or color_white)
			label:SizeToContents()
			return
		end
		local author = metatable.Author
		if not author then
			return
		end
		local authorPnl = container[author]
		if not (authorPnl and (function()
			local _base_0 = authorPnl
			local _fn_0 = _base_0.IsValid
			return _fn_0 and function(...)
				return _fn_0(_base_0, ...)
			end
		end)()) then
			authorPnl = Create("DIconLayout")
			container[author] = authorPnl
			container:Add(authorPnl)
			authorPnl:Dock(TOP)
			local label = Create("DLabel", authorPnl)
			authorPnl.Label = label
			label:Dock(TOP)
			label:SetText(author)
			label:SetFont("ContentHeader")
			label:SetContentAlignment(4)
			label:SizeToContents()
			label:SetTextColor(color_white)
		end
		local album = metatable.Album
		if not album then
			return
		end
		local albumPnl = authorPnl[album]
		if not (albumPnl and (function()
			local _base_0 = albumPnl
			local _fn_0 = _base_0.IsValid
			return _fn_0 and function(...)
				return _fn_0(_base_0, ...)
			end
		end)()) then
			albumPnl = authorPnl:Add("DIconLayout")
			authorPnl[album] = albumPnl
			albumPnl:Dock(TOP)
			albumPnl:DockMargin(ScreenScale(8), 0, 0, 0)
			local label = Create("DLabel", albumPnl)
			albumPnl.Label = label
			label:Dock(TOP)
			label:SetText(album)
			label:SetFont("DermaLarge")
			label:SetContentAlignment(4)
			label:SizeToContents()
			label:SetTextColor(color_white)
		end
		local icon = albumPnl:Add("ContentIcon")
		icon:SetMaterial(obj.material)
		icon:SetContentType("entity")
		icon:SetAdminOnly(obj.admin)
		icon:SetSpawnName(className)
		icon:SetColor(black)
		icon:SetName(title)
		icon:SetTooltip(translate("#ukdev.title: " .. title .. "\n" .. "#ukdev.album: " .. album .. "\n" .. "#ukdev.artist: " .. author))
		icon.OpenMenuExtra = openMenuExtra
		icon.OpenMenu = openMenu
		icon.DoClick = doClick
		return icon
	end)
end
