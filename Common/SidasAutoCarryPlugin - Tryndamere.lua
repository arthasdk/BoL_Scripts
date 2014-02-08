--[[
	Auto Carry Plugin - Tryndamere
		Author: mathiasmm
		Version: 1.0a
		Dependency: Sida's Auto Carry
 
	How to install:
		- Make sure you already have AutoCarry installed.
		- Name the script EXACTLY "SidasAutoCarryPlugin - Tryndamere.lua" without the quotes.
		- Place the plugin in BoL/Scripts/Common folder.
				
	Version History:
		1.0a - Initial release
--]]

if myHero.charName ~= "Tryndamere" then return end

function PluginOnLoad()
	mainLoad()
	mainMenu()
end

function PluginOnTick()
	Checks()
	if Carry.AutoCarry then Ownage() end
	if Carry.MixedMode then Poke() end
	if Plugin.extras.ksE then ksE() end
	if Plugin.autocarry.useR then Immune() end
end

function PluginOnDraw()
	if not myHero.dead then
		if Plugin.drawings.drawW and WREADY then
			DrawCircle(myHero.x, myHero.y, myHero.z, 400, 0x111111)
		end
		if Plugin.drawings.drawE and EREADY then
			DrawCircle(myHero.x, myHero.y, myHero.z, 660, 0x111111)
		end
	end
end

function Ownage()
	if Target then
		if EREADY and GetDistance(Target) <= eRange and Plugin.autocarry.useE then
			CastSpell(_E, Target.x, Target.z)
		end	

		if WREADY and GetDistance(Target) <= wRange and Plugin.autocarry.useW then
			CastSpell(_W)
		end
		myHero:Attack(Target)
	end 
end

function ksE()
	for i = 1, heroManager.iCount, 1 do
		local eTarget = heroManager:getHero(i)
			if ValidTarget(eTarget, eRange) then
				if eTarget.health <= getDmg("E", eTarget, myHero) then
					CastSpell(_E, eTarget.x, eTarget.z)
				end
			end
	end
end

function Poke()
	if Target ~= nil then
		if EREADY and GetDistance(Target) <= eRange and Plugin.mixedmode.mixedE then
			CastSpell(_E, Target.x, Target.z)
		end	

		if WREADY and GetDistance(Target) <= wRange and Plugin.mixedmode.mixedW then
			CastSpell(_W)
		end
	end
end

function Immune()
	if IsMyHealthLow() then
		CastSpell(_R)
	end
end

--[[ menu, checks and other stuff ]]--

function IsMyHealthLow()
	if myHero.health < (myHero.maxHealth * (Plugin.extras.minHealth / 100)) then
		return true
	else
		return false
	end
end

function Checks()
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	Target = AutoCarry.GetAttackTarget()
end

function mainLoad()
	wRange = 400
	eRange = 660
	
	AutoCarry.SkillsCrosshair.range = 660
	Carry = AutoCarry.MainMenu
	Plugin = AutoCarry.PluginMenu
end

function mainMenu()
	Plugin:addSubMenu("Auto Carry: Settings", "autocarry")
	Plugin.autocarry:addParam("useW", "Use Mocking Shout (W) in Auto Carry", SCRIPT_PARAM_ONOFF, true)
	Plugin.autocarry:addParam("useE", "Use Spinning Slash (E) in Auto Carry", SCRIPT_PARAM_ONOFF, true)
	Plugin.autocarry:addParam("useR", "Use Undying Rage (R) in Auto Carry", SCRIPT_PARAM_ONOFF, true)

	Plugin:addSubMenu("Mixed Mode: Settings", "mixedmode")
	Plugin.mixedmode:addParam("mixedW", "Use Mocking Shout (W) in Mixed Mode", SCRIPT_PARAM_ONOFF, false)
	Plugin.mixedmode:addParam("mixedE", "Use Spinning Slash (E) in Mixed Mode", SCRIPT_PARAM_ONOFF, true)
	
	Plugin:addSubMenu("Extras: Settings", "extras")
	Plugin.extras:addParam("ksE", "Killsteal by Spinning Slash (E)", SCRIPT_PARAM_ONOFF, true)
	Plugin.extras:addParam("minHealth", "Health Manager", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
	
	Plugin:addSubMenu("Draw: Settings", "drawings")
	Plugin.drawings:addParam("drawW", "Draw Mocking Shout (W)", SCRIPT_PARAM_ONOFF, true)
	Plugin.drawings:addParam("drawE", "Draw Spinning Slash (E)", SCRIPT_PARAM_ONOFF, true)
end