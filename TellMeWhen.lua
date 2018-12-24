-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Other contributions by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune
-- Cybeloras of Mal'Ganis
-- --------------------

-- -------------
-- ADDON GLOBALS
-- -------------

local LBF = LibStub("LibButtonFacade", true)
if LBF then
	LBF:RegisterSkinCallback("TellMeWhen", TellMeWhen_SkinCallback, self);
end

TellMeWhen = {};

TELLMEWHEN_VERSION = "1.4.1";
TELLMEWHEN_MAXGROUPS = 8;
TELLMEWHEN_MAXROWS = 7;
TELLMEWHEN_ICONSPACING = 0;
TELLMEWHEN_UPDATE_INTERVAL = 0.1;

TellMeWhen_Icon_Defaults = {
	BuffOrDebuff		= "HELPFUL",
	BuffShowWhen		= "present",
	CooldownShowWhen	= "usable",
	CooldownType		= "spell",
	Enabled				= false,
	Name				= "",
	OnlyMine			= false,
	ShowTimer			= false,
	ShowPBar			= false,
	ShowCBar			= false,
	InvertBars			= false,
	--DurationAndCD		= false,
	Type				= "",
	Unit				= "player",
	WpnEnchantType		= "mainhand",
	UnitReact			= 0,
	Conditions			= {},
	Alpha				= 100,
};

TellMeWhen_Group_Defaults = {
	Enabled			= false,
	Scale			= 2.0,
	Rows			= 1,
	Columns			= 4,
	Icons			= {},
	OnlyInCombat	= false,
	PrimarySpec		= true,
	SecondarySpec	= true,
	LBFGroup		= false,
};

for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
	TellMeWhen_Group_Defaults["Icons"][iconID] = TellMeWhen_Icon_Defaults;
end;

TellMeWhen_Defaults = {
	Version 		= 	TELLMEWHEN_VERSION,
	Locked 			= 	false,
	Groups 			= 	{},
};

for groupID = 1, TELLMEWHEN_MAXGROUPS do
	TellMeWhen_Defaults["Groups"][groupID] = TellMeWhen_Group_Defaults;
	if (groupID == 1) then
		TellMeWhen_Defaults["Groups"][groupID].Enabled = true;
	end
end

function TellMeWhen_Test(stuff)
	if ( stuff ) then
		DEFAULT_CHAT_FRAME:AddMessage("TellMeWhen test: "..stuff);
	else
		DEFAULT_CHAT_FRAME:AddMessage("TellMeWhen test: "..self:GetName());
	end
end

TellMeWhen_BuffEquivalencies = {};
TellMeWhen_BuffEquivalencies["Bleeding"] = "Pounce Bleed;Rake;Rip;Lacerate;Rupture;Garrote;Savage Rend;Rend;Deep Wound";
TellMeWhen_BuffEquivalencies["VulnerableToBleed"] = "Mangle (Cat);Mangle (Bear);Trauma";
--todo: include engineering bomb debuffs in Incapacitated and StunnedOrIncapacitated
TellMeWhen_BuffEquivalencies["Incapacitated"] ="Gouge;Maim;Repentance;Reckless Charge;Hungering Cold";
TellMeWhen_BuffEquivalencies["StunnedOrIncapacitated"] ="Gouge;Maim;Repentance;Reckless Charge;Hungering Cold;Bash;Pounce;Starfire Stun;Intimidation;Impact;Hammer of Justice;Stun;Blackout;Kidney Shot;Cheap Shot;Shadowfury;Intercept;Charge Stun;Concussion Blow;War Stomp";
TellMeWhen_BuffEquivalencies["Stunned"] ="Reckless Charge;Bash;Pounce;Starfire Stun;Intimidation;Impact;Hammer of Justice;Stun;Blackout;Kidney Shot;Cheap Shot;Shadowfury;Intercept;Charge Stun;Concussion Blow;War Stomp";
TellMeWhen_BuffEquivalencies["DontMelee"] ="Berserk;Evasion;Shield Wall;Retaliation;Dispersion;Hand of Sacrifice;Hand of Protection;Divine Shield;Divine Protection;Ice Block;Icebound Fortitude;Cyclone;Banish";
TellMeWhen_BuffEquivalencies["ImmuneToStun"] ="Divine Shield;Ice Block;The Beast Within;Beastial Wrath;Icebound Fortitude;Hand of Protection;Cyclone;Banish";
TellMeWhen_BuffEquivalencies["ImmuneToMagicCC"] ="Divine Shield;Ice Block;The Beast Within;Beastial Wrath;Cyclone;Banish";
TellMeWhen_BuffEquivalencies["FaerieFires"] ="Faerie Fire;Faerie Fire (Feral)";
TellMeWhen_BuffEquivalencies["MovementSlowed"] = "Incapacitating Shout;Chains of Ice;Icy Clutch;Slow;Daze;Hamstring;Piercing Howl;Wing Clip;Ice Trap;Frostbolt;Cone of Cold;Blast Wave;Mind Flay;Crippling Poison;Deadly Throw;Frost Shock;Earthbind;Curse of Exhaustion";
--Incapacitating Shout is cast by some mobs in Icecrown;Rocket Burst is the debuff from landing with the rocket pack during the gunship fight in ICC.
TellMeWhen_BuffEquivalencies["MeleeSlowed"] = "Rocket Burst;Infected Wounds;Judgements of the Just;Earth Shock;Thunder Clap;Icy Touch";
--TellMeWhen_BuffEquivalencies["CastingSlowed"] = "";


-- ---------------
-- EXECUTIVE FRAME
-- ---------------

function TellMeWhen_OnEvent(self, event)
	if ( event == 'VARIABLES_LOADED' ) then
		SlashCmdList["TELLMEWHEN"] = TellMeWhen_SlashCommand;
		SLASH_TELLMEWHEN1 = "/tellmewhen";
		SLASH_TELLMEWHEN2 = "/tmw";
		if ( not TellMeWhen_Settings ) then
			TellMeWhen_Settings = CopyTable(TellMeWhen_Defaults);
			TellMeWhen_Settings["Groups"][1]["Enabled"] = true;
		elseif ( TellMeWhen_Settings["Version"] < TELLMEWHEN_VERSION ) then
			TellMeWhen_SafeUpgrade();
		end
	elseif ( event == "PLAYER_LOGIN" ) or ( event == "PLAYER_ENTERING_WORLD" ) then
		self:RegisterEvent("PLAYER_TALENT_UPDATE");
		TellMeWhen_Update();
	elseif ( event == "PLAYER_TALENT_UPDATE") then
		TellMeWhen_Update();
	end
end

function TellMeWhen_SafeUpgrade()
	if (TellMeWhen_Settings["Version"] < "1.1.4") then
		TellMeWhen_Settings = CopyTable(TellMeWhen_Defaults);
		TellMeWhen_Settings["Groups"][1]["Enabled"] = true;
		TellMeWhen_Settings["Version"] = TELLMEWHEN_VERSION;
	elseif (TellMeWhen_Settings["Version"] < "1.2.0") then
	TellMeWhen_Settings = TellMeWhen_AddNewSettings(TellMeWhen_Settings, TellMeWhen_Defaults);
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			if (groupID < 5) then
				oldgroupSettings = TellMeWhen_Settings["Spec"][1]["Groups"][groupID];
				TellMeWhen_Settings["Groups"][groupID]["SecondarySpec"] = false;
			else
				local temp_groupID = groupID-4;
				TellMeWhen_Settings["Groups"][groupID]["PrimarySpec"] = false;
				oldgroupSettings = TellMeWhen_Settings["Spec"][2]["Groups"][temp_groupID];
			end
			if (oldgroupSettings) then
				TellMeWhen_Settings["Groups"][groupID]["Enabled"] = oldgroupSettings.Enabled;
				TellMeWhen_Settings["Groups"][groupID]["Scale"] = oldgroupSettings.Scale;
				TellMeWhen_Settings["Groups"][groupID]["Rows"] = oldgroupSettings.Rows;
				TellMeWhen_Settings["Groups"][groupID]["Columns"] = oldgroupSettings.Columns;
				TellMeWhen_Settings["Groups"][groupID]["OnlyInCombat"] = oldgroupSettings.OnlyInCombat;
			end

			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				if (oldgroupSettings) then
					oldiconSettings = oldgroupSettings["Icons"][iconID];
					if (oldiconSettings) then
						iconSettings = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID];
						iconSettings.BuffOrDebuff = oldiconSettings.BuffOrDebuff;
						iconSettings.BuffShowWhen = oldiconSettings.BuffShowWhen;
						iconSettings.CooldownShowWhen = oldiconSettings.CooldownShowWhen;
						iconSettings.CooldownType = oldiconSettings.CooldownType;
						iconSettings.Enabled = oldiconSettings.Enabled;
						iconSettings.Name = oldiconSettings.Name;
						iconSettings.OnlyMine = oldiconSettings.OnlyMine;
						iconSettings.ShowTimer = oldiconSettings.ShowTimer;
						iconSettings.Type = oldiconSettings.Type;
						iconSettings.Unit = oldiconSettings.Unit;
						iconSettings.WpnEnchantType = oldiconSettings.WpnEnchantType;
					end
				end
				if (iconSettings.Name == "" and iconSettings.type ~= "wpnenchant") then
					TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["Enabled"] = false;
				end
			end
		end
	TellMeWhen_Settings["Spec"] = nil;  -- Remove "Spec" {}
	end
	-- End convert 1.1.6 to 1.2.0
	if (TellMeWhen_Settings["Version"] < "1.2.5") then
		--no settings added yet in 1.2.5
		local iconSettings
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			TellMeWhen_Settings["Groups"][groupID]["LBFGroup"] = false;

			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				 -- TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]

			end
		end
	end
	
	if (TellMeWhen_Settings["Version"] < "1.3.0") then
		TellMeWhen_Settings["Texture"] = "Interface\\TargetingFrame\\UI-StatusBar";
		TellMeWhen_Settings["TextureName"] = "Blizzard";
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["ShowPBar"] = false;
				TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["ShowCBar"] = false;
				TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["InvertBars"] = false;
			end
		end
	end
	if (TellMeWhen_Settings["Version"] < "1.3.2") then
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["DurationAndCD"] = false;
			end
		end
	end
	if (TellMeWhen_Settings["Version"] < "1.3.3") then
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["UnitReact"] = 0;
			end
		end
	end
	if (TellMeWhen_Settings["Version"] < "1.4.0") then
		--  Convert 1.2.5 to 1.2.5.1 settings
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				iconSettings = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID];
				if (iconSettings.Conditions == nil) then
					iconSettings.Conditions = {};
				end
				if (iconSettings.Alpha == nil) then
					iconSettings.Alpha = 100;
				end
			end
		end
		TellMeWhen_Settings["Interval"] = TELLMEWHEN_UPDATE_INTERVAL;
	end
	
	--All Upgrades Complete
	TellMeWhen_Settings["Version"] = TELLMEWHEN_VERSION;
