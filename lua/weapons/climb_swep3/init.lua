AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.Weight = 5

local MatList = { }
MatList[67] = "concrete"
MatList[68] = "dirt"
MatList[71] = "chainlink"
MatList[76] = "tile"
MatList[77] = "metal"
MatList[78] = "dirt"
MatList[84] = "tile"
MatList[86] = "duct"
MatList[87] = "wood"


local max_jumps, min_height = 3, 250

function SWEP:PrimaryAttack()
    if self.Owner:OnGround() then
        return false
    end

    local tracedata = { }
    local ShootPos = self.Owner:GetShootPos()
    local AimVector = self.Owner:GetAimVector()
    tracedata.start = ShootPos
    tracedata.endpos = ShootPos + AimVector*500
    tracedata.filter = self.Owner
    local trace = util.TraceLine(tracedata)

    local dist = trace.HitPos:DistToSqr(self.Owner:GetPos())
    if self.Owner:GetNWInt("climbJumps") > 0 and trace.Hit and dist > 10000 and dist < 25000 then -- wall jump
        self.Owner:SetLocalVelocity(self.Owner:GetAimVector() * 300)
        self.Owner:EmitSound("npc/combine_soldier/gear6.wav", 75, math.random(95, 105))
        self.Owner:ViewPunch(Angle(-7.5, 0, 0))
        self.Owner:SetNWInt("climbJumps", self.Owner:GetNWInt("climbJumps") - 1)
        return true
    end

    if self.Owner:GetNWInt("climbJumps") > 0 and (trace.Hit or !trace.Hit) then -- strafes
        local diff_x = self.trace.HitPos.x - trace.HitPos.x
        local diff_y = self.trace.HitPos.y - trace.HitPos.y
        local diff = diff_x == 0 and diff_y or diff_x
        if diff < 0 then diff = -diff end
        if diff > 50 and dist > 6000 then
            self.trace = trace
            self:ResetValues()
            self.Owner:EmitSound("npc/combine_soldier/gear1.wav", 75, math.random(95, 105))
            self.Owner:ViewPunch(Angle(-7.5, 0, 0))
        end
    end

    // Are we close enough to start climbing? Are we out of jumps?
    if ( (self.Owner:GetNWInt("climbJumps") == 0 and trace.HitPos:DistToSqr(ShootPos) > 1600) or self.Owner:GetNWInt("climbJumps") > (max_jumps - 1) or trace.HitSky) then 
        return false 
    end

    // If we've mysteriously lost the wall we'll want to stop climbing!
    if !trace.Hit then return false end

    if self.Owner:GetVelocity().z <= -750 then
        self:SetNextPrimaryFire(CurTime() + 1)
        self.Owner:EmitSound("ambient/levels/canals/toxic_slime_sizzle4.wav", 50, 200)
        self.Owner:EmitSound("vo/npc/male01/ow0"..math.random(1, 2)..".wav", 125)
        return true
    end

    // Add some effects.
    if trace.MatType == MAT_GLASS then 
        self.Owner:EmitSound(Sound("physics/glass/glass_sheet_step"..math.random(1, 4)..".wav"), 75, math.random(95, 105))
	elseif trace.MatType and MatList[trace.MatType] then
        self.Owner:EmitSound(Sound("player/footsteps/"..MatList[trace.MatType]..math.random(1, 4)..".wav"), 75, math.random(95, 105))
    else 
        self.Owner:EmitSound(Sound("npc/fast_zombie/claw_miss"..math.random(1, 2)..".wav"), 75, math.random(95, 105)) 
    end

    // Climb the wall and modify our jump count.

    local Vel = self.Owner:GetVelocity()
    self.Owner:SetVelocity(Vector(0, 0, 240 - 15 * 1 + self.JumpSequence - Vel.z))

    self:SetNextPrimaryFire(CurTime() + 0.15)
    self.Owner:SetNWInt("climbJumps", self.Owner:GetNWInt("climbJumps") + 1)
    self.trace = trace
    self:ShakeEffect()
    return true
end

