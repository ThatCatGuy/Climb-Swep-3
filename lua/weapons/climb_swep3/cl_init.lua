include("shared.lua")

SWEP.PrintName       = "Climb SWEP 3"
SWEP.Slot             = 0
SWEP.SlotPos         = 4
SWEP.DrawAmmo         = false
SWEP.DrawCrosshair     = false

local MaxJumps = 3

function SWEP:DrawHUD()
    local Jumps = LocalPlayer():GetNWInt("climbJumps") or 0
    local width, height = 300, 30
    local x, y = ScrW() / 2, ScrH() * 0.95


    // Draw Jump-Monitor
    draw.RoundedBox(4, x - width / 2, y, width, height, Color(225, 181, 229, 122))
    if (MaxJumps - Jumps) > 0 then 
        draw.RoundedBox(4, x - width / 2, y, width * (MaxJumps - Jumps) / MaxJumps, height, Color(225, 181, 229, 255))
    end
    draw.DrawText("Jumps: "..(MaxJumps - Jumps).." of "..MaxJumps, "Trebuchet24", x - width / 2 + 10, y, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    local vel = math.Round(LocalPlayer():GetVelocity():Length())
    draw.DrawText(vel, "Trebuchet24", x + width / 2 - 10, y, HSVToColor(1, 1, math.Clamp(vel * 0.24, 0, 360)), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

function SWEP:DrawWorldModel() 
    return false 
end

function SWEP:PrimaryAttack()
    return true
end

function SWEP:SecondaryAttack()
    return true
end