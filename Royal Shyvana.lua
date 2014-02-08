if myHero.charName ~= "Shyvana" then return end

require "iSAC"

------------------------------------------------------
--			 Hotkeys				
------------------------------------------------------

local HK1 = 32
local HK2 = GetKey("C")
local HK3 = GetKey("X")               
local HK4 = GetKey("V")

------------------------------------------------------
--			 Constants					
------------------------------------------------------

local WRange = 320
local ERange, ESpeed, EDelay, EWidth = 925, 1200, 0.250, 60
local RRange = 1000
local AARange = 125

------------------------------------------------------
--			 Variables				
------------------------------------------------------

local ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, DAMAGE_PHYSICAL)
local tpE = VIP_USER and TargetPredictionVIP(ERange, ESpeed, EDelay, EWidth) or TargetPrediction(ERange, ESpeed/1000, EDelay*1000, EWidth)
local iOW = iOrbWalker(AARange, true)
local iSum = iSummoners()
local ver = 1.04

local igniteSlot = nil
local enemyMinions = {}
local JungleMobs = {}
local JungleFocusMobs = {}

------------------------------------------------------
--			 Predefined Tables					
------------------------------------------------------

local JungleMobNames = {
	["wolf8.1.1"] = true,
	["wolf8.1.2"] = true,
	["YoungLizard7.1.2"] = true,
	["YoungLizard7.1.3"] = true,
	["LesserWraith9.1.1"] = true,
	["LesserWraith9.1.2"] = true,
	["LesserWraith9.1.4"] = true,
	["YoungLizard10.1.2"] = true,
	["YoungLizard10.1.3"] = true,
	["SmallGolem11.1.1"] = true,
	["Wolf2.1.1"] = true,
	["Wolf2.1.2"] = true,
	["YoungLizard1.1.2"] = true,
	["YoungLizard1.1.3"] = true,
	["LesserWraith3.1.1"] = true,
	["LesserWraith3.1.2"] = true,
	["LesserWraith3.1.4"] = true,
	["YoungLizard4.1.2"] = true,
	["YoungLizard4.1.3"] = true,
	["SmallGolem5.1.1"] = true,
}

local FocusJungleNames = {
	["Dragon6.1.1"] = true,
	["Worm12.1.1"] = true,
	["GiantWolf8.1.1"] = true,
	["AncientGolem7.1.1"] = true,
	["Wraith9.1.1"] = true,
	["LizardElder10.1.1"] = true,
	["Golem11.1.2"] = true,
	["GiantWolf2.1.1"] = true,
	["AncientGolem1.1.1"] = true,
	["Wraith3.1.1"] = true,
	["LizardElder4.1.1"] = true,
	["Golem5.1.2"] = true,
	["GreatWraith13.1.1"] = true,
	["GreatWraith14.1.1"] = true,
}

local Items = {
	BRK = {id = 3153, range = 450, reqTarget = true, slot = nil },
	BWC = {id = 3144, range = 400, reqTarget = true, slot = nil },
	DFG = {id = 3128, range = 750, reqTarget = true, slot = nil },
	HGB = {id = 3146, range = 400, reqTarget = true, slot = nil },
	RSH = {id = 3074, range = 350, reqTarget = false, slot = nil},
	STD = {id = 3131, range = 350, reqTarget = false, slot = nil},
	TMT = {id = 3077, range = 350, reqTarget = false, slot = nil},
	YGB = {id = 3142, range = 350, reqTarget = false, slot = nil}
}

------------------------------------------------------
--			 Callbacks				
------------------------------------------------------

function OnLoad()
	ShyConfig = scriptConfig("Royal Shyvana "..ver.."", "ShyMenu")

	ShyConfig:addParam("combo","Combo!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	ShyConfig:addParam("harass", "Poke!", SCRIPT_PARAM_ONKEYDOWN, false, HK2)
	ShyConfig:addParam("autoFarm", "Farming Minions", SCRIPT_PARAM_ONKEYDOWN, false, HK3)
	ShyConfig:addParam("jungleFarm", "Jungle Clear", SCRIPT_PARAM_ONKEYDOWN, false, HK4)
	ShyConfig:addParam("autoKS", "Smart Killsteal", SCRIPT_PARAM_ONOFF, true)
	ShyConfig:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)
	ShyConfig:addParam("items", "Items usage in Combo!", SCRIPT_PARAM_ONOFF, true)
	ShyConfig:addParam("dragonEnemies","Minimum enemies for R", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)

	ShyConfig:permaShow("combo")
	ShyConfig:permaShow("harass")
	ShyConfig:permaShow("autoFarm")
	ShyConfig:permaShow("jungleFarm")

	ts.name = "Shyvana"
	ShyConfig:addTS(ts)

	igniteSlot = (myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and SUMMONER_2) or nil
	enemyMinions = minionManager(MINION_ENEMY, RRange, myHero, MINION_SORT_HEALTH_ASC)

	for i = 0, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object ~= nil then
			if FocusJungleNames[object.name] then
				table.insert(JungleFocusMobs, object)
			elseif JungleMobNames[object.name] then
				table.insert(JungleMobs, object)
			end
		end
	end
	
	PrintChat("<font color='#CCCCCC'>>> Royal Shyvana!</font>")	