end

function TellMeWhen_AddNewSettings(settings, defaults)
	for k, v in pairs(defaults) do
		if ( not settings[k] ) then
			if ( type(v) == "table" ) then
				settings[k] = {};
				settings[k] = TellMeWhen_AddNewSettings(settings[k], defaults[k]);
			else
				settings[k] = v;
			end
		elseif ( type(v) == "table" ) then
			settings[k] = TellMeWhen_AddNewSettings(settings[k], defaults[k]);
		end
	end
	return settings;
end

function TellMeWhen_Update()
	for groupID = 1, TELLMEWHEN_MAXGROUPS do
		TellMeWhen_Group_Update(groupID);
	end
end

do
	local executiveFrame = CreateFrame("Frame", "TellMeWhen_ExecutiveFrame");
	executiveFrame:SetScript("OnEvent", TellMeWhen_OnEvent);
	executiveFrame:RegisterEvent("VARIABLES_LOADED");
	executiveFrame:RegisterEvent("PLAYER_LOGIN");
	executiveFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
end



-- -----------
-- GROUP FRAME
-- -----------


function TellMeWhen_Group_OnEvent(self, event)
	-- called if OnlyInCombat true for this group
	if ( event == "PLAYER_REGEN_DISABLED" ) then
		self:Show();
	elseif ( event == "PLAYER_REGEN_ENABLED" ) then
		self:Hide();
	end
end

-- Called when the configuration of the group has changed, when the addon
-- is loaded or when tmw is locked or unlocked
function TellMeWhen_Group_Update(groupID)
	local currentSpec = GetActiveTalentGroup();
	local groupName = "TellMeWhen_Group"..groupID;
	local group = _G[groupName];
	local resizeButton = _G[groupName.."_ResizeButton"];

	local locked = TellMeWhen_Settings["Locked"];
	local genabled = TellMeWhen_Settings["Groups"][groupID]["Enabled"];
	local scale = TellMeWhen_Settings["Groups"][groupID]["Scale"];
	local rows = TellMeWhen_Settings["Groups"][groupID]["Rows"];
	local columns = TellMeWhen_Settings["Groups"][groupID]["Columns"];
	local onlyInCombat = TellMeWhen_Settings["Groups"][groupID]["OnlyInCombat"];
	local activePriSpec = TellMeWhen_Settings["Groups"][groupID]["PrimarySpec"];
	local activeSecSpec = TellMeWhen_Settings["Groups"][groupID]["SecondarySpec"];
	if (currentSpec==1 and not activePriSpec) or (currentSpec==2 and not activeSecSpec) then
		genabled = false;
	end

	if (genabled) then
		for row = 1, rows do
			for column = 1, columns do
				local iconID = (row-1)*columns + column;
				local iconName = groupName.."_Icon"..iconID;
				local icon = _G[iconName] or CreateFrame("Frame", iconName, group, "TellMeWhen_IconTemplate");
				local powerbarname = iconName.."_Power";
				local cooldownbarname = iconName.."_Cooldown";
				icon.powerbar = icon.powerbar or CreateFrame("StatusBar",powerbarname,icon)
				icon.cooldownbar = icon.cooldownbar or CreateFrame("StatusBar",cooldownbarname,icon)
				icon:SetID(iconID);
				icon:Show();
				if ( column > 1 ) then
					icon:SetPoint("TOPLEFT", _G[groupName.."_Icon"..(iconID-1)], "TOPRIGHT", TELLMEWHEN_ICONSPACING, 0);
				elseif ( row > 1 ) and ( column == 1 ) then
					icon:SetPoint("TOPLEFT", _G[groupName.."_Icon"..(iconID-columns)], "BOTTOMLEFT", 0, -TELLMEWHEN_ICONSPACING);
				elseif ( iconID == 1 ) then
					icon:SetPoint("TOPLEFT", group, "TOPLEFT");
				end
				TellMeWhen_Icon_Update(icon, groupID, iconID);
				if ( not genabled ) then
					TellMeWhen_Icon_ClearScripts(icon);
				end
				
				--this addes LibButtonFacade support I hope.
				
 			--	if LBF then
 			--		LBF:Group("TellMeWhen",groupName):AddButton(icon,ButtonData);
 			--	end
			end
		end
		for iconID = rows*columns+1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
			local icon = _G[groupName.."_Icon"..iconID];
			if icon then
				icon:Hide();
				TellMeWhen_Icon_ClearScripts(icon);
			end
		end

		group:SetScale(scale);
		local lastIcon = groupName.."_Icon"..(rows*columns);
		resizeButton:SetPoint("BOTTOMRIGHT", lastIcon, "BOTTOMRIGHT", 3, -3);
		if ( locked ) then
			resizeButton:Hide();
		else
			resizeButton:Show();
		end


	end -- Enabled

	if ( onlyInCombat and genabled and locked ) then
		group:RegisterEvent("PLAYER_REGEN_ENABLED");
		group:RegisterEvent("PLAYER_REGEN_DISABLED");
		group:SetScript("OnEvent", TellMeWhen_Group_OnEvent);
		group:Hide();
	else
		group:UnregisterEvent("PLAYER_REGEN_ENABLED");
		group:UnregisterEvent("PLAYER_REGEN_DISABLED");
		group:SetScript("OnEvent", nil);
		if ( genabled ) then
			group:Show();
		else
			group:Hide();
		end
	end
end




-- -------------
-- ICON FUNCTION
-- -------------
function TellMeWhen_Icon_Bars_Update(icon, groupID, iconID)
	local iconSettings = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID];
	if icon.ShowPBar or icon.ShowCBar then
		local groupName = "TellMeWhen_Group"..groupID;
		local iconName = groupName.."_Icon"..iconID;
		local genabled = TellMeWhen_Settings["Groups"][groupID]["Enabled"];
		local locked = TellMeWhen_Settings["Locked"];
		local onlyInCombat = TellMeWhen_Settings["Groups"][groupID]["OnlyInCombat"];
		local width, height = icon:GetSize()
		local scale = TellMeWhen_Settings["Groups"][groupID]["Scale"];
		if not TellMeWhen_Settings["Texture"] then
			TellMeWhen_Settings["Texture"] = "Interface\\TargetingFrame\\UI-StatusBar";
		end
		if not TellMeWhen_Settings["TextureName"] then
			TellMeWhen_Settings["TextureName"] = "Blizzard";
		end
		local tex = TellMeWhen_Settings["Texture"]
		if icon.ShowPBar then
			local cost = select(4,GetSpellInfo(TellMeWhen_GetSpellNames(icon.Name,1)));
			local powerbarname = iconName.."_Power";
			if not icon.powerbar then
				icon.powerbar = CreateFrame("StatusBar",powerbarname,icon)

			end
			icon.powerbar:SetSize(width*0.9, (height / 2)*0.87);
			icon.powerbar:SetPoint("TOP",icon,"TOP",0,-1.5);
			if cost then
				icon.powerbar:SetMinMaxValues(0, cost);
			end
			if not icon.powerbar.texture then
				icon.powerbar.texture = icon.powerbar:CreateTexture()
			end
			icon.powerbar.texture:SetTexture(tex);						
			local powerType, powerTypeString = UnitPowerType("player");
			local colorinfo = PowerBarColor[powerTypeString];
			icon.powerbar.texture:SetVertexColor(colorinfo.r, colorinfo.g, colorinfo.b, 0.9);
			icon.powerbar:SetStatusBarTexture(icon.powerbar.texture);
			icon.powerbar:SetFrameLevel(icon:GetFrameLevel() + 2);
		end
		if icon.ShowCBar then
			local cooldownbarname = iconName.."_Cooldown";
			icon.cooldownbar = icon.cooldownbar or CreateFrame("StatusBar",cooldownbarname,icon);
			icon.cooldownbar:SetSize(width*0.9, (height / 2)*0.87);
			icon.cooldownbar:SetPoint("BOTTOM",icon,"BOTTOM",0,1.5);
			icon.cooldownbar.texture = icon.cooldownbar.texture or icon.cooldownbar:CreateTexture();
			icon.cooldownbar.texture:SetTexture(tex);
			icon.cooldownbar:SetStatusBarTexture(icon.cooldownbar.texture);
			icon.cooldownbar:SetFrameLevel(icon:GetFrameLevel() + 2);
			icon.cooldownbar:SetMinMaxValues(0,  1)
		end
	end
	if not icon.ShowPBar then
		icon.powerbar:Hide();
	else
		icon.powerbar:Show()
	end
	if not icon.ShowCBar then
		icon.cooldownbar:Hide();
	else
		icon.cooldownbar:Show()
	end
end

