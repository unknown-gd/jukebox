AddCSLuaFile("shared.lua")
include("shared.lua")
local modelPath = "models/squad/sf_plates/sf_plate1x1.mdl"
util.PrecacheModel(modelPath)
ENT.Initialize = function(self)
	self:SetModel(modelPath)
	self:SetSubMaterial(0, "!" .. self.MaterialPath)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if not (phys and phys:IsValid()) then
		return
	end
	phys:SetMass(5)
	phys:Wake()
	return
end
ENT.OnRemove = function(self)
	local entity = self.Jukebox
	if entity and entity:IsValid() then
		entity:Stop()
		return
	end
end
