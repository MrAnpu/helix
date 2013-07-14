local PLUGIN = PLUGIN
PLUGIN.name = "Map Scenes"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds different camera positions to the menu."

if (CLIENT) then
	net.Receive("nut_MapScenePos", function(length)
		PLUGIN.position = net.ReadVector()
		PLUGIN.angles = net.ReadAngle()
	end)

	function PLUGIN:CalcView(client, origin, angles, fov)
		if (PLUGIN.position and PLUGIN.angles and !client.character) then
			local view = {}
			view.origin = PLUGIN.position
			view.angles = PLUGIN.angles

			return view
		end
	end
else
	util.AddNetworkString("nut_MapScenePos")

	PLUGIN.positions = PLUGIN.positions or {}

	function PLUGIN:LoadData()
		self.positions = nut.util.ReadTable("scenes")
	end

	function PLUGIN:SaveData()
		nut.util.WriteTable("scenes", self.positions)
	end

	function PLUGIN:PlayerLoadedData(client)
		if (#self.positions > 0) then
			local data = table.Random(self.positions)

			net.Start("nut_MapScenePos")
				net.WriteVector(data.position)
				net.WriteAngle(data.angles)
			net.Send(client)

			client:SetNutVar("mapScenePos", data.position)
		end
	end

	function PLUGIN:SetupPlayerVisibility(client, viewEntity)
		local position = client:GetNutVar("mapScenePos")

		if (!client.character and position) then
			AddOriginToPVS(position)
		end
	end
end

local COMMAND = {}
COMMAND.adminOnly = true

function COMMAND:OnRun(client, arguments)
	local data = {
		position = client:EyePos(),
		angles = client:EyeAngles()
	}

	table.insert(PLUGIN.positions, data)

	PLUGIN:SaveData()
	nut.util.Notify("You've added a new map scene.", client)
end

nut.command.Register(COMMAND, "mapsceneadd")

local COMMAND = {}
COMMAND.adminOnly = true
COMMAND.syntax = "[number range]"

function COMMAND:OnRun(client, arguments)
	local range = tonumber(arguments[1] or "160") or 160
	local count = 0

	for k, v in pairs(PLUGIN.positions) do
		if (v.position:Distance(client:GetPos()) <= range) then
			count = count + 1

			table.remove(PLUGIN.positions, k)
		end
	end

	if (count > 0) then
		PLUGIN:SaveData()
	end

	nut.util.Notify("You've removed "..count.." map scenes in a "..range.." unit radius.", client)
end

nut.command.Register(COMMAND, "mapsceneremove")