local SM = LibStub("LibSharedMedia-3.0")
function TellMeWhen_Icon_Update(icon, groupID, iconID)
	local iconSettings      = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID];
	local Enabled           = iconSettings.Enabled;
	local iconType          = iconSettings.Type;
	local CooldownType      = iconSettings.CooldownType;
	icon.CooldownShowWhen   = iconSettings.CooldownShowWhen;
	icon.BuffShowWhen       = iconSettings.BuffShowWhen;
	local Conditions        = iconSettings.Conditions;
	local ConditionPresent  = false;
	icon.Name               = iconSettings.Name;
	icon.Unit               = iconSettings.Unit;
	icon.UnitReact          = iconSettings.UnitReact;
	icon.ShowTimer          = iconSettings.ShowTimer;
	icon.ShowPBar           = iconSettings.ShowPBar;
	icon.ShowCBar           = iconSettings.ShowCBar;
	icon.InvertBars         = iconSettings.InvertBars;
	icon.OnlyMine           = iconSettings.OnlyMine;
	icon.BuffOrDebuff       = iconSettings.BuffOrDebuff;
	icon.WpnEnchantType     = iconSettings.WpnEnchantType;
	--icon.DurationAndCD    = iconSettings.DurationAndCD;
	icon.baseAlpha          = iconSettings.Alpha;
	
	TellMeWhen_Settings["Interval"] = TellMeWhen_Settings["Interval"] or TELLMEWHEN_UPDATE_INTERVAL
	icon.updateTimer = TellMeWhen_Settings["Interval"];

	icon.texture = _G[icon:GetName().."Texture"];
	icon.countText = _G[icon:GetName().."Count"];
	icon.Cooldown = _G[icon:GetName().."Cooldown"];

	--[[icon:UnregisterEvent("ACTIONBAR_UPDATE_STATE");
	icon:UnregisterEvent("ACTIONBAR_UPDATE_USABLE");
	icon:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
	--icon:UnregisterEvent("SPELL_UPDATE_USABLE");
	icon:UnregisterEvent("PLAYER_TARGET_CHANGED");
	icon:UnregisterEvent("PLAYER_FOCUS_CHANGED");
	icon:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	icon:UnregisterEvent("UNIT_INVENTORY_CHANGED");
	icon:UnregisterEvent("BAG_UPDATE_COOLDOWN");
	icon:UnregisterEvent("UNIT_AURA");
	icon:UnregisterEvent("PLAYER_TOTEM_UPDATE");
	icon:UnregisterEvent("PLAYER_REGEN_ENABLED");
	icon:UnregisterEvent("PLAYER_REGEN_DISABLED");]]--
	
	icon:UnregisterAllEvents();
	icon.countText:Hide();
		
	if (Conditions ~= nil and #Conditions > 0) then
		ConditionPresent = true;
		for i=1,#Conditions do
			icon:UnregisterEvent("UNIT_" .. Conditions[i].ConditionType);
		end
	end
	if ( TellMeWhen_Settings["Locked"] and not Enabled) then
		TellMeWhen_Icon_ClearScripts(icon);
	else

		--TESTANDO FUNÇÃO ABAIXO
		-- used by both cooldown and reactive icons
		if ( icon.CooldownShowWhen == "usable" ) then
			icon.usableAlpha = 1;
			icon.unusableAlpha = 0;
		elseif ( icon.CooldownShowWhen == "unusable" ) then
			icon.usableAlpha = 0;
			icon.unusableAlpha = 1;
		elseif ( icon.CooldownShowWhen == "always") then
			icon.usableAlpha = 1;
			icon.unusableAlpha = 1;
		else
			error("Alpha not assigned: "..icon.Name);
			icon.usableAlpha = 1;
			icon.unusableAlpha = 1;
		end
		-- used by both buff/debuff and wpnenchant icons
		if ( icon.BuffShowWhen == "present" ) then
			icon.presentAlpha = 1;
			icon.absentAlpha = 0;
		elseif ( icon.BuffShowWhen == "absent" ) then
			icon.presentAlpha = 0;
			icon.absentAlpha = 1;
		elseif ( icon.BuffShowWhen == "always") then
			icon.presentAlpha = 1;
			icon.absentAlpha = 1;
			--SendChatMessage("Alpha always assigned to: "..icon.Name);
		else
			error("Alpha not assigned: "..icon.Name);
			icon.presentAlpha = 1;
			icon.absentAlpha = 1;
		end
		
		--[[ used by both cooldown and reactive icons
		if ( icon.CooldownShowWhen == "usable" ) then
			icon.usableAlpha = (1 * icon.usableAlpha);
			icon.unusableAlpha = (0 * icon.unusableAlpha);
		elseif ( icon.CooldownShowWhen == "unusable" ) then
			icon.usableAlpha = (0 * icon.usableAlpha); --hey, you never know, multiplying by zero might become useful in the future
			icon.unusableAlpha = (1 * icon.unusableAlpha);
		elseif ( icon.CooldownShowWhen == "always") then
			icon.usableAlpha = (1 * icon.usableAlpha);
			icon.unusableAlpha = (1 * icon.unusableAlpha);
		else
			error("Alpha not assigned: "..icon.Name);
			icon.usableAlpha = (1 * icon.usableAlpha);
			icon.unusableAlpha = (1 * icon.unusableAlpha);
		end
		-- used by both buff/debuff and wpnenchant icons
		if ( icon.BuffShowWhen == "present" ) then
			icon.presentAlpha = (1 * icon.usableAlpha);
			icon.absentAlpha = (0 * icon.unusableAlpha);
		elseif ( icon.BuffShowWhen == "absent" ) then
			icon.presentAlpha = (0 * icon.usableAlpha);
			icon.absentAlpha = (1 * icon.unusableAlpha);
		elseif ( icon.BuffShowWhen == "always") then
			icon.presentAlpha = (1 * icon.usableAlpha);
			icon.absentAlpha = (1 * icon.unusableAlpha);
			--SendChatMessage("Alpha always assigned to: "..icon.Name);
		else
			error("Alpha not assigned: "..icon.Name);
			icon.presentAlpha = (1 * icon.usableAlpha);
			icon.absentAlpha = (1 * icon.unusableAlpha);
		end]]--


		if ( iconType == "cooldown" ) then
-- --------------				
-- SPELL COOLDOWN
-- --------------			
			if ( CooldownType == "spell" ) then
				if ( GetSpellCooldown(TellMeWhen_GetSpellNames(icon.Name,1)) ) then
					icon.texture:SetTexture(GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)));
					icon:SetScript("OnUpdate", TellMeWhen_Icon_SpellCooldown_OnUpdate);
				else
					TellMeWhen_Icon_ClearScripts(icon);
					icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
				end
				TellMeWhen_Icon_Bars_Update(icon, groupID, iconID)
				if (icon.ShowTimer) then
					icon:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
					icon:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
					icon:SetScript("OnEvent", TellMeWhen_Icon_SpellCooldown_OnEvent);
				else
					icon:SetScript("OnEvent", nil);
				end
				TellMeWhen_Icon_StatusCheck(icon, iconType, CooldownType);
-- --------------				
-- ITEM COOLDOWN
-- -------------
			elseif ( CooldownType == "item" ) then
				icon.ShowPBar = false;
				icon.powerbar:Hide();
				TellMeWhen_Icon_Bars_Update(icon, groupID, iconID)
				local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(TellMeWhen_GetItemIDs(icon.Name,1)) --or error("Invalid Item Name for Group " .. groupID .. " Icon " .. iconID .. " (Check Spelling or cooldown type) :\r\n " .. icon.Name)
			--	if itemLink then
			--		local _, _, Color, Ltype, Id = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
			--		icon.ID = Id
					icon:SetScript("OnUpdate", TellMeWhen_Icon_ItemCooldown_OnUpdate)
			--	end
				if ( itemName ) then
					icon.texture:SetTexture(itemTexture);
					if (icon.ShowTimer) then
						icon:RegisterEvent("BAG_UPDATE_COOLDOWN");
						icon:SetScript("OnEvent", TellMeWhen_Icon_ItemCooldown_OnEvent);
					else
						icon:SetScript("OnEvent", nil);
					end
				else
					TellMeWhen_Icon_ClearScripts(icon);
					icon.learnedTexture = false;
					icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
				end
			end
			icon.Cooldown:SetReverse(false);
			TellMeWhen_Icon_StatusCheck(icon, iconType, CooldownType);	
			
-- --------------				
-- BUFF
-- --------------	
		elseif ( iconType == "buff" ) then
		
			icon:RegisterEvent("PLAYER_TARGET_CHANGED");
			icon:RegisterEvent("PLAYER_FOCUS_CHANGED");
			icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
			icon:RegisterEvent("UNIT_AURA");
			icon:RegisterEvent("PLAYER_REGEN_ENABLED");
			if (ConditionPresent) then
				icon.conditionPresent = ConditionPresent;
				icon.conditions = Conditions;
				for i=1,#Conditions do
					icon:RegisterEvent("UNIT_" .. Conditions[i].ConditionType);
				end
			end
			icon:RegisterEvent("PLAYER_REGEN_DISABLED");
			TellMeWhen_Icon_Bars_Update(icon, groupID, iconID)
		--	icon:SetScript("OnEvent", TellMeWhen_Icon_Buff_OnEvent);
			icon:SetScript("OnUpdate",TellMeWhen_Icon_Buff_OnUpdate)
			local name = TellMeWhen_GetSpellNames(icon.Name,1)
			
			if ( icon.Name == "" ) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			elseif ( GetSpellTexture(name) ) then
				icon.texture:SetTexture(GetSpellTexture(name));
			elseif ( not icon.learnedTexture ) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01");
			end
			icon.Cooldown:SetReverse(true);
			TellMeWhen_Icon_StatusCheck(icon, iconType);
			
-- --------------				
-- REACTIVE
-- --------------
		elseif ( iconType == "reactive" ) then
		
			TellMeWhen_Icon_Bars_Update(icon, groupID, iconID)
			if ( GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)) ) then
				icon.texture:SetTexture(GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)));	
				--icon:SetScript("OnEvent", TellMeWhen_Icon_Reactive_OnEvent);
				icon:SetScript("OnUpdate", TellMeWhen_Icon_Reactive_OnUpdate);
			else
				TellMeWhen_Icon_ClearScripts(icon);
				icon.learnedTexture = false;
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			end
			icon:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
			icon:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
			icon:SetScript("OnEvent", TellMeWhen_Icon_SpellCooldown_OnEvent);
			TellMeWhen_Icon_StatusCheck(icon, iconType);

-- --------------				
-- WEP ENCHANT
-- --------------	
		elseif ( iconType == "wpnenchant" ) then
			icon.ShowPBar = false;
			icon.ShowCBar = false;			
			TellMeWhen_Icon_Bars_Update(icon, groupID, iconID)
			icon:RegisterEvent("UNIT_INVENTORY_CHANGED");
			local slotID;
			if ( icon.WpnEnchantType == "mainhand" ) then
				slotID = GetInventorySlotInfo("MainHandSlot");
			elseif ( icon.WpnEnchantType == "offhand" ) then
				slotID = GetInventorySlotInfo("SecondaryHandSlot");
			end
			local wpnTexture = GetInventoryItemTexture("player", slotID);
			if ( wpnTexture ) then
				icon.texture:SetTexture(wpnTexture);
				icon:SetScript("OnEvent", TellMeWhen_Icon_WpnEnchant_OnEvent);
				icon:SetScript("OnUpdate", TellMeWhen_Icon_WpnEnchant_OnUpdate);
			else
				TellMeWhen_Icon_ClearScripts(icon);
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			end
			
