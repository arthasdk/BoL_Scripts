-----------------------------------------------------------------------------
--> Nautilus, the Titan of the Depths by mathiasmm
--> Version: see variable below

--> Features:
-->> VPrediction on every skillshot, also takes hitbox into account.
-->> Uses Collision for Dredge Line.
-->> Cast options for Q, W, E, R in Auto Carry Mode and Q, W in Mixed Mode.
-->> Option to KS with Dredge Line, Riptide and Depth Charge.
-->> Drawing options for Dredge Line, Riptide and Depth Charge.
-->> Slider to set the amount of enemies for Depth Charge & Titan's Wrath.
-->> Option to enable Lag Free Circles with length changer.
-->> Option to interrupt important spells.
-----------------------------------------------------------------------------

if myHero.charName ~= "Nautilus" then return end

require 'VPrediction'
require 'Collision'

-- Constants
local QRange = 1030
local ERange = 600
local RRange = 825
local ARange = 175

local VP = nil
local version = 1.01

local InterruptList = {
	{charName = "Katarina",        spellName = "KatarinaR"},
	{charName = "Galio",           spellName = "GalioIdolOfDurand"},
	{charName = "FiddleSticks",    spellName = "Crowstorm"},
	{charName = "Nunu",            spellName = "AbsoluteZero"},
	{charName = "Shen",            spellName = "ShenStandUnited"},
	{charName = "Urgot",           spellName = "UrgotSwap2"},
	{charName = "Malzahar",        spellName = "AlZaharNetherGrasp"},
	{charName = "Karthus",         spellName = "FallenOne"},
	{charName = "Pantheon",        spellName = "Pantheon_GrandSkyfall_Jump"},
	{charName = "Caitlyn",         spellName = "CaitlynAceintheHole"},
	{charName = "MissFortune",     spellName = "MissFortuneBulletTime"},
	{charName = "Warwick",         spellName = "InfiniteDuress"}
}

local ToInterrupt = {}

--> Load
function PluginOnLoad()
	AutoCarry.SkillsCrosshair.range = QRange + 50
	Menu()
	VP = VPrediction()
	Col = Collision(QRange, 2000, 0.250, 70)
		
	_G.oldDrawCircle = rawget(_G, 'DrawCircle')
	_G.DrawCircle = DrawCircle2
	AutoCarry.PluginMenu.extra.HitChanceInfo = false
	PrintChat("<font color='#FFFF33'>Nautilus, the Titan of the Depths "..version.." - loaded!")
	
	for _, enemy in pairs(GetEnemyHeroes()) do
		for _, champ in pairs(InterruptList) do
			if enemy.charName == champ.charName then
				table.insert(ToInterrupt, champ.spellName)
			end
		end
	end
end
 
--> Drawings
function PluginOnDraw()
	if not myHero.dead then
		if QReady and AutoCarry.PluginMenu.drawQ then DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0x6600CCFF) end
		if EReady and AutoCarry.PluginMenu.drawE then DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x6600CCFF) end
		if RReady and AutoCarry.PluginMenu.drawR then DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0x6600CCFF) end
	end
end
 
--> KS
function KS()
	for i = 1, heroManager.iCount, 1 do
		local Enemy = heroManager:getHero(i)
		qDmg = getDmg("Q", Enemy, myHero)
		eDmg = getDmg("E", Enemy, myHero)
		rDmg = getDmg("R", Enemy, myHero)
		
		if ValidTarget(Enemy, QRange) and Enemy.health < qDmg and AutoCarry.PluginMenu.KSQ then DredgeLineKS() end
		if ValidTarget(Enemy, RRange) and Enemy.health < rDmg and AutoCarry.PluginMenu.KSR then CastSpell(_R) end
		if ValidTarget(Enemy, ERange) and Enemy.health < eDmg and AutoCarry.PluginMenu.KSE then CastSpell(_E) end
	end
end

