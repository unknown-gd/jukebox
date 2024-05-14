AddCSLuaFile("shared.lua")
include("shared.lua")
local MOVETYPE_VPHYSICS = MOVETYPE_VPHYSICS
local SOLID_VPHYSICS = SOLID_VPHYSICS
local Add = hook.Add
local modelPath = "models/props_lab/citizenradio.mdl"
util.PrecacheModel(modelPath)
ENT.Initialize = function(self)
	self:SetModel(modelPath)
	Add("PlayerUse", self, self.PlayerUse)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetTrigger(true)
	local phys = self:GetPhysicsObject()
	if not (phys and phys:IsValid()) then
		return
	end
	phys:SetMass(15)
	phys:Wake()
	return
end
local CreateSound = CreateSound
ENT.Play = function(self)
	self:Stop()
	local disc = self.Disc
	if not (disc and disc:IsValid()) then
		return
	end
	local filePath = disc.FilePath
	if not filePath then
		return
	end
	local cSound = CreateSound(self, filePath)
	self.m_cSound = cSound
	cSound:ChangeVolume(0, 0)
	cSound:SetDSP(1)
	cSound:Play()
	cSound:ChangeVolume(1, 0.5)
	return cSound
end
ENT.Stop = function(self)
	local cSound = self.m_cSound
	if not (cSound and cSound:IsPlaying()) then
		return
	end
	cSound:Stop()
	return cSound
end
ENT.ChangeVolume = function(self, volume, delta)
	local cSound = self.m_cSound
	if cSound then
		cSound:SetVolume(volume, delta or 0)
	end
	return cSound
end
local NoCollide = constraint.NoCollide
local Simple = timer.Simple
local CurTime = CurTime
ENT.Eject = function(self, ply)
	local disc = self.Disc
	if not (disc and disc:IsValid()) then
		return
	end
	self.m_fLastInsert = CurTime()
	self:Stop()
	self.Disc = nil
	disc:SetParent()
	disc.Jukebox = nil
	disc:SetPos(self:WorldSpaceCenter())
	local cons = NoCollide(self, disc, 0, 0)
	if cons and cons:IsValid() then
		Simple(0.5, function()
			if cons:IsValid() then
				cons:Remove()
				return
			end
		end)
	end
	local phys = disc:GetPhysicsObject()
	if phys and phys:IsValid() then
		if ply and ply:IsValid() then
			phys:ApplyForceCenter((ply:EyePos() - disc:GetPos()) * 16)
		else
			phys:ApplyForceCenter(self:GetAngles():Forward() * 1024)
		end
		phys:Wake()
	end
	return disc
end
local angle_zero = angle_zero
ENT.Insert = function(self, disc)
	self.m_fLastInsert = CurTime()
	self:Eject()
	self.Disc = disc
	disc.Jukebox = self
	disc:SetParent(self)
	disc:SetLocalPos(self:OBBCenter() - disc:OBBCenter())
	disc:SetLocalAngles(angle_zero)
	return
end
ENT.StartTouch = function(self, entity)
	if not entity.MusicDisc or (CurTime() - (self.m_fLastInsert or 0)) < 0.5 then
		return
	end
	self:Insert(entity)
	self:Play()
	return
end
ENT.PlayerUse = function(self, ply, entity)
	if entity ~= self then
		return
	end
	local curTime, lastUseTime = CurTime(), self.m_fLastUse
	self.m_fLastUse = curTime
	if not lastUseTime or (curTime - lastUseTime) > 0.025 then
		self.m_fStartUseTime = curTime
		self:HoldUse(ply, 0)
		return
	end
	local startUseTime = self.m_fStartUseTime
	if startUseTime and self:HoldUse(ply, curTime - startUseTime) == true then
		self.m_fStartUseTime = nil
	end
end
ENT.HoldUse = function(self, ply, delay)
	if delay > 0.5 then
		self:Eject(ply)
		return
	end
end
ENT.Use = function(self, ply)
	return
end
ENT.OnRemove = function(self)
	self:Stop()
	return
end