-- --------------				
-- TOTEM
-- --------------	
		elseif ( iconType == "totem" ) then
			icon.ShowPBar = false;
			icon.ShowCBar = false;
			TellMeWhen_Icon_Bars_Update(icon, groupID, iconID)
			icon:RegisterEvent("PLAYER_TOTEM_UPDATE");
			icon:SetScript("OnEvent", TellMeWhen_Icon_Totem_OnEvent);
			icon:SetScript("OnUpdate", TellMeWhen_Icon_Totem_OnEvent);
			TellMeWhen_Icon_Totem_OnEvent(icon);
			if ( icon.Name == "" ) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
				icon.learnedTexture = false;
			elseif ( GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)) ) then
				icon.texture:SetTexture(GetSpellTexture(TellMeWhen_GetSpellNames(icon.Name,1)));
			elseif ( not icon.learnedTexture ) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01");
			end

		else
			icon.ShowPBar = false;
			icon.ShowCBar = false;
			TellMeWhen_Icon_Bars_Update(icon, groupID, iconID)
			TellMeWhen_Icon_ClearScripts(icon);
			if ( icon.Name ~= "" ) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			else
				icon.texture:SetTexture(nil);
			end
		end
	end -- Enabled CHECK

	icon.countText:Hide();
	icon.Cooldown:Hide();

	if ( Enabled ) then
		icon:SetAlpha(1.0);
	else
		icon:SetAlpha(0.4);
		TellMeWhen_Icon_ClearScripts(icon);
	end

	icon:Show();
	if ( TellMeWhen_Settings["Locked"] ) then
		icon:EnableMouse(0);
		if ( not Enabled ) then
			icon:Hide();
			icon.powerbar:Hide();
			icon.cooldownbar:Hide();
		elseif (icon.Name == "") and ( iconType ~= "wpnenchant" ) then
			icon:Hide();
		end
		icon.powerbar:SetValue(0);
		icon.cooldownbar:SetValue(0);
		icon.powerbar:SetAlpha(.9)

		--
	else
		if not icon.cooldownbar.texture then
			icon.cooldownbar.texture = icon.cooldownbar:CreateTexture()
		end
		if not icon.powerbar.texture then
			icon.powerbar.texture = icon.powerbar:CreateTexture()
		end
		icon.cooldownbar:SetMinMaxValues(0,  1)
		icon.cooldownbar:SetValue(2000000)
		icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.5)
		icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
		icon.powerbar:SetValue(20000)
		icon.powerbar:SetAlpha(.5)
		icon.powerbar.texture:SetTexCoord(0, 1, 0, 1)
		icon:EnableMouse(1);
		icon.texture:SetVertexColor(1, 1, 1, 1);
		TellMeWhen_Icon_ClearScripts(icon);
	end
end

function TellMeWhen_Icon_ClearScripts(icon)
	icon:SetScript("OnEvent", nil);
	icon:SetScript("OnUpdate", nil);
end

function TellMeWhen_GetGCD()
	--To test if GCD, look at an instant cast spell without a CD that player's
	--class starts with with. If that spell is on CD, GCD is up.

	--only look for DKs if player has WOTLK expansion
	local ver = select(4, GetBuildInfo());
		if (ver >= 30000) then
		defaultSpells = {
			ROGUE=GetSpellInfo(1752), -- sinister strike
			PRIEST=GetSpellInfo(139), -- renew
			DRUID=GetSpellInfo(774), -- rejuvenation
			WARRIOR=GetSpellInfo(6673), -- battle shout
			MAGE=GetSpellInfo(7302), -- frost armor
			WARLOCK=GetSpellInfo(1454), -- life tap
			PALADIN=GetSpellInfo(4987), -- cleanse
			SHAMAN=GetSpellInfo(324), -- lightning shield
			HUNTER=GetSpellInfo(1978), -- serpent sting
			DEATHKNIGHT=GetSpellInfo(45462) -- plague strike
		}
	else
		defaultSpells = {
			ROGUE=GetSpellInfo(1752), -- sinister strike
			PRIEST=GetSpellInfo(139), -- renew
			DRUID=GetSpellInfo(774), -- rejuvenation
			WARRIOR=GetSpellInfo(6673), -- battle shout
			MAGE=GetSpellInfo(7302), -- frost armor
			WARLOCK=GetSpellInfo(1454), -- life tap
			PALADIN=GetSpellInfo(4987), -- cleanse
			SHAMAN=GetSpellInfo(324), -- lightning shield
			HUNTER=GetSpellInfo(1978), -- serpent sting
		}
	end
	local _, unitClass = UnitClass("player");
	return select(2,GetSpellCooldown(defaultSpells[unitClass]));
end



--[[ COMENTADO, TESTANDO FUNÇÃO ABAIXO

function TellMeWhen_Icon_StatusCheck(icon, iconType, CooldownType)
	-- this function is so OnEvent-based icons can do a check when the addon is locked
	if ( iconType == "reactive" ) then
		TellMeWhen_Icon_Reactive_OnUpdate(icon,1)
	elseif ( iconType == "buff" ) then
		TellMeWhen_Icon_Buff_OnUpdate(icon,1);
	elseif ( iconType == "cooldown" ) then
		if (CooldownType == "spell") then
			TellMeWhen_Icon_SpellCooldown_OnUpdate(icon,1);
		elseif (CooldownType == "item") then
			TellMeWhen_Icon_ItemCooldown_OnUpdate(icon,1);
		end
	end
end]]--

function TellMeWhen_Icon_StatusCheck(icon, iconType, CooldownType)
	-- this function is so OnEvent-based icons can do a check when the addon is locked
	-- the 1s trick it into thinking that it has been a long time since the last onupdate and so it will run the whole function.
	if ( iconType == "reactive" ) then
		TellMeWhen_Icon_Reactive_OnUpdate(icon,1)
	elseif ( iconType == "buff" ) then
		TellMeWhen_Icon_Buff_OnUpdate(icon,1);
	elseif ( iconType == "cooldown" ) then
		if (CooldownType == "spell") then
			TellMeWhen_Icon_SpellCooldown_OnUpdate(icon,1);
			TellMeWhen_Icon_SpellCooldown_OnEvent(icon)
		elseif (CooldownType == "item") then
			TellMeWhen_Icon_ItemCooldown_OnUpdate(icon,1);
			TellMeWhen_Icon_ItemCooldown_OnEvent(icon)
		end
	end
end

-- REALLY CRUDE FIX HERE FOR SWIPE
-- or clever, i dont know

function TellMeWhen_Icon_SpellCooldown_OnEvent(icon,event)
	local spellname = TellMeWhen_GetSpellNames(icon.Name,1)
	local startTime, timeLeft = GetSpellCooldown(spellname);
	if ( timeLeft ) then
		CooldownFrame_SetTimer(icon.Cooldown, startTime, timeLeft, 1);
	end
end

function TellMeWhen_Icon_SpellCooldown_OnEvent(icon)
--[[	if event == "PET_BAR_UPDATE" then
		icon.namefirst = TellMeWhen_GetSpellNames(icon,icon.Name,1)
		icon.namename = TellMeWhen_GetSpellNames(icon,icon.Name,1,true)
		icon.texture:SetTexture(GetSpellTexture(icon.namefirst) or "Interface\\Icons\\INV_Misc_QuestionMark");
		return
	end]]
	local startTime, duration = GetSpellCooldown(TellMeWhen_GetSpellNames(icon.Name,1));
	if not (icon.ShowTimer) or (not TellMeWhen_Settings["ClockGCD"]) and (TellMeWhen_GetGCD() == duration and duration > 0) then return end
	if ( duration ) then
		CooldownFrame_SetTimer(icon.Cooldown, startTime, duration, 1);
	end
end


local percentcomplete = 1
function TellMeWhen_Icon_SpellCooldown_OnUpdate(icon, elapsed)
	
	icon.updateTimer = icon.updateTimer - elapsed;
	local name = TellMeWhen_GetSpellNames(icon.Name,1)
	
	local startTime, timeLeft = GetSpellCooldown(name);
	if icon.ShowPBar then
		icon.powerbar:SetAlpha(1)
		local cost = select(4,GetSpellInfo(name)) or 0 
		icon.powerbar:SetMinMaxValues(0, cost);
		if not icon.InvertBars then
			icon.powerbar:SetValue(cost - UnitPower("player"))
			icon.powerbar.texture:SetTexCoord(0, max(0,min(((cost - UnitPower("player")) / cost),1)), 0, 1) --more cheats
		else
			icon.powerbar:SetValue(UnitPower("player"))
			icon.powerbar.texture:SetTexCoord(0, max(0,min((UnitPower("player") / cost),1)), 0, 1)			--more cheats
		end
	end

	if icon.ShowCBar then
		if not icon.InvertBars then
			if (timeLeft == 0) then
				percentcomplete = 1
				icon.cooldownbar:SetMinMaxValues(0, 1)
				icon.cooldownbar:SetValue(0)
				icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
				icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
			else
				percentcomplete = (((GetTime() - startTime) / timeLeft))
				icon.cooldownbar:SetMinMaxValues(0,  timeLeft)
				icon.cooldownbar:SetValue(timeLeft - (GetTime() - startTime))
				icon.cooldownbar.texture:SetTexCoord(0, min((1-percentcomplete),1), 0, 1)
				icon.cooldownbar:SetStatusBarColor((100 - percentcomplete), percentcomplete + 0.2, 0,0.9)
			end
		else
			--inverted
			if (timeLeft == 0) then
				percentcomplete = 1
				icon.cooldownbar:SetMinMaxValues(0,  1)
				icon.cooldownbar:SetValue(1)
				icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
				icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
			else
				percentcomplete = (((GetTime() - startTime) / timeLeft))
				icon.cooldownbar:SetMinMaxValues(0,  timeLeft)
				icon.cooldownbar:SetValue(GetTime() - startTime)
				icon.cooldownbar.texture:SetTexCoord(0, min(((percentcomplete)),1), 0, 1)
				icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete)) , (percentcomplete) + 0.2, 0,0.9)
			end
		end
	end
	if ( icon.updateTimer <= 0 ) and timeLeft then
		icon.updateTimer = TellMeWhen_Settings["Interval"];
		local isEnemy = UnitIsEnemy("player", "target")
		local react = UnitReaction("player", "target") or 5
		if (isEnemy) or (react <= 4) then
			isEnemy = 1
		else
			isEnemy = 0
		end
		if (icon.UnitReact == 0) or (icon.UnitReact == isEnemy) or (icon.UnitReact == 2 and isEnemy == 0 ) then
			local inrange = IsSpellInRange(name, icon.Unit);
			local _, nomana = IsUsableSpell(name);
			local OnGCD = TellMeWhen_GetGCD() == timeLeft and timeLeft > 0;
			--name, rank, icon, powerCost,  isFunnel, powerType, castingTime,  minRange, maxRange
			local minRange,maxRange = select(8,GetSpellInfo(name));
			if ( not maxRange or inrange == nil) then
				inrange = 1;
			end
			if ( (timeLeft == 0 or OnGCD) and inrange == 1 and not nomana) then
				icon.texture:SetVertexColor(1, 1, 1, 1);
				TellMeWhen_SetIconAlpha(icon, icon.usableAlpha);
			elseif ( icon.usableAlpha == 1 and  (timeLeft == 0 or OnGCD)) then
				--gray if not inrange or if nomana
				icon.texture:SetVertexColor(0.5, 0.5, 0.5, 1);
				icon:SetAlpha(icon.usableAlpha);				TellMeWhen_SetIconAlpha(icon, icon.usableAlpha);			else
				icon.texture:SetVertexColor(1, 1, 1, 1);
				icon:SetAlpha(icon.unusableAlpha);
			end
		else
			icon:SetAlpha(0)
		end
	end