end

function OnTick()
	enemyMinions:update()
	AARange = GetDistance(myHero.minBBox) + myHero.range
	iOW.AARange = AARange
	ts.range = QRange
	ts:update()
	Checks()
	
	if not myHero.dead then
		iSum:AutoIgnite()	
		if ShyConfig.autoKS then AutoKS() end
		if ShyConfig.combo then Combo() if ShyConfig.Orbwalk then iOW:Orbwalk(mousePos, ts.target) end end
		if ShyConfig.harass then Poke() if ShyConfig.Orbwalk then iOW:Orbwalk(mousePos, ts.target) end end
		if ShyConfig.jungleFarm then JungleFarm() end
		if ShyConfig.autoFarm then Farm() end
	end
end

function OnCreateObj(object)
	if FocusJungleNames[object.name] then
		table.insert(JungleFocusMobs, object)
	elseif JungleMobNames[object.name] then
		table.insert(JungleMobs, object)
	end
end

function OnDeleteObj(object)
	for i, Mob in pairs(JungleMobs) do
		if object.name == Mob.name then
			table.remove(JungleMobs, i)
		end
	end
	for i, Mob in pairs(JungleFocusMobs) do
		if object.name == Mob.name then
			table.remove(JungleFocusMobs, i)
		end
	end
end

------------------------------------------------------
--			 Functions					
------------------------------------------------------

function Combo()
	if not ValidTarget(ts.target) then return end
	
	local count = 0
	for _, enemy in pairs(GetEnemyHeroes()) do
		if enemy and not enemy.dead and GetDistance(enemy) <= RRange then
			count = count + 1
		end
	end 
	
	if ShyConfig.items then UseItems(ts.target) end
	
	if count >= ShyConfig.dragonEnemies and RREADY then
		CastSpell(_R, ts.target.x, ts.target.z)
	end
	
	if prediction ~= nil and EREADY and GetDistance(prediction) <= ERange then
		CastSpell(_E, prediction.x, prediction.z)
	end
	
	if GetDistance(ts.target) <= WRange and WREADY then
		CastSpell(_W)
	end
	
	if QREADY and GetDistance(ts.target) <= AARange then
		CastSpell(_Q)
	end
end

function AutoKS()
	for _, enemy in ipairs(GetEnemyHeroes()) do
		QDMG = getDmg("Q", enemy, myHero)
		EDMG = getDmg("E", enemy, myHero)
		
		if ValidTarget(enemy) then
			if GetDistance(enemy) < AARange and QDMG > enemy.health then
				CastSpell(_Q)
				myHero:Attack(enemy)
			elseif GetDistance(enemy) < ERange and EDMG > enemy.health then
				CastSpell(_E, enemy.x, enemy.z)
			end
		end
	end
end

function Poke()
	if not ValidTarget(ts.target) then return end
	
	if prediction ~= nil and EREADY and GetDistance(prediction) <= ERange then
		CastSpell(_E, prediction.x, prediction.z)
	end
	if WREADY and GetDistance(ts.target) <= WRange then
		CastSpell(_W)
	end
end

function JungleFarm()
	local Mob = GetJungleMob()
	if not Mob then return end
	
	if EREADY and GetDistance(Mob) <= ERange then
		CastSpell(_E, Mob.x, Mob.z)
	end
	if WREADY and GetDistance(Mob) <= WRange then
		CastSpell(_W)
	end
	if QREADY and GetDistance(Mob) <= AARange then
		CastSpell(_Q)
	end
	
	iOW:Attack(Mob)
end

function Farm()
	for _, minion in ipairs(enemyMinions.objects) do
		if minion.health < getDmg("AD", minion, myHero) and iOW:GetStage() == STAGE_NONE then
			myHero:Attack(minion)
			return
		end
	end
	if not GetJungleMob() then iOW:Move(mousePos) end
end

------------------------------------------------------
--			 Others				
------------------------------------------------------

function GetJungleMob()
	for _, Mob in pairs(JungleFocusMobs) do
		if ValidTarget(Mob, ERange) then return Mob end
	end
	for _, Mob in pairs(JungleMobs) do
		if ValidTarget(Mob, ERange) then return Mob end
	end
end

function Checks()
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	
	if ts.target ~= nil then
		prediction = tpE:GetPrediction(ts.target)
	end
end

function UseItems(target)
	if target ~= nil then
		for _, item in pairs(Items) do
			item.slot = GetInventorySlotItem(item.id)
			if item.slot ~= nil then
				if item.reqTarget and GetDistance(target) < item.range then
					CastSpell(item.slot, target)
				elseif not item.reqTarget then
					if (GetDistance(target) - getHitBoxRadius(myHero) - getHitBoxRadius(target)) < 50 then
						CastSpell(item.slot)
					end
				end
			end
		end
	end
end

function getHitBoxRadius(target)
    return GetDistance(ts.target.minBBox, ts.target.maxBBox)/2
end