function SWEP:CanGrab() -- This too, but modified it somewhat.
    // We'll detect whether we can grab onto the ledge.
    local trace = {}
    trace.start = self.Owner:GetShootPos() + Vector( 0, 0, 15 )
    trace.endpos = trace.start + self.Owner:GetAimVector() * 30
    trace.filter = self.Owner

    local trHi = util.TraceLine(trace)

    local trace = {}
    trace.start = self.Owner:GetShootPos()
    trace.endpos = trace.start + self.Owner:GetAimVector() * 30
    trace.filter = self.Owner

    local trLo = util.TraceLine(trace)

    // Is the ledge actually grabbable?
    if trLo and trHi and trLo.Hit and !trHi.Hit then
        return {trLo.HitWorld, trLo}
    else
        return {false, trLo}
    end

end

function SWEP:SecondaryAttack()
    if self.Owner:OnGround() then return false end // We don't want to grab onto a ledge if we're on the ground!
    self:SetNextSecondaryFire(CurTime() + 1)

    if self.Grab then
        self.Grab = false
        if self.Owner:GetMoveType() == MOVETYPE_NONE then 
            self.Owner:SetMoveType(MOVETYPE_WALK) 
        end
        return false
    end

    // Returns whether we can grab(boolean) and a traceres.
    local Grab = self:CanGrab()

    // If we can't grab we're done here.
    if !Grab[1] then 
        return false 
    end

    // Otherwise reset our jumps and enter ledge holding mode!
    self.Grab  = true
    local VelZ = self.Owner:GetVelocity().z;
	self.Owner:ViewPunch(Angle(math.max(15, math.min(30, VelZ)) * (VelZ > 0 and 1 or -1), 0, 0));
    self.Owner:SetLocalVelocity(Vector(0, 0, 0))
    self.Owner:SetMoveType(MOVETYPE_NONE)
    self.Owner:EmitSound(Sound("physics/flesh/flesh_impact_hard"..math.random(1, 3)..".wav"), 75)
end

function SWEP:ShakeEffect()
    if self.JumpSequence == 0 then
        self.Owner:ViewPunch(Angle(0, 5, 0))
    elseif self.JumpSequence == 1 then
        self.Owner:ViewPunch(Angle(0, -5, 0))
    elseif self.JumpSequence == 2 then
        self.Owner:ViewPunch(Angle(-5, 0, 0))
    end
    self.JumpSequence = self.JumpSequence < 3 and self.JumpSequence + 1 or 0
end

function SWEP:Initialize()
    self:SetWeaponHoldType("normal")
    --self:SetWeaponHoldType(self.HoldType)
    self.Weapon:DrawShadow(false)
	self.Owner:SetNWInt("climbJumps", 0)
    self.JumpSequence = 0
    return true
end

function SWEP:Deploy()
    self.Owner:DrawViewModel(false)
	self.Owner:SetNWInt("climbJumps", 0)
end

local function IsClimbSwep(ply)
    local wep = ply:GetActiveWeapon()
    if !IsValid(ply) or !IsValid(wep) then return false, nil end
    return wep:GetClass() == "climb_swep3", wep
end

function SWEP:ResetValues()
    self.JumpSequence = 0
    self.Owner:SetNWInt("climbJumps", 0)
end

hook.Add("OnPlayerHitGround", "ClimbSlide", function(ply, inWater, onFloater, fallSpeed)
    if !IsValid(ply) or ply:Health() <= 0 then return end
    local is_climb_swep, swep = IsClimbSwep(ply)
    if is_climb_swep then
        swep:ResetValues()
        if !ply.Sliding then
            local velocity = ply:GetVelocity()
            if ply:Crouching() and math.abs(velocity:Length()) > 300 and velocity.z < -300 then
                ply:SetVelocity(velocity + ply:GetForward() * (100 + fallSpeed))
                ply.Sliding = true
                timer.Simple(1, function()
                    ply.Sliding = false
                end)
            end
        end
    end
end)

hook.Add("GetFallDamage", "ClimbRollPD", function(ply, fallSpeed)
    local is_climb_swep, swep = IsClimbSwep(ply)
	if is_climb_swep and fallSpeed < 900 and ply:Crouching() then
		return 0
	end
end)