end



function TellMeWhen_Icon_ItemCooldown_OnEvent(icon)
	local startTime, timeLeft, enable = GetItemCooldown(icon.ID);
	if ( timeLeft ) then
		CooldownFrame_SetTimer(icon.Cooldown, startTime, timeLeft, 1);
	end
end

function TellMeWhen_Icon_ItemCooldown_OnUpdate(icon, elapsed)
	icon.updateTimer = icon.updateTimer - elapsed;
	local startTime, timeLeft = GetItemCooldown(icon.ID);
	if icon.ShowCBar then
		if not icon.InvertBars then
			if (timeLeft == 0) then
				percentcomplete = 100
				icon.cooldownbar:SetMinMaxValues(0,  1)
				icon.cooldownbar:SetValue(0)
				icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
				icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
			else
				percentcomplete = (((GetTime() - startTime) / timeLeft) * 100)
				icon.cooldownbar:SetMinMaxValues(0,  timeLeft)
				icon.cooldownbar:SetValue(timeLeft - (GetTime() - startTime))
				icon.cooldownbar.texture:SetTexCoord(0, min((1-(percentcomplete/100)),1), 0, 1)
				icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
			end
		else
			--inverted
			if (timeLeft == 0) then
				percentcomplete = 100
				icon.cooldownbar:SetMinMaxValues(0,  1)
				icon.cooldownbar:SetValue(1)
				icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
				icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
			else
				percentcomplete = (((GetTime() - startTime) / timeLeft) * 100)
				icon.cooldownbar:SetMinMaxValues(0,  timeLeft)
				icon.cooldownbar:SetValue(GetTime() - startTime)
				icon.cooldownbar.texture:SetTexCoord(0, min(((percentcomplete/100)),1), 0, 1)
				icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
			end
		end
	end
	if ( icon.updateTimer <= 0 ) and timeLeft then
		icon.updateTimer = TellMeWhen_Settings["Interval"];
		local isEnemy = UnitIsEnemy("player", "target")
		local react = UnitReaction("player", "target") or 5
		if (isEnemy) or (react <= 4) then
			isEnemy = 1
		else
			isEnemy = 0
		end
		if (icon.UnitReact == 0) or (icon.UnitReact == isEnemy) or (icon.UnitReact == 2 and isEnemy == 0 ) then
			if ( timeLeft == 0 or TellMeWhen_GetGCD() == timeLeft ) then
				TellMeWhen_SetIconAlpha(icon, icon.usableAlpha);
			elseif ( timeLeft > 0 and TellMeWhen_GetGCD() ~= timeLeft ) then
				TellMeWhen_SetIconAlpha(icon, icon.unusableAlpha);
			end
		else
			icon:SetAlpha(0)
		end
	end
end

