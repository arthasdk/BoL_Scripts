--[[
	Auto Carry Plugin - Olaf
		Author: mathiasmm
		Version: 1.01
		Dependency: Sida's Auto Carry
 
	How to install:
		- Make sure you already have AutoCarry installed.
		- Name the script EXACTLY "SidasAutoCarryPlugin - Olaf.lua" without the quotes.
		- Place the plugin in BoL/Scripts/Common folder.
				
	Version History:
		1.0 - Initial release
		1.01 - Changed Axe-Catch (Auto Carry only) & added slider for Axe-Catch range
--]]

if myHero.charName ~= "Olaf" then return end

function PluginOnLoad()
	mainLoad()
	mainMenu()
end

function PluginOnTick()
	Checks()
	if Carry.AutoCarry then Ownage() end
	if Carry.MixedMode then Poke() end
	if Plugin.extras.ksE then ksE() end
	if Plugin.extras.antiCC and not VIP_USER then AntiCC() end
	if Plugin.extras.AxeCatch and Carry.AutoCarry then AxeCatch() end
end

function PluginOnDraw()
	if not myHero.dead and not Plugin.drawings.disableAll then
		if Plugin.drawings.drawE and EREADY then
			DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0x111111)
		end
		if Plugin.drawings.drawQ and QREADY then
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x111111)
		end
	end
end

function Ownage()
	if Target then
		if QREADY and Plugin.autocarry.useQ and GetDistance(Target) <= qRange then
			AutoCarry.CastSkillshot(SkillQ, Target)
		end

		if EREADY and Plugin.autocarry.useE and GetDistance(Target) <= eRange then
			CastSpell(_E, Target)
		end

		if WREADY and Plugin.autocarry.useW and GetDistance(Target) <= wRange then
			CastSpell(_W)
		end
	end
end

function Poke()
	if Target then
		if EREADY and GetDistance(Target) <= eRange and Plugin.mixedmode.mixedE then
			CastSpell(_E, Target)
		end	

		if QREADY and GetDistance(Target) <= qRange and Plugin.mixedmode.mixedQ then
			AutoCarry.CastSkillshot(SkillQ, Target)
		end
	end
end

function ksE()
	for i = 1, heroManager.iCount, 1 do
		local eTarget = heroManager:getHero(i)
			if ValidTarget(eTarget, eRange) then
				if eTarget.health <= getDmg("E", eTarget, myHero) then 
					CastSpell(_E, eTarget)
				end
			end
	end
end

--[[ menu, checks and other stuff ]]--
function Checks()
	Target = AutoCarry.GetAttackTarget()
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
end

function mainLoad()
	qRange = 1000
	eRange = 320
	wRange = 200
	
	qSpeed = 1600
	qDelay = 250

	SkillQ = {spellKey = _Q, range = qRange, speed = qSpeed, delay = qDelay}
	
	AutoCarry.SkillsCrosshair.range = 1000
	Carry = AutoCarry.MainMenu
	Plugin = AutoCarry.PluginMenu
end

function mainMenu()
	Plugin:addSubMenu("Auto Carry: Settings", "autocarry")
	Plugin.autocarry:addParam("useQ", "Use Undertow (Q) in Auto Carry", SCRIPT_PARAM_ONOFF, true)
	Plugin.autocarry:addParam("useW", "Use Vicious Strikes (W) in Auto Carry", SCRIPT_PARAM_ONOFF, true)
	Plugin.autocarry:addParam("useE", "Use Reckless Swing (E) in Auto Carry", SCRIPT_PARAM_ONOFF, true)

	Plugin:addSubMenu("Mixed Mode: Settings", "mixedmode")
	Plugin.mixedmode:addParam("mixedQ", "Use Undertow (Q) in Mixed Mode", SCRIPT_PARAM_ONOFF, true)
	Plugin.mixedmode:addParam("mixedE", "Use Reckless Swing (E) in Mixed Mode", SCRIPT_PARAM_ONOFF, false)
	
	Plugin:addSubMenu("Extras: Settings", "extras")
	Plugin.extras:addParam("ksE", "Killsteal by Reckless Swing (E)", SCRIPT_PARAM_ONOFF, true)
	Plugin.extras:addParam("antiCC", "Use Ragnarok (R) when CC'd", SCRIPT_PARAM_ONOFF, true)
	Plugin.extras:addParam("AxeCatch", "Auto-Catch Axes", SCRIPT_PARAM_ONOFF, true)
	Plugin.extras:addParam("AxeCatchRange", "Auto-Catch Range", SCRIPT_PARAM_SLICE, 300, 300, 550, -1)
	
	Plugin:addSubMenu("Draw: Settings", "drawings")
	Plugin.drawings:addParam("disableAll", "Disable all drawings", SCRIPT_PARAM_ONOFF, false)
	Plugin.drawings:addParam("drawQ", "Draw Undertow (Q)", SCRIPT_PARAM_ONOFF, true)
	Plugin.drawings:addParam("drawE", "Draw Reckless Swing (E)", SCRIPT_PARAM_ONOFF, true)
end

function AntiCC()
	if not myHero.canMove then CastSpell(_R) end
end

function AxeCatch()
	if Axe ~= nil and not QREADY and GetDistance(myHero, Axe) <= Plugin.extras.AxeCatchRange then
		myHero:MoveTo(Axe.x, Axe.z)
	end
end

function OnGainBuff(unit, buff)
	if unit and unit == myHero and RREADY and Plugin.extras.antiCC then
		if buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_SUPPRESS or buff.type == BUFF_SILENCE or buff.type == BUFF_BLIND or buff.type == BUFF_FEAR or buff.type == BUFF_CHARM then
			CastSpell(_R)
		end
	end
end

function PluginOnCreateObj(obj) 
	if obj and GetDistance(obj) < qRange then
		if obj.name:find("olaf_axe_totem") then
			Axe = obj
		end
	end
end 

function PluginOnDeleteObj(obj) 
	if obj and GetDistance(obj) < qRange then
		if obj.name:find("olaf_axe_totem") then 
			Axe = nil
		end
	end
end