function Menu()
	AutoCarry.PluginMenu:addSubMenu("-- Extras Options --", "extra")
	AutoCarry.PluginMenu.extra:addParam("HitChance", "Q - Hitchance", SCRIPT_PARAM_SLICE, 2, 0, 5, 0)
	AutoCarry.PluginMenu.extra:addParam("HitChanceInfo", "Info - Hitchance", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu.extra:addParam("ultEnemies", "No. enemies to use Depth Charge", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
	AutoCarry.PluginMenu.extra:addParam("wEnemies", "No. enemies to use Titan's Wrath", SCRIPT_PARAM_SLICE, 1, 1, 5, 0)
	
	AutoCarry.PluginMenu:addParam("sep", "-- Auto Carry Options --", SCRIPT_PARAM_INFO, "") 
	AutoCarry.PluginMenu:addParam("useQ", "Use - Dredge Line", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useW", "Use - Titan's Wrath", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("useE", "Use - Riptide", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useR", "Use - Depth Charge", SCRIPT_PARAM_ONOFF, true)
	
	AutoCarry.PluginMenu:addParam("sep", "-- Mixed Mode Options --", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("useQ2", "Use - Dredge Line", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useE2", "Use - Riptide", SCRIPT_PARAM_ONOFF, true)
	
	AutoCarry.PluginMenu:addParam("sep", "-- KS Options --", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("KS", "Enable - Killsteal", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("KSQ", "Use - Dredge Line", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("KSE", "Use - Riptide", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("KSR", "Use - Depth Charge", SCRIPT_PARAM_ONOFF, false)
	
	AutoCarry.PluginMenu:addParam("sep", "-- Interrupt Options --", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("iR", "Use - Depth Charge", SCRIPT_PARAM_ONOFF, false)
	
	AutoCarry.PluginMenu:addParam("sep", "-- Drawing Options --", SCRIPT_PARAM_INFO, "")
	AutoCarry.PluginMenu:addParam("drawQ", "Draw - Dredge Line", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawE", "Draw - Riptide", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawR", "Draw - Depth Charge", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("LagFree", "Lag Free Circles", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("CL", "Length before snapping", 4, 300, 75, 2000, 0)
	AutoCarry.PluginMenu:addParam("CLinfo", "The lower your length the better system you need", 5, "")
end

function PluginOnTick()
	Checks()
		if Target ~= nil then
			if AutoCarry.MainMenu.AutoCarry then
				DredgeLine()
				TitanWrath()
				Riptide()
				DepthCharge()
            end
			
            if AutoCarry.MainMenu.MixedMode then
				DredgeLine2()
				Riptide2()
            end
		end
		
	if AutoCarry.PluginMenu.KS then KS() end	
	if AutoCarry.PluginMenu.extra.HitChanceInfo then
		PrintChat ("<font color='#FFFFFF'>Hitchance 0: No waypoints found for the target, returning target current position</font>")
		PrintChat ("<font color='#FFFFFF'>Hitchance 1: Low hitchance to hit the target</font>")
		PrintChat ("<font color='#FFFFFF'>Hitchance 2: High hitchance to hit the target</font>")
		PrintChat ("<font color='#FFFFFF'>Hitchance 3: Target too slowed or/and too close(~100% hit chance)</font>")
		PrintChat ("<font color='#FFFFFF'>Hitchance 4: Target inmmobile(~100% hit chace)</font>")
		PrintChat ("<font color='#FFFFFF'>Hitchance 5: Target dashing(~100% hit chance)</font>")
		AutoCarry.PluginMenu.extra.HitChanceInfo = false
	end
	
	if AutoCarry.PluginMenu.LagFree then _G.DrawCircle = DrawCircle2
	else _G.DrawCircle = _G.oldDrawCircle end
end

function PluginOnProcessSpell(unit, spell)
	if #ToInterrupt > 0 and RReady then
		for _, ability in pairs(ToInterrupt) do
			if spell.name == ability and unit.team ~= myHero.team then
				if ValidTarget(unit, RRange) and AutoCarry.PluginMenu.iR then
					CastSpell(_R, unit)
				end
			end
		end
	end
end

function Checks()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	Target = AutoCarry.GetAttackTarget()
end

function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
end

function DredgeLine()
	for i, target in pairs(GetEnemyHeroes()) do
		CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.250, 70, QRange, 2000, myHero)
		willCollide = Col:GetMinionCollision(CastPosition, myHero)
		
		if QReady and AutoCarry.PluginMenu.useQ and HitChance >= AutoCarry.PluginMenu.extra.HitChance and GetDistance(CastPosition) < QRange and GetDistance(CastPosition) - getHitBoxRadius(Target)/2 and not willCollide then CastSpell(_Q, CastPosition.x, CastPosition.z) end
	end
end

function TitanWrath()
	local ValidTargets = 0
	for i, Enemy in pairs(GetEnemyHeroes()) do
		if Enemy ~= nil and not Enemy.dead and Enemy.visible and GetDistance(myHero, Enemy) < 300 then ValidTargets = ValidTargets + 1 end
	end
	
	if WReady and AutoCarry.PluginMenu.useW and GetDistance(Target) <= ARange and ValidTargets >= AutoCarry.PluginMenu.extra.wEnemies then CastSpell(_W) end
end

function Riptide()
	if EReady and AutoCarry.PluginMenu.useE and GetDistance(Target) <= ERange then CastSpell(_E) end
end

function Riptide2()
	if EReady and AutoCarry.PluginMenu.useE2 and GetDistance(Target) <= ERange then CastSpell(_E) end
end

function DredgeLine2()
	for i, target in pairs(GetEnemyHeroes()) do
		CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.250, 70, QRange, 2000, myHero)
		willCollide = Col:GetMinionCollision(CastPosition, myHero)
		
		if QReady and AutoCarry.PluginMenu.useQ2 and HitChance >= AutoCarry.PluginMenu.extra.HitChance and GetDistance(CastPosition) < QRange and GetDistance(CastPosition) - getHitBoxRadius(Target)/2 and not willCollide then CastSpell(_Q, CastPosition.x, CastPosition.z) end
	end
end

function DredgeLineKS()
	for i, target in pairs(GetEnemyHeroes()) do
        CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.250, 70, QRange, 2000, myHero)
		willCollide = Col:GetMinionCollision(CastPosition, myHero)
		
        if QReady and HitChance >= 2 and GetDistance(CastPosition) < QRange and not willCollide and GetDistance(CastPosition) - getHitBoxRadius(Target)/2 then CastSpell(_Q, CastPosition.x, CastPosition.z) end
	end
end

function DepthCharge()
	local ValidTargets = 0
	for i, Enemy in pairs(GetEnemyHeroes()) do
		if Enemy ~= nil and not Enemy.dead and Enemy.visible and GetDistance(myHero, Enemy) < RRange then ValidTargets = ValidTargets + 1 end
	end
	
	if RReady and AutoCarry.PluginMenu.useR and GetDistance(Target) <= RRange and ValidTargets >= AutoCarry.PluginMenu.extra.ultEnemies then CastSpell(_R, Target) end
end

-- Lag Free Circles (by barasia, vadash and viseversa)
function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
  radius = radius or 300
  quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
  quality = 2 * math.pi / quality
  radius = radius*.92
  
  local points = {}
  for theta = 0, 2 * math.pi + quality, quality do
    local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
    points[#points + 1] = D3DXVECTOR2(c.x, c.y)
  end
  
  DrawLines2(points, width or 1, color or 4294967295)
end

function round(num) 
  if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end

function DrawCircle2(x, y, z, radius, color)
  local vPos1 = Vector(x, y, z)
  local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
  local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
  local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
  
  if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
    DrawCircleNextLvl(x, y, z, radius, 1, color, AutoCarry.PluginMenu.CL) 
  end
end