function TellMeWhen_Icon_Buff_OnUpdate(icon, elapsed)
	local auraNames = TellMeWhen_GetSpellNames(icon.Name);
	if #(auraNames) > 1 then
		if ( UnitExists(icon.Unit) ) then
			
			local maxExpirationTime = 0;
			local processedBuffInAuraNames = false;
			local i, iName;

			local filter = icon.BuffOrDebuff;
			if icon.OnlyMine then filter = filter.."|PLAYER" end
			
			for i, iName in ipairs(auraNames) do
		--		local buffName, rank, iconTexture, count, debuffType, duration, expirationTime, unitCaster, isStealable;
				local buffName, _, iconTexture, count, _, duration, expirationTime, unitCaster = UnitAura(icon.Unit, iName, nil, filter);
				if ( buffName ) then --and expirationTime > maxExpirationTime and ((( unitCaster == "player" ) or ( unitCaster == "pet" ) or ( unitCaster == "vehicle" )) or not icon.OnlyMine) ) then
					--maxExpirationTime = expirationTime;
					if ( icon.texture:GetTexture() ~= iconTexture) then
						icon.texture:SetTexture(iconTexture);
						icon.learnedTexture = true;
					end
					if (icon.presentAlpha) then
						icon:SetAlpha(icon.presentAlpha);
					end
					icon.texture:SetVertexColor(1, 1, 1, 1);
					if ( count > 1 ) then
						icon.countText:SetText(count);
						icon.countText:Show();
					else
						icon.countText:Hide();
					end
					if ( icon.ShowTimer and not UnitIsDead(icon.Unit)) then
						CooldownFrame_SetTimer(icon.Cooldown, expirationTime - duration, duration, 1);
					end
					processedBuffInAuraNames = true;
					icon.powerbar:SetMinMaxValues(0,  1)
					icon.powerbar:SetValue(0)
					if icon.ShowCBar then
						if not icon.InvertBars then
							if (duration == nil or duration == 0) then
								percentcomplete = 100
								icon.cooldownbar:SetMinMaxValues(0,  1)
								icon.cooldownbar:SetValue(0)
								icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
								icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
							else
								percentcomplete = (( duration - (expirationTime - GetTime()) )/duration * 100)
								icon.cooldownbar:SetMinMaxValues(0,  duration)
								icon.cooldownbar:SetValue(expirationTime - GetTime())
								icon.cooldownbar.texture:SetTexCoord(0, min((1-(percentcomplete/100)),1), 0, 1)
								icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
							end
						else
							--inverted
							if (duration == nil or duration == 0) then
								percentcomplete = 100
								icon.cooldownbar:SetMinMaxValues(0,  1)
								icon.cooldownbar:SetValue(0)
							else
								percentcomplete = (( duration - (expirationTime - GetTime()) )/duration * 100)
								icon.cooldownbar:SetMinMaxValues(0,  duration)
								icon.cooldownbar:SetValue(duration - (expirationTime - GetTime()))
								icon.cooldownbar.texture:SetTexCoord(0, min(((percentcomplete/100)),1), 0, 1)
								icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
							end
						end
					end
				end
			end
				
			if (processedBuffInAuraNames) then
				 return;
			end

			if (icon.absentAlpha) then
				icon:SetAlpha(icon.absentAlpha);
			end
			if ( icon.presentAlpha == 1 ) and ( icon.absentAlpha == 1) then
				icon.texture:SetVertexColor(1, 0.35, 0.35, 1);
			end

			icon.countText:Hide();
			if ( icon.ShowTimer  ) then
				CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
			end
		else
			icon:SetAlpha(0);
			CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
		end
	else
		local startTime, timeLeft = GetSpellCooldown(icon.Name);
		icon.updateTimer = icon.updateTimer - elapsed;
		if icon.ShowPBar then
			if not icon.powerbar.texture then
				icon.powerbar.texture = icon.powerbar:CreateTexture()
				icon.powerbar.texture:SetTexture(TellMeWhen_Settings["Texture"]);	  
			end
			local cost = select(4,GetSpellInfo(icon.Name)) or 0
			if not icon.InvertBars then
				icon.powerbar:SetValue(cost - UnitPower("player"))
				icon.powerbar.texture:SetTexCoord(0, max(0,min(((cost - UnitPower("player")) / cost),1)), 0, 1) --more cheats
			else
				icon.powerbar:SetValue(UnitPower("player"))
				icon.powerbar.texture:SetTexCoord(0, max(0,min((UnitPower("player") / cost),1)), 0, 1)				--more cheats
			end
		end

		if icon.ShowCBar and timeLeft then
			if not icon.cooldownbar.texture then
				icon.cooldownbar.texture = icon.cooldownbar:CreateTexture()
				icon.cooldownbar.texture:SetTexture(TellMeWhen_Settings["Texture"]);	  
			end
			local filter = icon.BuffOrDebuff;
			if icon.OnlyMine then filter = filter.."|PLAYER" end
			if ( UnitExists(icon.Unit) ) then
				duration, expirationTime = select(6,UnitAura(icon.Unit, icon.Name, nil, filter))
			else
				duration, expirationTime = nil, nil
			end
			if icon.DurationAndCD then
				if (duration == nil) or (timeLeft <= duration ) then
					if not icon.InvertBars then
						if (timeLeft == 0) then
							percentcomplete = 100
							icon.cooldownbar:SetMinMaxValues(0,  1)
							icon.cooldownbar:SetValue(0)
							icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
							icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
						else
							percentcomplete = (((GetTime() - startTime) / timeLeft) * 100)
							icon.cooldownbar:SetMinMaxValues(0,  timeLeft)
							icon.cooldownbar:SetValue(timeLeft - (GetTime() - startTime))
							icon.cooldownbar.texture:SetTexCoord(0, min((1-(percentcomplete/100)),1), 0, 1)
							icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
						end
					else
						--inverted
						if (timeLeft == 0) then
							percentcomplete = 100
							icon.cooldownbar:SetMinMaxValues(0,  1)
							icon.cooldownbar:SetValue(1)
							icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
							icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
						else
							percentcomplete = (((GetTime() - startTime) / timeLeft) * 100)
							icon.cooldownbar:SetMinMaxValues(0,  timeLeft)
							icon.cooldownbar:SetValue(GetTime() - startTime)
							icon.cooldownbar.texture:SetTexCoord(0, min(((percentcomplete/100)),1), 0, 1)
							icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
						end
					end
				else
					if not icon.InvertBars then
						if (duration == nil or duration == 0) then
							percentcomplete = 100
							icon.cooldownbar:SetMinMaxValues(0,  1)
							icon.cooldownbar:SetValue(0)
							icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
							icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
						else
							percentcomplete = (( duration - (expirationTime - GetTime()) )/duration * 100)
							icon.cooldownbar:SetMinMaxValues(0,  duration)
							icon.cooldownbar:SetValue(expirationTime - GetTime())
							icon.cooldownbar.texture:SetTexCoord(0, min((1-(percentcomplete/100)),1), 0, 1)
							icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
						end
					else
						--inverted
						if (duration == nil or duration == 0) then
							percentcomplete = 100
							icon.cooldownbar:SetMinMaxValues(0,  1)
							icon.cooldownbar:SetValue(0)
						else
							percentcomplete = (( duration - (expirationTime - GetTime()) )/duration * 100)
							icon.cooldownbar:SetMinMaxValues(0,  duration)
							icon.cooldownbar:SetValue(duration - (expirationTime - GetTime()))
							icon.cooldownbar.texture:SetTexCoord(0, min(((percentcomplete/100)),1), 0, 1)
							icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
						end
					end
				end
			else
				if not icon.InvertBars then
					if (duration == nil or duration == 0) then
						percentcomplete = 100
						icon.cooldownbar:SetMinMaxValues(0,  1)
						icon.cooldownbar:SetValue(0)
						icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
						icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
					else
						percentcomplete = (( duration - (expirationTime - GetTime()) )/duration * 100)
						icon.cooldownbar:SetMinMaxValues(0,  duration)
						icon.cooldownbar:SetValue(expirationTime - GetTime())
						icon.cooldownbar.texture:SetTexCoord(0, min((1-(percentcomplete/100)),1), 0, 1)
						icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
					end
				else
					--inverted
					if (duration == nil or duration == 0) then
						percentcomplete = 100
						icon.cooldownbar:SetMinMaxValues(0,  1)
						icon.cooldownbar:SetValue(0)
					else
						percentcomplete = (( duration - (expirationTime - GetTime()) )/duration * 100)
						icon.cooldownbar:SetMinMaxValues(0,  duration)
						icon.cooldownbar:SetValue(duration - (expirationTime - GetTime()))
						icon.cooldownbar.texture:SetTexCoord(0, min(((percentcomplete/100)),1), 0, 1)
						icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
					end
				end
			end
		end
		if ( icon.updateTimer <= 0 ) and timeLeft then
			icon.updateTimer = TellMeWhen_Settings["Interval"];
			local isEnemy = UnitIsEnemy("player", "target")
			local react = UnitReaction("player", "target") or 5
			if (isEnemy) or (react <= 4) then
				isEnemy = 1
			else
				isEnemy = 0
			end
			if (icon.UnitReact == 0) or (icon.UnitReact == isEnemy) or (icon.UnitReact == 2 and isEnemy == 0 ) then
				local auraNames = TellMeWhen_GetSpellNames(icon.Name);
				local maxExpirationTime = 0;
				local processedBuffInAuraNames = false;
				local i, iName;

				local filter = icon.BuffOrDebuff;
				if icon.OnlyMine then filter = filter.."|PLAYER" end
				if ( not TellMeWhen_Icon_ConditionCheck(icon) ) then
					icon:SetAlpha(0);
					return;
				end
				for i, iName in ipairs(auraNames) do
			--		local buffName, rank, iconTexture, count, debuffType, duration, expirationTime, unitCaster, isStealable;
					local buffName, _, iconTexture, count, _, duration, expirationTime, unitCaster = UnitAura(icon.Unit, iName, nil, filter);
					if ( buffName ) then --and expirationTime > maxExpirationTime and ((( unitCaster == "player" ) or ( unitCaster == "pet" ) or ( unitCaster == "vehicle" )) or not icon.OnlyMine) ) then
						--maxExpirationTime = expirationTime;
						if ( icon.texture:GetTexture() ~= iconTexture) then
							icon.texture:SetTexture(iconTexture);
							icon.learnedTexture = true;
						end
						if (icon.presentAlpha) then
							icon:SetAlpha(icon.presentAlpha);
						end
						icon.texture:SetVertexColor(1, 1, 1, 1);
		--~					if ( LBF ) then
		--~ 					LBF:SetNormalVertexColor(icon,1,1,1,1);
		--~ 				end
						if ( count > 1 ) then
							icon.countText:SetText(count);
							icon.countText:Show();
						else
							icon.countText:Hide();
						end
						if ( icon.ShowTimer and not UnitIsDead(icon.Unit)) then
							CooldownFrame_SetTimer(icon.Cooldown, expirationTime - duration, duration, 1);
						end
						processedBuffInAuraNames = true;
					end
				end
				if (processedBuffInAuraNames) then
					 return;
				end

				if (icon.absentAlpha) then
					icon:SetAlpha(icon.absentAlpha);
				end
				if ( icon.presentAlpha == 1 ) and ( icon.absentAlpha == 1) then
					icon.texture:SetVertexColor(1, 1, 1, 1);
				end

				icon.countText:Hide();
				if ( icon.ShowTimer  ) then
					CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
				end
			else
				icon:SetAlpha(0);
				CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
			end
		end
	end
end--[[if ( UnitExists(icon.Unit) ) then
		icon.updateTimer = icon.updateTimer - elapsed;
		local auraNames = TellMeWhen_GetSpellNames(icon.Name)
		local processedBuffInAuraNames = false;
		local i, iName;
		local filter = icon.BuffOrDebuff;
		if icon.OnlyMine then filter = filter.."|PLAYER" end
		
		for i, iName in ipairs(auraNames) do
			local startTime, timeLeft = GetSpellCooldown(iName)
			local buffName, _, iconTexture, count, _, duration, expirationTime, unitCaster = UnitAura(icon.Unit, iName, nil, filter);
			if icon.ShowPBar then
				if not icon.powerbar.texture then
					icon.powerbar.texture = icon.powerbar:CreateTexture()
					icon.powerbar.texture:SetTexture(TellMeWhen_Settings["Texture"]);	  
				end
				
				local power = UnitPower("player")
				local cost = select(4,GetSpellInfo(iName)) or 0
				if not icon.InvertBars then
					icon.powerbar:SetValue(cost - power)
					icon.powerbar.texture:SetTexCoord(0, max(0,min(((cost - power) / cost),1)), 0, 1) --more cheats
				else
					icon.powerbar:SetValue(power)
					icon.powerbar.texture:SetTexCoord(0, max(0,min((power / cost),1)), 0, 1)	 --more cheats
				end
			end
			if icon.ShowCBar then
				if not icon.cooldownbar.texture then
					icon.cooldownbar.texture = icon.cooldownbar:CreateTexture()
					icon.cooldownbar.texture:SetTexture(TellMeWhen_Settings["Texture"]);	  
				end
				if icon.DurationAndCD and #(auraNames) == 1 then
					if not duration then
						if not icon.InvertBars then
							if (timeLeft == 0) then
								percentcomplete = 100
								icon.cooldownbar:SetMinMaxValues(0,  1)
								icon.cooldownbar:SetValue(0)
								icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
								icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
							else
								percentcomplete = (((GetTime() - startTime) / timeLeft) * 100)
								icon.cooldownbar:SetMinMaxValues(0,  timeLeft)
								icon.cooldownbar:SetValue(timeLeft - (GetTime() - startTime))
								icon.cooldownbar.texture:SetTexCoord(0, min((1-(percentcomplete/100)),1), 0, 1)
								icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
							end
						else
							--inverted
							if (timeLeft == 0) then
								percentcomplete = 100
								icon.cooldownbar:SetMinMaxValues(0,  1)
								icon.cooldownbar:SetValue(1)
								icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
								icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
							else
								percentcomplete = (((GetTime() - startTime) / timeLeft) * 100)
								icon.cooldownbar:SetMinMaxValues(0,  timeLeft)
								icon.cooldownbar:SetValue(GetTime() - startTime)
								icon.cooldownbar.texture:SetTexCoord(0, min(((percentcomplete/100)),1), 0, 1)
								icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
							end
						end
					else
						if not icon.InvertBars then
							if (duration == nil or duration == 0) then
								percentcomplete = 100
								icon.cooldownbar:SetMinMaxValues(0,  1)
								icon.cooldownbar:SetValue(0)
								icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
								icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
							else
								percentcomplete = (( duration - (expirationTime - GetTime()) )/duration * 100)
								icon.cooldownbar:SetMinMaxValues(0,  duration)
								icon.cooldownbar:SetValue(expirationTime - GetTime())
								icon.cooldownbar.texture:SetTexCoord(0, min((1-(percentcomplete/100)),1), 0, 1)
								icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
							end
						else
							--inverted
							if (duration == nil or duration == 0) then
								percentcomplete = 100
								icon.cooldownbar:SetMinMaxValues(0,  1)
								icon.cooldownbar:SetValue(0)
							else
								percentcomplete = (( duration - (expirationTime - GetTime()) )/duration * 100)
								icon.cooldownbar:SetMinMaxValues(0,  duration)
								icon.cooldownbar:SetValue(duration - (expirationTime - GetTime()))
								icon.cooldownbar.texture:SetTexCoord(0, min(((percentcomplete/100)),1), 0, 1)
								icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
							end
						end
					end
				else
					if not icon.InvertBars then
						if (duration == nil or duration == 0) then
							percentcomplete = 100
							icon.cooldownbar:SetMinMaxValues(0,  1)
							icon.cooldownbar:SetValue(0)
							icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
							icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
						else
							percentcomplete = (( duration - (expirationTime - GetTime()) )/duration * 100)
							icon.cooldownbar:SetMinMaxValues(0,  duration)
							icon.cooldownbar:SetValue(expirationTime - GetTime())
							icon.cooldownbar.texture:SetTexCoord(0, min((1-(percentcomplete/100)),1), 0, 1)
							icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
						end
					else
						--inverted
						if (duration == nil or duration == 0) then
							percentcomplete = 100
							icon.cooldownbar:SetMinMaxValues(0,  1)
							icon.cooldownbar:SetValue(0)
						else
							percentcomplete = (( duration - (expirationTime - GetTime()) )/duration * 100)
							icon.cooldownbar:SetMinMaxValues(0,  duration)
							icon.cooldownbar:SetValue(duration - (expirationTime - GetTime()))
							icon.cooldownbar.texture:SetTexCoord(0, min(((percentcomplete/100)),1), 0, 1)
							icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
						end
					end
				end
			end
			
			if ( icon.updateTimer <= 0 ) and buffName then
				
				local isEnemy = UnitIsEnemy("player", "target")
				local react = UnitReaction("player", "target") or 5
				if (isEnemy) or (react <= 4) then
					isEnemy = 1
				else
					isEnemy = 0
				end
				if (icon.UnitReact == 0) or (icon.UnitReact == isEnemy) or (icon.UnitReact == 2 and isEnemy == 0 ) then
					
					local maxExpirationTime = 0;
					local processedBuffInAuraNames = false;
					
					local filter = icon.BuffOrDebuff;
					if icon.OnlyMine then filter = filter.."|PLAYER" end
					if ( not TellMeWhen_Icon_ConditionCheck(icon) ) then
						icon:SetAlpha(0);
						return;
					end
					if ( icon.texture:GetTexture() ~= iconTexture) then
						icon.texture:SetTexture(iconTexture);
						icon.learnedTexture = true;
					end
					if (icon.presentAlpha) then
						icon:SetAlpha(icon.presentAlpha);
					end
					icon.texture:SetVertexColor(1, 1, 1, 1);
					if ( LBF ) then
						LBF:SetNormalVertexColor(icon,1,1,1,1);
					end
					if ( count > 1 ) then
						icon.countText:SetText(count);
						icon.countText:Show();
					else
						icon.countText:Hide();
					end
					if ( icon.ShowTimer and not UnitIsDead(icon.Unit)) then
						CooldownFrame_SetTimer(icon.Cooldown, expirationTime - duration, duration, 1);
					end
					processedBuffInAuraNames = true;
				end
			end
			if (processedBuffInAuraNames) then
				return;
			end
			
			if (icon.absentAlpha) then
				icon:SetAlpha(icon.absentAlpha);
			end
			if ( icon.presentAlpha == 1 ) and ( icon.absentAlpha == 1) then
				icon.texture:SetVertexColor(1, 1, 1, 1);
			end
			
			icon.countText:Hide();
			if ( icon.ShowTimer  ) then
				CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
			end
			
	end
		


	else
	icon:SetAlpha(0);
	CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
	end	 
end]]



function TellMeWhen_Icon_BuffCheck(icon)
	if ( UnitExists(icon.Unit) ) then
	--	icon:SetScript("OnUpdate",TellMeWhen_Icon_Buff_OnUpdate)
		
		local auraNames = TellMeWhen_GetSpellNames(icon.Name);
		local maxExpirationTime = 0;
		local processedBuffInAuraNames = false;
		local i, iName;

		local filter = icon.BuffOrDebuff;
		if icon.OnlyMine then filter = filter.."|PLAYER" end

		-- Verify condition is satisfied before showing
		if ( not TellMeWhen_Icon_ConditionCheck(icon) ) then
			icon:SetAlpha(0);
			return;
		end
		for i, iName in ipairs(auraNames) do
	--		local buffName, rank, iconTexture, count, debuffType, duration, expirationTime, unitCaster, isStealable;
			local buffName, _, iconTexture, count, _, duration, expirationTime, unitCaster = UnitAura(icon.Unit, iName, nil, filter);
			if ( buffName ) then --and expirationTime > maxExpirationTime and ((( unitCaster == "player" ) or ( unitCaster == "pet" ) or ( unitCaster == "vehicle" )) or not icon.OnlyMine) ) then
				--maxExpirationTime = expirationTime;
				if ( icon.texture:GetTexture() ~= iconTexture) then
					icon.texture:SetTexture(iconTexture);
					icon.learnedTexture = true;
				end
				if (icon.presentAlpha) then
					TellMeWhen_SetIconAlpha(icon, icon.presentAlpha);
				end
				icon.texture:SetVertexColor(1, 1, 1, 1);
					if ( LBF ) then
 					LBF:SetNormalVertexColor(icon,1,1,1,1);
 				end
				if ( count > 1 ) then
					icon.countText:SetText(count);
					icon.countText:Show();
				else
					icon.countText:Hide();
				end
				if ( icon.ShowTimer and not UnitIsDead(icon.Unit)) then
					CooldownFrame_SetTimer(icon.Cooldown, expirationTime - duration, duration, 1);
				end
				processedBuffInAuraNames = true;
			end
		end
		if (processedBuffInAuraNames) then
			 return;
		end

		if (icon.absentAlpha) then
			TellMeWhen_SetIconAlpha(icon, icon.absentAlpha);
		end
		if ( icon.presentAlpha == 1 ) and ( icon.absentAlpha == 1) then
			icon.texture:SetVertexColor(1, 0.35, 0.35, 1);
		end

		icon.countText:Hide();
		if ( icon.ShowTimer  ) then
			CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
		end
	else
		
		icon:SetAlpha(0);
		CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
		--REMOVER SE DER PROBLEMA
		--icon.cooldownbar:SetScript("OnUpdate",nil)
	end
end


function TellMeWhen_Icon_Reactive_OnEvent(icon, event)
	if ( event == "ACTIONBAR_UPDATE_USABLE") then
		TellMeWhen_Icon_ReactiveCheck(icon);
	elseif ( event == "ACTIONBAR_UPDATE_COOLDOWN" ) then
		if ( icon.ShowTimer ) then
			TellMeWhen_Icon_SpellCooldown_OnEvent(icon, event);
		end
		TellMeWhen_Icon_ReactiveCheck(icon);
	end
end

function TellMeWhen_Icon_Reactive_OnUpdate(icon,elapsed)
	icon.updateTimer = icon.updateTimer - elapsed;
	
	local startTime, timeLeft = GetSpellCooldown(TellMeWhen_GetSpellNames(icon.Name,1));
	if icon.ShowPBar then
		local cost = select(4,GetSpellInfo(icon.Name)) or 0 
		if not icon.InvertBars then
			icon.powerbar:SetValue(cost - UnitPower("player"))
			icon.powerbar.texture:SetTexCoord(0, max(0,min(((cost - UnitPower("player")) / cost),1)), 0, 1) --more cheats
		else
			icon.powerbar:SetValue(UnitPower("player"))
			icon.powerbar.texture:SetTexCoord(0, max(0,min((UnitPower("player") / cost),1)), 0, 1)			--more cheats
		end
	end

	if icon.ShowCBar then
		if not icon.InvertBars then
			if (timeLeft == 0) then
				percentcomplete = 100
				icon.cooldownbar:SetMinMaxValues(0,  1)
				icon.cooldownbar:SetValue(0)
				icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
				icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
			else
				percentcomplete = (((GetTime() - startTime) / timeLeft) * 100)
				icon.cooldownbar:SetMinMaxValues(0,  timeLeft)
				icon.cooldownbar:SetValue(timeLeft - (GetTime() - startTime))
				icon.cooldownbar.texture:SetTexCoord(0, min((1-(percentcomplete/100)),1), 0, 1)
				icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
			end
		else
			--inverted
			if (timeLeft == 0) then
				percentcomplete = 100
				icon.cooldownbar:SetMinMaxValues(0,  1)
				icon.cooldownbar:SetValue(1)
				icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.9)
				icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
			else
				percentcomplete = (((GetTime() - startTime) / timeLeft) * 100)
				icon.cooldownbar:SetMinMaxValues(0,  timeLeft)
				icon.cooldownbar:SetValue(GetTime() - startTime)
				icon.cooldownbar.texture:SetTexCoord(0, min(((percentcomplete/100)),1), 0, 1)
				icon.cooldownbar:SetStatusBarColor(((100 - percentcomplete) / 100) , (percentcomplete/100) + 0.2, 0,0.9)
			end
		end
	end
	if ( icon.updateTimer <= 0 ) and timeLeft then
		icon.updateTimer = TellMeWhen_Settings["Interval"];
		local usable, nomana = IsUsableSpell(TellMeWhen_GetSpellNames(icon.Name,1));
		local inrange = IsSpellInRange(TellMeWhen_GetSpellNames(icon.Name,1), icon.Unit);
		local OnGCD = TellMeWhen_GetGCD() == timeLeft and timeLeft > 0;
		--if range is invalid don't test for it
		if ( inrange == nil ) then
			inrange = 1
		end
		local isEnemy = UnitIsEnemy("player", icon.Unit)
		if (icon.UnitReact == 0) or(icon.UnitReact == isEnemy) or (icon.UnitReact == 2 and isEnemy == nil) then
			if ( usable ) then --and TellMeWhen_GetGCD() < timeLeft ) then
				if( inrange and not nomana  ) then --and timeLeft == 0) then
					icon.texture:SetVertexColor(1,1,1,1)
					icon:SetAlpha(icon.usableAlpha)
				elseif ( not inrange or nomana ) then
					icon.texture:SetVertexColor(.35,.35,.35,1)
					icon:SetAlpha(icon.usableAlpha)
				else
					icon.texture:SetVertexColor(1,1,1,1)
					icon:SetAlpha(icon.unusableAlpha)
				end
			else -- ( not usable and not nomana) then --or ( timeLeft > 1.5 ) then
				--icon.texture:SetVertexColor(1,1,1,1)
				icon:SetAlpha(icon.unusableAlpha)
			end
		else
			icon:SetAlpha(0)
		end
	end
end
function TellMeWhen_Icon_ConditionCheck(icon)
	local retCode = true;
	if ( icon.conditionPresent ) then
		for i=1,#icon.conditions do
			local tempRet = TellMeWhen_Icon_ConditionCheckLevel(icon.conditions[i]);
			if( icon.conditions[i].ConditionAndOr == "OR" ) then
				retCode = retCode or tempRet;
			else
				retCode = retCode and tempRet;
			end
		end
	end
	return retCode;
end

function TellMeWhen_Icon_ConditionCheckLevel(condition)
	local retCode = true;
	
	if ( condition.ConditionType == "HEALTH" ) then
		local percent = 100 * UnitHealth("player")/UnitHealthMax("player");
		retCode = TellMeWhen_Icon_ConditionCheckInternal(condition.ConditionOperator, condition.ConditionLevel, percent);
	elseif ( condition.ConditionType == "POWER" ) then
		local percent = 100 * UnitPower("player")/UnitPowerMax("player");
		retCode = TellMeWhen_Icon_ConditionCheckInternal(condition.ConditionOperator, condition.ConditionLevel, percent);
	end
	return retCode;
end

function TellMeWhen_Icon_ConditionCheckInternal(operator, inLevel, percent)
	local retCode = true;
	local level = tonumber(inLevel)
	
	if ( operator == "==" ) then
		retCode = ( percent == level );
	elseif ( operator == "<" ) then
		retCode = ( percent < level );
	elseif ( operator == "<=" ) then
		retCode = ( percent <= level );
	elseif ( operator == ">" ) then
		retCode = ( percent > level );
	elseif ( operator == ">=" ) then
		retCode = ( percent >= level );
	elseif ( operator == "~=" ) then
		retCode = ( percent ~= level );
	end
	return retCode;
end

function TellMeWhen_Icon_Reactive_OnEvent(icon, event)
	if ( event == "ACTIONBAR_UPDATE_USABLE") then
		TellMeWhen_Icon_ReactiveCheck(icon);
	elseif ( event == "ACTIONBAR_UPDATE_COOLDOWN" ) then
		if ( icon.ShowTimer ) then
			TellMeWhen_Icon_SpellCooldown_OnEvent(icon, event);
		end
		TellMeWhen_Icon_ReactiveCheck(icon);
	end
end

function TellMeWhen_Icon_ReactiveCheck(icon)
	local usable, nomana = IsUsableSpell(TellMeWhen_GetSpellNames(icon.Name,1));
	local _, timeLeft, _ = GetSpellCooldown(icon.Name);
	local inrange = IsSpellInRange(TellMeWhen_GetSpellNames(icon.Name,1), icon.Unit);
	local OnGCD = TellMeWhen_GetGCD() == timeLeft and timeLeft > 0;
	--if range is invalid don't test for it
	if ( inrange == nil ) then
		inrange = 1
	end
	if ( usable ) then --and TellMeWhen_GetGCD() < timeLeft ) then
		if( inrange and not nomana  ) then --and timeLeft == 0) then
			icon.texture:SetVertexColor(1,1,1,1)
			TellMeWhen_SetIconAlpha(icon, icon.usableAlpha);
		elseif ( not inrange or nomana ) then
			icon.texture:SetVertexColor(.35,.35,.35,1)
			TellMeWhen_SetIconAlpha(icon, icon.usableAlpha);
		else
			icon.texture:SetVertexColor(1,1,1,1)
			TellMeWhen_SetIconAlpha(icon, icon.unusableAlpha);
		end
	else -- ( not usable and not nomana) then --or ( timeLeft > 1.5 ) then
		--icon.texture:SetVertexColor(1,1,1,1)
		TellMeWhen_SetIconAlpha(icon, icon.unusableAlpha);
	end
end



function TellMeWhen_Icon_WpnEnchant_OnEvent(icon, event, ...)
	if ( event == "UNIT_INVENTORY_CHANGED" ) and ( select(1, ...) == "player" ) then
		local slotID;
		if ( icon.WpnEnchantType == "mainhand" ) then
			slotID = GetInventorySlotInfo("MainHandSlot");
		elseif ( icon.WpnEnchantType == "offhand" ) then
			slotID = GetInventorySlotInfo("SecondaryHandSlot");
		end
		local wpnTexture = GetInventoryItemTexture("player", slotID);
		if ( wpnTexture ) then
			icon.texture:SetTexture(wpnTexture);
		else
			icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
		end
		icon.startTime = GetTime();
	end
end

function TellMeWhen_Icon_WpnEnchant_OnUpdate(icon, elapsed)
	icon.updateTimer = icon.updateTimer - elapsed;
	if ( icon.updateTimer <= 0 ) then
		icon.updateTimer = TellMeWhen_Settings["Interval"];
		local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo();
		if ( icon.WpnEnchantType == "mainhand" ) and ( hasMainHandEnchant ) then
			TellMeWhen_SetIconAlpha(icon, icon.presentAlpha);
			if ( mainHandCharges > 1 ) then
				icon.countText:SetText(mainHandCharges);
				icon.countText:Show();
			else
				icon.countText:Hide();
			end
			if (icon.ShowTimer) then
				if ( icon.startTime ~= nil ) then
					CooldownFrame_SetTimer(icon.Cooldown, GetTime(), mainHandExpiration/1000, 1);
				else
					icon.startTime = GetTime();
				end
			end
		elseif ( icon.WpnEnchantType == "offhand" ) and ( hasOffHandEnchant ) then
			TellMeWhen_SetIconAlpha(icon, icon.presentAlpha);
			if ( offHandCharges > 1 ) then
				icon.countText:SetText(offHandCharges);
				icon.countText:Show();
			else
				icon.countText:Hide();
			end
			if (icon.ShowTimer) then
				if ( icon.startTime ~= nil ) then
					CooldownFrame_SetTimer(icon.Cooldown, GetTime(), offHandExpiration/1000, 1);
				else
					icon.startTime = GetTime();
				end
			end
		else
			TellMeWhen_SetIconAlpha(icon, icon.absentAlpha);
			CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
		end
	end
end


function TellMeWhen_Icon_Totem_OnEvent(icon, event, ...)
	--Totems have changed! Do something!
	local spellName, spellRank, spellIconPath,totemNames
	totemNames = TellMeWhen_GetSpellNames(icon.Name);
	local foundTotem = false
	for iSlot=1, 4 do
		local haveTotem, totemName, startTime, totemDuration, totemIcon = GetTotemInfo(iSlot)
		for i, iName in ipairs(totemNames) do
			spellName, spellRank, spellIconPath = GetSpellInfo(iName)
			if ( totemName and totemName:find(iName) ) then
				foundTotem = true;
				icon.texture:SetVertexColor(1,1,1,1);
				TellMeWhen_SetIconAlpha(icon, icon.presentAlpha);

				if ( icon.texture:GetTexture() ~= totemIcon ) then
					icon.texture:SetTexture( totemIcon );
					icon.learnedTexture = true;
				--else
					--icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
				end

				if ( icon.ShowTimer ) then
					-- The startTime reported here is both cast to an int and off by
					-- a latency meaning it can be significantly low.  So we cache the GetTime
					-- that the totem actually appeared, so long as GetTime is reasonably close to
					-- startTime (since the totems may have been out for awhile before this runs.)
					local precise = GetTime()
					if ( precise - startTime > 1 ) then
						precise = startTime + 1
					end
					CooldownFrame_SetTimer(icon.Cooldown, precise, totemDuration, 1);
				end
				icon:SetScript("OnUpdate", nil);
				break
			end
		end
	end
	if (not foundTotem) then
		if ( icon.absentAlpha == 1 and icon.presentAlpha == 1) then
			icon.texture:SetVertexColor(1,0.35,0.35,1);
		end
		TellMeWhen_SetIconAlpha(icon, icon.absentAlpha);
		CooldownFrame_SetTimer(icon.Cooldown, 0, 0, 0);
	end

end

function TellMeWhen_GetMatchedBuffName(checkName, buffName)
	local buffNames = TellMeWhen_SplitNames(buffName)
	if tonumber( checkName ) ~= nil then
		checkName = GetSpellInfo(checkName)
	end

	local i, iName
	for i, iName in ipairs(buffNames) do
		if ( checkName == iName ) then
			return iName
		end
	end
	return nil
end

function TellMeWhen_GetSpellNames(buffName,firstOnly)
	local buffNames;
	if (TellMeWhen_BuffEquivalencies[buffName]) then
		 buffNames = TellMeWhen_SplitNames(TellMeWhen_BuffEquivalencies[buffName],"spell");
	else
		 buffNames = TellMeWhen_SplitNames(buffName,"spell")
	end
	if ( firstOnly ) then
		return buffNames[1]
	end
	return buffNames
end

function TellMeWhen_GetItemNames(buffName,firstOnly)
	local buffNames = TellMeWhen_SplitNames(buffName,"item")
	if ( firstOnly ) then
		return buffNames[1]
	end
	return buffNames
end

function TellMeWhen_GetItemIDs(buffName,firstOnly)
	local buffNames = TellMeWhen_SplitNames(buffName,"item")
	if ( firstOnly ) then
		return buffNames[1]
	end
	return buffNames
end

function TellMeWhen_SplitNames(buffName,convertIDs)
	-- If buffName contains one or more semicolons, split the list into parts
	local buffNames = {}
	if (buffName:find(";") ~= nil) then
		buffNames = { strsplit(";", buffName) }
	else
		buffNames = { buffName }
	end

	local i, iName
	for i, iName in ipairs(buffNames) do
		if (tonumber( iName ) ~= nil) then
			if (convertIDs == "item") then
				buffNames[i] = GetItemInfo(iName)
			else
				buffNames[i] = GetSpellInfo(iName)
			end
		end
	end

	return buffNames
end

function TellMeWhen_SetIconAlpha(icon, alphaScale)
	icon:SetAlpha( alphaScale * ( icon.baseAlpha / 100.0 ) );
end
function TellMeWhen_SkinCallback(arg, SkinID, Gloss, Backdrop, Group, Button, Colors)
-- when ButtonFacade skin is changed

-- Put info into TellMeWhen_Settings for later
 --[[ if not Group then

 else
 	TellMeWhen_Settings[Group]["SkinID"] = SkinID
 	TellMeWhen_Settings[Group]["Gloss"] = Gloss
 	TellMeWhen_Settings[Group]["Backdrop"] = Backdrop
 	TellMeWhen_Settings[Group]["Colors"] = Colors
 end]]


end
