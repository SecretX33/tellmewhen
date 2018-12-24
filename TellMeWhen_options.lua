-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Cybeloras of Mal'Ganis
-- --------------------
local LSM = LibStub("LibSharedMedia-3.0")

-- Editado aqui para desabilitar a trava de combate
function TellMeWhen_SlashCommand(cmd)
	if ( cmd == TELLMEWHEN_CMD_RESET ) and not UnitAffectingCombat("player") then
		TellMeWhen_Reset();
	elseif (cmd == TELLMEWHEN_CMD_OPTIONS) then
		TellMeWhen_ShowConfig();
	else
		TellMeWhen_LockToggle();
	end
	--[[else
		DEFAULT_CHAT_FRAME:AddMessage(TELLMEWHEN_CMD_ERROR)
	end]]--
end


-- -----------------------
-- INTERFACE OPTIONS PANEL
-- -----------------------

function TellMeWhen_GroupPositionReset_OnClick(groupID)
	local group = _G["TellMeWhen_Group"..groupID];
	TellMeWhen_Settings["Groups"][groupID]["Scale"] = 2.0
	TellMeWhen_Update();
	group:SetPoint("TOPLEFT", "UIParent", "CENTER", 0, 0);
	DEFAULT_CHAT_FRAME:AddMessage("TellMeWhen Group "..groupID.." position reset.");
end

function TellMeWhen_LockToggle()
	if ( TellMeWhen_Settings["Locked"] ) then
		TellMeWhen_Settings["Locked"] = false;
	else
		TellMeWhen_Settings["Locked"] = true;
	end
	PlaySound("UChatScrollButton");
	TellMeWhen_Update();
end

function TellMeWhen_Reset()
	TellMeWhen_Settings = CopyTable(TellMeWhen_Defaults);
	for groupID = 1, TELLMEWHEN_MAXGROUPS do
		local group = _G["TellMeWhen_Group"..groupID];
		group:ClearAllPoints();
		group:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", 100, -50 - 30*groupID);
		TellMeWhen_Settings["Groups"][groupID]["Enabled"] = false;
	end
	TellMeWhen_Settings["Groups"][1]["Enabled"] = true;
	TellMeWhen_Update();			-- default setting is unlocked?
	DEFAULT_CHAT_FRAME:AddMessage("[TellMeWhen]: Groups have been Reset");
end


function TellMeWhen_ShowConfig()
	local uIPanel = _G["InterfaceOptionsTellMeWhenPanel"];
	InterfaceOptionsFrame_OpenToCategory(uIPanel);
end



function TellMeWhen_Cancel()
	TellMeWhen_Settings = CopyTable(TellMeWhen_OldSettings);
	TellMeWhen_Update();
end

--	--------------------
--	INTERFACE OPTIONS
--	--------------------

-- TODO: just iterate over a group template
local options = {
   type = "group",
   args = {
      main = {
         type = "group",
         name = "Main Options",
         order = 1,
         args = {
			header = {
               name = TELLMEWHEN_ICON_TOOLTIP1 .. " " .. TELLMEWHEN_VERSION,
               type = "header",
               order = 1,
            },
            togglelock = {
               name = TELLMEWHEN_UIPANEL_LOCKUNLOCK,
               desc = TELLMEWHEN_UIPANEL_SUBTEXT2,
               type = "toggle",
               order = 2,
               set = function(info,val)
                  TellMeWhen_Settings["Locked"] = val;
                  TellMeWhen_Update();
               end,
               get = function(info) return TellMeWhen_Settings["Locked"] end
            },
            bartexture = {
               name = TELLMEWHEN_UIPANEL_BARTEXTURE,
               type = "select",
               order = 3,
               dialogControl = 'LSM30_Statusbar',
               values = LSM:HashTable("statusbar"),
               set = function(info,val)
                  TellMeWhen_Settings["Texture"] = LSM:Fetch("statusbar",val)
                  TellMeWhen_Settings["TextureName"] = val
                  TellMeWhen_Update()
               end,
               get = function(info) return TellMeWhen_Settings["TextureName"] end
            },
			updinterval = {
				 name = TELLMEWHEN_UIPANEL_UPDATEINTERVAL,
				 desc = TELLMEWHEN_UIPANEL_TOOLTIP_UPDATEINTERVAL,
				 type = "range",
				 order = 10,
				 min = 0,
				 max = 1,
				 step = 0.01,
				 bigStep = 0.01,
				 set = function(info,val)
					TellMeWhen_Settings["Interval"] = val;
					TellMeWhen_Update()
				 end,
				 get = function(info) return TellMeWhen_Settings["Interval"] end
				 
			  },
			resetall = {
				 name = TELLMEWHEN_UIPANEL_ALLRESET,
				 desc = TELLMEWHEN_UIPANEL_TOOLTIP_ALLRESET,
				 type = "execute",
				 order = 12,
				 confirm = true,
				 func = function() TellMeWhen_Reset() end,
            },
            group1 = {
               type = "group",
               name = "Icon Group 1",
               order = 1,
               args = {
                  group1enable = {
                     name = "Toggle Group",
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ENABLEGROUP,
                     type = "toggle",
                     order = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][1]["Enabled"] = val;
                        TellMeWhen_Group_Update(1)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][1]["Enabled"] end
                  },
                  group1columns = {
                     name = TELLMEWHEN_UIPANEL_COLUMNS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_COLUMNS,
                     type = "range",
                     order = 10,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][1]["Columns"] = val;
                        TellMeWhen_Group_Update(1)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][1]["Columns"] end
                     
                  },
                  group1rows = {
                     name = TELLMEWHEN_UIPANEL_ROWS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ROWS,
                     type = "range",
                     order = 11,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][1]["Rows"] = val;
                        TellMeWhen_Group_Update(1)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][1]["Rows"] end
                     
                  },
                  group1combat = {
                     name = TELLMEWHEN_UIPANEL_ONLYINCOMBAT,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ONLYINCOMBAT,
                     type = "toggle",
                     order = 2,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][1]["OnlyInCombat"] = val;
                        TellMeWhen_Group_Update(1);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][1]["OnlyInCombat"] end
                  },
                  group1mainspec = {
                     name = TELLMEWHEN_UIPANEL_PRIMARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_PRIMARYSPEC,
                     type = "toggle",
                     order = 3,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][1]["PrimarySpec"] = val;
                        TellMeWhen_Group_Update(1);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][1]["PrimarySpec"] end
                  },
                  group1offspec = {
                     name = TELLMEWHEN_UIPANEL_SECONDARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_SECONDARYSPEC,
                     type = "toggle",
                     order = 4,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][1]["SecondarySpec"] = val;
                        TellMeWhen_Group_Update(1);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][1]["SecondarySpec"] end
                  },
                  group1reset = {
                     name = TELLMEWHEN_UIPANEL_GROUPRESET,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_GROUPRESET,
                     type = "execute",
                     order = 13,
                     func = function() TellMeWhen_GroupPositionReset_OnClick(1) end
                  }
               }
            },
            group2 = {
               type = "group",
               name = "Icon Group 2",
               order = 2,
               args = {
                  group2enable = {
                     name = "Toggle Group",
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ENABLEGROUP,
                     type = "toggle",
                     order = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][2]["Enabled"] = val;
                        TellMeWhen_Group_Update(2)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][2]["Enabled"] end
                  },
                  group2columns = {
                     name = TELLMEWHEN_UIPANEL_COLUMNS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_COLUMNS,
                     type = "range",
                     order = 10,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][2]["Columns"] = val;
                        TellMeWhen_Group_Update(2)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][2]["Columns"] end
                     
                  },
                  group2rows = {
                     name = TELLMEWHEN_UIPANEL_ROWS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ROWS,
                     type = "range",
                     order = 11,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][2]["Rows"] = val;
                        TellMeWhen_Group_Update(2)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][2]["Rows"] end
                     
                  },
                  group2combat = {
                     name = TELLMEWHEN_UIPANEL_ONLYINCOMBAT,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ONLYINCOMBAT,
                     type = "toggle",
                     order = 2,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][2]["OnlyInCombat"] = val;
                        TellMeWhen_Group_Update(2);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][2]["OnlyInCombat"] end
                  },
                  group2mainspec = {
                     name = TELLMEWHEN_UIPANEL_PRIMARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_PRIMARYSPEC,
                     type = "toggle",
                     order = 3,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][2]["PrimarySpec"] = val;
                        TellMeWhen_Group_Update(2);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][2]["PrimarySpec"] end
                  },
                  group2offspec = {
                     name = TELLMEWHEN_UIPANEL_SECONDARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_SECONDARYSPEC,
                     type = "toggle",
                     order = 4,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][2]["SecondarySpec"] = val;
                        TellMeWhen_Group_Update(2);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][2]["SecondarySpec"] end
                  },
                  group2reset = {
                     name = TELLMEWHEN_UIPANEL_GROUPRESET,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_GROUPRESET,
                     type = "execute",
                     order = 13,
                     func = function() TellMeWhen_GroupPositionReset_OnClick(2) end
                  }
               }
            },
            group3 = {
               type = "group",
               name = "Icon Group 3",
               order = 3,
               args = {
                  group3enable = {
                     name = "Toggle Group",
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ENABLEGROUP,
                     type = "toggle",
                     order = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][3]["Enabled"] = val;
                        TellMeWhen_Group_Update(3)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][3]["Enabled"] end
                  },
                  group3columns = {
                     name = TELLMEWHEN_UIPANEL_COLUMNS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_COLUMNS,
                     type = "range",
                     order = 10,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][3]["Columns"] = val;
                        TellMeWhen_Group_Update(3)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][3]["Columns"] end
                     
                  },
                  group3rows = {
                     name = TELLMEWHEN_UIPANEL_ROWS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ROWS,
                     type = "range",
                     order = 11,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][3]["Rows"] = val;
                        TellMeWhen_Group_Update(3)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][3]["Rows"] end
                     
                  },
                  group3combat = {
                     name = TELLMEWHEN_UIPANEL_ONLYINCOMBAT,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ONLYINCOMBAT,
                     type = "toggle",
                     order = 2,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][3]["OnlyInCombat"] = val;
                        TellMeWhen_Group_Update(3);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][3]["OnlyInCombat"] end
                  },
                  group3mainspec = {
                     name = TELLMEWHEN_UIPANEL_PRIMARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_PRIMARYSPEC,
                     type = "toggle",
                     order = 3,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][3]["PrimarySpec"] = val;
                        TellMeWhen_Group_Update(3);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][3]["PrimarySpec"] end
                  },
                  group3offspec = {
                     name = TELLMEWHEN_UIPANEL_SECONDARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_SECONDARYSPEC,
                     type = "toggle",
                     order = 4,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][3]["SecondarySpec"] = val;
                        TellMeWhen_Group_Update(3);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][3]["SecondarySpec"] end
                  },
                  group3reset = {
                     name = TELLMEWHEN_UIPANEL_GROUPRESET,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_GROUPRESET,
                     type = "execute",
                     order = 13,
                     func = function() TellMeWhen_GroupPositionReset_OnClick(3) end
                  }
               }
            },
            group4 = {
               type = "group",
               name = "Icon Group 4",
               order = 4,
               args = {
                  group4enable = {
                     name = "Toggle Group",
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ENABLEGROUP,
                     type = "toggle",
                     order = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][4]["Enabled"] = val;
                        TellMeWhen_Group_Update(4)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][4]["Enabled"] end
                  },
                  group4columns = {
                     name = TELLMEWHEN_UIPANEL_COLUMNS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_COLUMNS,
                     type = "range",
                     order = 10,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][4]["Columns"] = val;
                        TellMeWhen_Group_Update(4)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][4]["Columns"] end
                     
                  },
                  group4rows = {
                     name = TELLMEWHEN_UIPANEL_ROWS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ROWS,
                     type = "range",
                     order = 11,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][4]["Rows"] = val;
                        TellMeWhen_Group_Update(4)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][4]["Rows"] end
                     
                  },
                  group4combat = {
                     name = TELLMEWHEN_UIPANEL_ONLYINCOMBAT,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ONLYINCOMBAT,
                     type = "toggle",
                     order = 2,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][4]["OnlyInCombat"] = val;
                        TellMeWhen_Group_Update(4);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][4]["OnlyInCombat"] end
                  },
                  group4mainspec = {
                     name = TELLMEWHEN_UIPANEL_PRIMARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_PRIMARYSPEC,
                     type = "toggle",
                     order = 3,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][4]["PrimarySpec"] = val;
                        TellMeWhen_Group_Update(4);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][4]["PrimarySpec"] end
                  },
                  group4offspec = {
                     name = TELLMEWHEN_UIPANEL_SECONDARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_SECONDARYSPEC,
                     type = "toggle",
                     order = 4,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][4]["SecondarySpec"] = val;
                        TellMeWhen_Group_Update(4);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][4]["SecondarySpec"] end
                  },
                  group4reset = {
                     name = TELLMEWHEN_UIPANEL_GROUPRESET,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_GROUPRESET,
                     type = "execute",
                     order = 13,
                     func = function() TellMeWhen_GroupPositionReset_OnClick(4) end
                  }
               }
            },
            group5 = {
               type = "group",
               name = "Icon Group 5",
               order = 5,
               args = {
                  group5enable = {
                     name = "Toggle Group",
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ENABLEGROUP,
                     type = "toggle",
                     order = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][5]["Enabled"] = val;
                        TellMeWhen_Group_Update(5)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][5]["Enabled"] end
                  },
                  group5columns = {
                     name = TELLMEWHEN_UIPANEL_COLUMNS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_COLUMNS,
                     type = "range",
                     order = 10,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][5]["Columns"] = val;
                        TellMeWhen_Group_Update(5)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][5]["Columns"] end
                     
                  },
                  group5rows = {
                     name = TELLMEWHEN_UIPANEL_ROWS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ROWS,
                     type = "range",
                     order = 11,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][5]["Rows"] = val;
                        TellMeWhen_Group_Update(5)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][5]["Rows"] end
                     
                  },
                  group5combat = {
                     name = TELLMEWHEN_UIPANEL_ONLYINCOMBAT,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ONLYINCOMBAT,
                     type = "toggle",
                     order = 2,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][5]["OnlyInCombat"] = val;
                        TellMeWhen_Group_Update(5);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][5]["OnlyInCombat"] end
                  },
                  group5mainspec = {
                     name = TELLMEWHEN_UIPANEL_PRIMARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_PRIMARYSPEC,
                     type = "toggle",
                     order = 3,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][5]["PrimarySpec"] = val;
                        TellMeWhen_Group_Update(5);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][5]["PrimarySpec"] end
                  },
                  group5offspec = {
                     name = TELLMEWHEN_UIPANEL_SECONDARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_SECONDARYSPEC,
                     type = "toggle",
                     order = 4,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][5]["SecondarySpec"] = val;
                        TellMeWhen_Group_Update(5);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][5]["SecondarySpec"] end
                  },
                  group5reset = {
                     name = TELLMEWHEN_UIPANEL_GROUPRESET,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_GROUPRESET,
                     type = "execute",
                     order = 13,
                     func = function() TellMeWhen_GroupPositionReset_OnClick(5) end
                  }
               }
            },
            group6 = {
               type = "group",
               name = "Icon Group 6",
               order = 6,
               args = {
                  group6enable = {
                     name = "Toggle Group",
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ENABLEGROUP,
                     type = "toggle",
                     order = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][6]["Enabled"] = val;
                        TellMeWhen_Group_Update(6)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][6]["Enabled"] end
                  },
                  group6columns = {
                     name = TELLMEWHEN_UIPANEL_COLUMNS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_COLUMNS,
                     type = "range",
                     order = 10,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][6]["Columns"] = val;
                        TellMeWhen_Group_Update(6)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][6]["Columns"] end
                     
                  },
                  group6rows = {
                     name = TELLMEWHEN_UIPANEL_ROWS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ROWS,
                     type = "range",
                     order = 11,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][6]["Rows"] = val;
                        TellMeWhen_Group_Update(6)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][6]["Rows"] end
                     
                  },
                  group6combat = {
                     name = TELLMEWHEN_UIPANEL_ONLYINCOMBAT,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ONLYINCOMBAT,
                     type = "toggle",
                     order = 2,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][6]["OnlyInCombat"] = val;
                        TellMeWhen_Group_Update(6);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][6]["OnlyInCombat"] end
                  },
                  group6mainspec = {
                     name = TELLMEWHEN_UIPANEL_PRIMARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_PRIMARYSPEC,
                     type = "toggle",
                     order = 3,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][6]["PrimarySpec"] = val;
                        TellMeWhen_Group_Update(6);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][6]["PrimarySpec"] end
                  },
                  group6offspec = {
                     name = TELLMEWHEN_UIPANEL_SECONDARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_SECONDARYSPEC,
                     type = "toggle",
                     order = 4,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][6]["SecondarySpec"] = val;
                        TellMeWhen_Group_Update(6);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][6]["SecondarySpec"] end
                  },
                  group6reset = {
                     name = TELLMEWHEN_UIPANEL_GROUPRESET,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_GROUPRESET,
                     type = "execute",
                     order = 13,
                     func = function() TellMeWhen_GroupPositionReset_OnClick(6) end
                  }
               }
            },
            group7 = {
               type = "group",
               name = "Icon Group 7",
               order = 7,
               args = {
                  group7enable = {
                     name = "Toggle Group",
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ENABLEGROUP,
                     type = "toggle",
                     order = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][7]["Enabled"] = val;
                        TellMeWhen_Group_Update(7)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][7]["Enabled"] end
                  },
                  group7columns = {
                     name = TELLMEWHEN_UIPANEL_COLUMNS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_COLUMNS,
                     type = "range",
                     order = 10,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][7]["Columns"] = val;
                        TellMeWhen_Group_Update(7)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][7]["Columns"] end
                     
                  },
                  group7rows = {
                     name = TELLMEWHEN_UIPANEL_ROWS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ROWS,
                     type = "range",
                     order = 11,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][7]["Rows"] = val;
                        TellMeWhen_Group_Update(7)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][7]["Rows"] end
                     
                  },
                  group7combat = {
                     name = TELLMEWHEN_UIPANEL_ONLYINCOMBAT,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ONLYINCOMBAT,
                     type = "toggle",
                     order = 2,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][7]["OnlyInCombat"] = val;
                        TellMeWhen_Group_Update(7);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][7]["OnlyInCombat"] end
                  },
                  group7mainspec = {
                     name = TELLMEWHEN_UIPANEL_PRIMARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_PRIMARYSPEC,
                     type = "toggle",
                     order = 3,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][7]["PrimarySpec"] = val;
                        TellMeWhen_Group_Update(7);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][7]["PrimarySpec"] end
                  },
                  group7offspec = {
                     name = TELLMEWHEN_UIPANEL_SECONDARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_SECONDARYSPEC,
                     type = "toggle",
                     order = 4,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][7]["SecondarySpec"] = val;
                        TellMeWhen_Group_Update(7);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][7]["SecondarySpec"] end
                  },
                  group7reset = {
                     name = TELLMEWHEN_UIPANEL_GROUPRESET,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_GROUPRESET,
                     type = "execute",
                     order = 13,
                     func = function() TellMeWhen_GroupPositionReset_OnClick(7) end
                  }
               }
            },
            group8 = {
               type = "group",
               name = "Icon Group 8",
               order = 8,
               args = {
                  group8enable = {
                     name = "Toggle Group",
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ENABLEGROUP,
                     type = "toggle",
                     order = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][8]["Enabled"] = val;
                        TellMeWhen_Group_Update(8)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][8]["Enabled"] end
                  },
                  group8columns = {
                     name = TELLMEWHEN_UIPANEL_COLUMNS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_COLUMNS,
                     type = "range",
                     order = 10,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][8]["Columns"] = val;
                        TellMeWhen_Group_Update(8)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][8]["Columns"] end
                     
                  },
                  group8rows = {
                     name = TELLMEWHEN_UIPANEL_ROWS,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ROWS,
                     type = "range",
                     order = 11,
                     min = 1,
                     max = TELLMEWHEN_MAXROWS,
                     step = 1,
                     bigStep = 1,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][8]["Rows"] = val;
                        TellMeWhen_Group_Update(8)
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][8]["Rows"] end
                     
                  },
                  group8combat = {
                     name = TELLMEWHEN_UIPANEL_ONLYINCOMBAT,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_ONLYINCOMBAT,
                     type = "toggle",
                     order = 2,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][8]["OnlyInCombat"] = val;
                        TellMeWhen_Group_Update(8);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][8]["OnlyInCombat"] end
                  },
                  group8mainspec = {
                     name = TELLMEWHEN_UIPANEL_PRIMARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_PRIMARYSPEC,
                     type = "toggle",
                     order = 3,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][8]["PrimarySpec"] = val;
                        TellMeWhen_Group_Update(8);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][8]["PrimarySpec"] end
                  },
                  group8offspec = {
                     name = TELLMEWHEN_UIPANEL_SECONDARYSPEC,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_SECONDARYSPEC,
                     type = "toggle",
                     order = 4,
                     set = function(info,val)
                        TellMeWhen_Settings["Groups"][8]["SecondarySpec"] = val;
                        TellMeWhen_Group_Update(8);
                     end,
                     get = function(info) return TellMeWhen_Settings["Groups"][8]["SecondarySpec"] end
                  },
                  group8reset = {
                     name = TELLMEWHEN_UIPANEL_GROUPRESET,
                     desc = TELLMEWHEN_UIPANEL_TOOLTIP_GROUPRESET,
                     type = "execute",
                     order = 13,
                     func = function() TellMeWhen_GroupPositionReset_OnClick(8) end
                  }
               }
            }
         }
      }
   }
}



LibStub("AceConfig-3.0"):RegisterOptionsTable("TellMeWhen Options", options)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TellMeWhen Options","TellMeWhen")

-- --------
-- ICON GUI
-- --------

TellMeWhen_CurrentIcon = { groupID = 1, iconID = 1 };		-- a dirty hack, i know.

StaticPopupDialogs["TELLMEWHEN_CHOOSENAME_DIALOG"] = {
	text = TELLMEWHEN_CHOOSENAME_DIALOG,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 200,
	OnShow = function(icon)
		local groupID = TellMeWhen_CurrentIcon["groupID"];
		local iconID = TellMeWhen_CurrentIcon["iconID"];
		local text = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["Name"];
		_G[icon:GetName().."EditBox"]:SetText(text);
		_G[icon:GetName().."EditBox"]:SetFocus();
	end,
	OnAccept = function(icon)
		local base = icon:GetName()
		local editbox = _G[(base .. "EditBox")]
		TellMeWhen_IconMenu_ChooseName(editbox:GetText())
	end,
	EditBoxOnEnterPressed = function(icon)
		local base = icon:GetParent():GetName()
		local editbox = _G[(base .. "EditBox")]
		TellMeWhen_IconMenu_ChooseName(editbox:GetText())
		icon:GetParent():Hide();
		
	--[[	local text = _G[icon:GetParent():GetName().."EditBox"]:GetText();
		TellMeWhen_IconMenu_ChooseName(text);
		icon:GetParent():Hide();]]
	end,
	EditBoxOnEscapePressed = function(icon)
		icon:GetParent():Hide();
	end,
	OnHide = function(icon)
		if ( ChatFrameEditBox and ChatFrameEditBox:IsVisible() ) then
			ChatFrameEditBox:SetFocus();
		end
		local base = icon:GetName()
		local editbox = _G[(base .. "EditBox")]
		editbox:SetText("");
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

TellMeWhen_IconMenu_CooldownOptions = {
	{ VariableName = "ShowTimer", MenuText = TELLMEWHEN_ICONMENU_SHOWTIMER },
	{ VariableName = "CooldownType", MenuText = TELLMEWHEN_ICONMENU_COOLDOWNTYPE, HasSubmenu = true },
	{ VariableName = "CooldownShowWhen", MenuText = TELLMEWHEN_ICONMENU_SHOWWHEN, HasSubmenu = true },
	{ VariableName = "UnitReact", MenuText = TELLMEWHEN_ICONMENU_REACT, HasSubmenu = true },
	{ VariableName = "Bars", MenuText = TELLMEWHEN_ICONMENU_BARS, HasSubmenu = true },
};

TellMeWhen_IconMenu_ReactiveOptions = {
	{ VariableName = "ShowTimer", MenuText = TELLMEWHEN_ICONMENU_SHOWTIMER },
	{ VariableName = "CooldownShowWhen", MenuText = TELLMEWHEN_ICONMENU_SHOWWHEN, HasSubmenu = true},
	{ VariableName = "UnitReact", MenuText = TELLMEWHEN_ICONMENU_REACT, HasSubmenu = true },
	{ VariableName = "Bars", MenuText = TELLMEWHEN_ICONMENU_BARS, HasSubmenu = true },
};

TellMeWhen_IconMenu_BuffOptions = {
	{ VariableName = "ShowTimer", MenuText = TELLMEWHEN_ICONMENU_SHOWTIMER },
	{ VariableName = "OnlyMine", MenuText = TELLMEWHEN_ICONMENU_ONLYMINE },
	{ VariableName = "BuffOrDebuff", MenuText = TELLMEWHEN_ICONMENU_BUFFTYPE, HasSubmenu = true },
	{ VariableName = "Unit", MenuText = TELLMEWHEN_ICONMENU_UNIT, HasSubmenu = true },
	{ VariableName = "BuffShowWhen", MenuText = TELLMEWHEN_ICONMENU_BUFFSHOWWHEN, HasSubmenu = true },
	{ VariableName = "UnitReact", MenuText = TELLMEWHEN_ICONMENU_REACT, HasSubmenu = true },
	{ VariableName = "Bars", MenuText = TELLMEWHEN_ICONMENU_BARS, HasSubmenu = true },
};

TellMeWhen_IconMenu_WpnEnchantOptions = {
	{ VariableName = "ShowTimer", MenuText = TELLMEWHEN_ICONMENU_SHOWTIMER },
	{ VariableName = "WpnEnchantType", MenuText = TELLMEWHEN_ICONMENU_WPNENCHANTTYPE, HasSubmenu = true },
	{ VariableName = "BuffShowWhen", MenuText = TELLMEWHEN_ICONMENU_SHOWWHEN, HasSubmenu = true },
--	{ VariableName = "Bars", MenuText = TELLMEWHEN_ICONMENU_BARS, HasSubmenu = true },
};

TellMeWhen_IconMenu_TotemOptions = {
	{ VariableName = "ShowTimer", MenuText = TELLMEWHEN_ICONMENU_SHOWTIMER },
	{ VariableName = "Unit", MenuText = TELLMEWHEN_ICONMENU_UNIT, HasSubmenu = true },
	{ VariableName = "BuffShowWhen", MenuText = TELLMEWHEN_ICONMENU_SHOWWHEN, HasSubmenu = true },
};

TellMeWhen_IconMenu_SubMenus = {
	-- the keys on this table need to match the settings variable names
	Type = {
	  	{ Setting = "cooldown", MenuText = TELLMEWHEN_ICONMENU_COOLDOWN },
	  	{ Setting = "buff", MenuText = TELLMEWHEN_ICONMENU_BUFFDEBUFF },
	  	{ Setting = "reactive", MenuText = TELLMEWHEN_ICONMENU_REACTIVE },
	  	{ Setting = "wpnenchant", MenuText = TELLMEWHEN_ICONMENU_WPNENCHANT },
		{ Setting = "totem", MenuText = TELLMEWHEN_ICONMENU_TOTEM },
	},
	CooldownType = {
	  	{ Setting = "spell", MenuText = TELLMEWHEN_ICONMENU_SPELL },
	  	{ Setting = "item", MenuText = TELLMEWHEN_ICONMENU_ITEM },
	},
	BuffOrDebuff = {
	  	{ Setting = "HELPFUL", MenuText = TELLMEWHEN_ICONMENU_BUFF },
	  	{ Setting = "HARMFUL", MenuText = TELLMEWHEN_ICONMENU_DEBUFF },
	},
	Unit = {
		{ Setting = "player", MenuText = TELLMEWHEN_ICONMENU_PLAYER },
		{ Setting = "target", MenuText = TELLMEWHEN_ICONMENU_TARGET },
		{ Setting = "targettarget", MenuText = TELLMEWHEN_ICONMENU_TARGETTARGET },
		{ Setting = "focus", MenuText = TELLMEWHEN_ICONMENU_FOCUS },
		{ Setting = "focustarget", MenuText = TELLMEWHEN_ICONMENU_FOCUSTARGET },
		{ Setting = "pet", MenuText = TELLMEWHEN_ICONMENU_PET },
		{ Setting = "pettarget", MenuText = TELLMEWHEN_ICONMENU_PETTARGET },
	},
	BuffShowWhen = {
	  	{ Setting = "present", MenuText = TELLMEWHEN_ICONMENU_PRESENT },
	  	{ Setting = "absent", MenuText = TELLMEWHEN_ICONMENU_ABSENT },
	  	{ Setting = "always", MenuText = TELLMEWHEN_ICONMENU_ALWAYS },
	},
	CooldownShowWhen = {
	  	{ Setting = "usable", MenuText = TELLMEWHEN_ICONMENU_USABLE },
	  	{ Setting = "unusable", MenuText = TELLMEWHEN_ICONMENU_UNUSABLE },
	  	{ Setting = "always", MenuText = TELLMEWHEN_ICONMENU_ALWAYS },
	},
	WpnEnchantType = {
	  	{ Setting = "mainhand", MenuText = TELLMEWHEN_ICONMENU_MAINHAND },
	  	{ Setting = "offhand", MenuText = TELLMEWHEN_ICONMENU_OFFHAND },
	},
	Bars = {
	  	{ Setting = "ShowPBar", MenuText = TELLMEWHEN_ICONMENU_SHOWPBAR },
		{ Setting = "ShowCBar", MenuText = TELLMEWHEN_ICONMENU_SHOWCBAR },
		{ Setting = "InvertBars", MenuText = TELLMEWHEN_ICONMENU_INVERTBARS },
	},
	UnitReact = {
	  	{ Setting = 0, MenuText = TELLMEWHEN_ICONMENU_EITHER },
	  	{ Setting = 2, MenuText = TELLMEWHEN_ICONMENU_FRIEND },
		{ Setting = 1, MenuText = TELLMEWHEN_ICONMENU_HOSTILE },
	},
};


function TellMeWhen_Icon_OnEnter(icon, motion)
	GameTooltip_SetDefaultAnchor(GameTooltip, icon);
	GameTooltip:AddLine(TELLMEWHEN_ICON_TOOLTIP1, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1);
	GameTooltip:AddLine(TELLMEWHEN_ICON_TOOLTIP2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
	GameTooltip:Show();
end

function TellMeWhen_Icon_OnMouseDown(icon, button)
	if ( button == "RightButton" ) then
 		PlaySound("UChatScrollButton");
		TellMeWhen_CurrentIcon["iconID"] = icon:GetID();		-- yay for dirty hacks
		TellMeWhen_CurrentIcon["groupID"] = icon:GetParent():GetID();
		ToggleDropDownMenu(1, nil, _G[icon:GetName().."DropDown"], "cursor", 0, 0);
 	end
end

function TellMeWhen_IconMenu_Initialize(self)

	local groupID = TellMeWhen_CurrentIcon["groupID"];
	local iconID = TellMeWhen_CurrentIcon["iconID"];

	local name = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["Name"];
	local iconType = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["Type"];
	local enabled = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["Enabled"];
	local conditions = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["Conditions"];

	if ( UIDROPDOWNMENU_MENU_LEVEL == 2 ) then
		local subMenus = TellMeWhen_IconMenu_SubMenus;
		for index, value in ipairs(subMenus[UIDROPDOWNMENU_MENU_VALUE]) do
			-- here, UIDROPDOWNMENU_MENU_VALUE is the setting name
			local info = UIDropDownMenu_CreateInfo();
			info.text = subMenus[UIDROPDOWNMENU_MENU_VALUE][index]["MenuText"];
			info.value = subMenus[UIDROPDOWNMENU_MENU_VALUE][index]["Setting"];
			if UIDROPDOWNMENU_MENU_VALUE == "Bars" then	
				info.checked = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID][info.value];
				info.func = TellMeWhen_IconMenu_ToggleSetting;
				info.keepShownOnClick = true;
			else
				info.checked = ( info.value == TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID][UIDROPDOWNMENU_MENU_VALUE] );
				info.func = TellMeWhen_IconMenu_ChooseSetting;
			end
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
		end
		if (UIDROPDOWNMENU_MENU_VALUE == "Bars") and (iconType == "buff") then	
			local info = UIDropDownMenu_CreateInfo();
			info.text = TELLMEWHEN_ICONMENU_DURATIONANDCD
			info.value = "DurationAndCD"
			info.checked = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID][info.value]
			info.func = TellMeWhen_IconMenu_ToggleSetting;
			info.keepShownOnClick = true;
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
		end
		return;
	end

	-- show name
	if ( name ) and ( name ~= "" ) then
		local info = UIDropDownMenu_CreateInfo();
		--info.text = "\t\t\t\t\t" .. name;
		info.text = "" .. name;
		info.isTitle = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);
	end

	-- choose name
	if ( iconType ~= "wpnenchant" ) then
		info = UIDropDownMenu_CreateInfo();
		info.value = "TELLMEWHEN_ICONMENU_CHOOSENAME";
		--info.text = "\t\t\t\t\t" .. TELLMEWHEN_ICONMENU_CHOOSENAME;
		info.text = "" .. TELLMEWHEN_ICONMENU_CHOOSENAME;
		info.func = TellMeWhen_IconMenu_ShowNameDialog;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);
	end

	-- enable icon
	info = UIDropDownMenu_CreateInfo();
	info.value = "Enabled";
	info.text = TELLMEWHEN_ICONMENU_ENABLE;
	info.checked = enabled;
	info.func = TellMeWhen_IconMenu_ToggleSetting;
	info.keepShownOnClick = true;
	UIDropDownMenu_AddButton(info);

	-- icon type
	info = UIDropDownMenu_CreateInfo();
	info.value = "Type";
	--info.text = "\t\t\t\t\t" .. TELLMEWHEN_ICONMENU_TYPE;
	info.text = "" .. TELLMEWHEN_ICONMENU_TYPE;
	info.hasArrow = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info);

	-- icon alpha
	info = UIDropDownMenu_CreateInfo();
	info.value = "Set Alpha";
	--info.text = "\t\t\t\t\t" .. TELLMEWHEN_ICONMENU_SETALPHA;
	info.text = "" .. TELLMEWHEN_ICONMENU_SETALPHA;
	info.hasArrow = false;
	info.notCheckable = true;
	info.func = TellMeWhen_LoadIconAlpha;
	UIDropDownMenu_AddButton(info);

	-- icon condition
	if ( iconType == "buff" ) then
		info = UIDropDownMenu_CreateInfo();
		if ( #conditions > 0 ) then
			info.text = "" .. TELLMEWHEN_ICONMENU_EDITCONDITION;
			info.value = "Edit condition";
			info.func = TellMeWhen_LoadConditionDialog;
		else
			info.text = "" .. TELLMEWHEN_ICONMENU_ADDCONDITION;
			info.value = "Add condition";
			info.func = TellMeWhen_ClearConditionDialog;
		end
		info.hasArrow = false;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);
	end

	-- additional options
	if ( iconType == "cooldown" )
	or ( iconType == "buff" )
	or ( iconType == "reactive" )
	or ( iconType == "wpnenchant" )
	or ( iconType == "totem" )
	then
		info = UIDropDownMenu_CreateInfo();
		info.disabled = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);

		local moreOptions;
		if ( iconType == "cooldown" ) then
			moreOptions = TellMeWhen_IconMenu_CooldownOptions;
		elseif ( iconType == "buff" ) then
			moreOptions = TellMeWhen_IconMenu_BuffOptions;
		elseif ( iconType == "reactive" ) then
			moreOptions = TellMeWhen_IconMenu_ReactiveOptions;
		elseif ( iconType == "wpnenchant" ) then
			moreOptions = TellMeWhen_IconMenu_WpnEnchantOptions;
		elseif ( iconType == "totem" ) then
			moreOptions = TellMeWhen_IconMenu_TotemOptions;
		end

		for index, value in ipairs(moreOptions) do
			info = UIDropDownMenu_CreateInfo();
			info.hasArrow = moreOptions[index]["HasSubmenu"];
			if info.hasArrow then
				--info.text = "\t\t\t\t\t" .. moreOptions[index]["MenuText"];
				info.text = "" .. moreOptions[index]["MenuText"];
			else
				info.text = moreOptions[index]["MenuText"];
			end
			info.value = moreOptions[index]["VariableName"];
			
			if not info.hasArrow then
				info.func = TellMeWhen_IconMenu_ToggleSetting;
				info.checked = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID][info.value];
				info.notCheckable = false;
			else
				info.notCheckable = true;
			end
			info.keepShownOnClick = true;
			UIDropDownMenu_AddButton(info);
		end

	else
		info = UIDropDownMenu_CreateInfo();
		info.text = TELLMEWHEN_ICONMENU_OPTIONS;
		info.disabled = true;
		UIDropDownMenu_AddButton(info);
	end

	-- clear settings
	if (( name ) and ( name ~= "" )) or ( iconType ~= "" ) then

		info = UIDropDownMenu_CreateInfo();
		info.disabled = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);

		info = UIDropDownMenu_CreateInfo();
		--info.text = "\t\t\t\t\t" .. TELLMEWHEN_ICONMENU_CLEAR;
		info.text = "" .. TELLMEWHEN_ICONMENU_CLEAR;
		info.func = TellMeWhen_IconMenu_ClearSettings;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);
	end

end

function TellMeWhen_IconMenu_ShowNameDialog()
	local dialog = StaticPopup_Show("TELLMEWHEN_CHOOSENAME_DIALOG");
end

function TellMeWhen_IconMenu_ChooseName(text)
	local groupID = TellMeWhen_CurrentIcon["groupID"];
	local iconID = TellMeWhen_CurrentIcon["iconID"];
	TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["Name"] = text;
	_G["TellMeWhen_Group"..groupID.."_Icon"..iconID].learnedTexture = nil;
	TellMeWhen_Icon_Update(_G["TellMeWhen_Group"..groupID.."_Icon"..iconID], groupID, iconID);
end

function TellMeWhen_IconMenu_ToggleSetting(icon)
	local groupID = TellMeWhen_CurrentIcon["groupID"];
	local iconID = TellMeWhen_CurrentIcon["iconID"];
	TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID][icon.value] = icon.checked;
	TellMeWhen_Icon_Update(_G["TellMeWhen_Group"..groupID.."_Icon"..iconID], groupID, iconID);
end

function TellMeWhen_IconMenu_ChooseSetting(icon)

	local groupID = TellMeWhen_CurrentIcon["groupID"];
	local iconID = TellMeWhen_CurrentIcon["iconID"];
	TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID][UIDROPDOWNMENU_MENU_VALUE] = icon.value;
	TellMeWhen_Icon_Update(_G["TellMeWhen_Group"..groupID.."_Icon"..iconID], groupID, iconID);
	if ( UIDROPDOWNMENU_MENU_VALUE == "Type" ) then
		CloseDropDownMenus();
	end
end

function TellMeWhen_IconMenu_ClearSettings()
	local groupID = TellMeWhen_CurrentIcon["groupID"];
	local iconID = TellMeWhen_CurrentIcon["iconID"];
	TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID] = CopyTable(TellMeWhen_Icon_Defaults);
	TellMeWhen_Icon_Update(_G["TellMeWhen_Group"..groupID.."_Icon"..iconID], groupID, iconID);
	CloseDropDownMenus();
end



-- -------------
-- RESIZE BUTTON
-- -------------

function TellMeWhen_GUIButton_OnEnter(icon, shortText, longText)
	local tooltip = _G["GameTooltip"];
	if ( GetCVar("UberTooltips") == "1" ) then
		GameTooltip_SetDefaultAnchor(tooltip, icon);
		tooltip:AddLine(shortText, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1);
		tooltip:AddLine(longText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
		tooltip:Show();
	else
		tooltip:SetOwner(icon, "ANCHOR_BOTTOMLEFT");
		tooltip:SetText(shortText);
	end
end

function TellMeWhen_StartSizing(icon, button)
	local scalingFrame = icon:GetParent();
	scalingFrame.oldScale = scalingFrame:GetScale();
	icon.oldCursorX, icon.oldCursorY = GetCursorPosition(UIParent);
	scalingFrame.oldX = scalingFrame:GetLeft();
	scalingFrame.oldY = scalingFrame:GetTop();
	icon:SetScript("OnUpdate", TellMeWhen_SizeUpdate);
end

function TellMeWhen_SizeUpdate(icon)
	local uiScale = UIParent:GetScale();
	local scalingFrame = icon:GetParent();
	local cursorX, cursorY = GetCursorPosition(UIParent);

	-- calculate new scale
	local newXScale = scalingFrame.oldScale * (cursorX/uiScale - scalingFrame.oldX*scalingFrame.oldScale) / (icon.oldCursorX/uiScale - scalingFrame.oldX*scalingFrame.oldScale) ;
	local newYScale = scalingFrame.oldScale * (cursorY/uiScale - scalingFrame.oldY*scalingFrame.oldScale) / (icon.oldCursorY/uiScale - scalingFrame.oldY*scalingFrame.oldScale) ;
	local newScale = max(0.6, newXScale, newYScale);
	scalingFrame:SetScale(newScale);

	-- calculate new frame position
	local newX = scalingFrame.oldX * scalingFrame.oldScale / newScale;
	local newY = scalingFrame.oldY * scalingFrame.oldScale / newScale;
	scalingFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY);
end

function TellMeWhen_StopSizing(icon, button)
	icon:SetScript("OnUpdate", nil)
	TellMeWhen_Settings["Groups"][icon:GetParent():GetID()]["Scale"] = icon:GetParent():GetScale();
end



-- -----------------------
-- CONDITION EDITOR DIALOG
-- -----------------------

TellMeWhen_IconMenu_ConditionTypes = {
	{ text = TELLMEWHEN_CONDITIONPANEL_HEALTH, value = "HEALTH" },
	{ text = TELLMEWHEN_CONDITIONPANEL_POWER, value = "POWER" },
};

function TellMeWhen_TypeMenuOnClick(self, frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value);
end

function TellMeWhen_TypeMenu(frame)
	for i=1,#TellMeWhen_IconMenu_ConditionTypes do
		local info = UIDropDownMenu_CreateInfo();
		info.func = TellMeWhen_TypeMenuOnClick;
		info.text = TellMeWhen_IconMenu_ConditionTypes[i].text;
		info.value = TellMeWhen_IconMenu_ConditionTypes[i].value ;
		info.arg1 = frame;
		UIDropDownMenu_AddButton(info);
	end
	UIDropDownMenu_JustifyText( frame, "LEFT" );
end

function TellMeWhen_TypeMenuInit(self)
	UIDropDownMenu_Initialize(self, TellMeWhen_TypeMenu, "DROPDOWN");
end

function TellMeWhen_OperatorMenuOnClick(self, frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value);
end

TellMeWhen_IconMenu_ConditionOperators = {
	{ text = TELLMEWHEN_CONDITIONPANEL_EQUALS, value = "==" },
	{ text = TELLMEWHEN_CONDITIONPANEL_NOTEQUAL, value = "~=" },
	{ text = TELLMEWHEN_CONDITIONPANEL_LESS, value = "<" },
	{ text = TELLMEWHEN_CONDITIONPANEL_LESSEQUAL, value = "<=" },
	{ text = TELLMEWHEN_CONDITIONPANEL_GREATER, value = ">" },
	{ text = TELLMEWHEN_CONDITIONPANEL_GREATEREQUAL, value = ">=" },
};

function TellMeWhen_OperatorMenu(frame)
	for i=1,#TellMeWhen_IconMenu_ConditionOperators do
		local info = UIDropDownMenu_CreateInfo();
		info.func = TellMeWhen_OperatorMenuOnClick;
		info.text = TellMeWhen_IconMenu_ConditionOperators[i].text;
		info.value = TellMeWhen_IconMenu_ConditionOperators[i].value ;
		info.arg1 = frame;
		UIDropDownMenu_AddButton(info);
	end
	UIDropDownMenu_JustifyText( frame, "LEFT" );
end

function TellMeWhen_OperatorMenuInit(self)
	UIDropDownMenu_Initialize(self, TellMeWhen_OperatorMenu, "DROPDOWN");
end

TellMeWhen_IconMenu_ConditionAndOrs = {
	{ text = TELLMEWHEN_CONDITIONPANEL_AND, value = "AND" },
	{ text = TELLMEWHEN_CONDITIONPANEL_OR, value = "OR" },
};

function TellMeWhen_AndOrMenuOnClick(self, frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value);
end

function TellMeWhen_AndOrMenu(frame)
	for i=1,#TellMeWhen_IconMenu_ConditionAndOrs do
		local info = UIDropDownMenu_CreateInfo();
		info.func = TellMeWhen_AndOrMenuOnClick;
		info.text = TellMeWhen_IconMenu_ConditionAndOrs[i].text;
		info.value = TellMeWhen_IconMenu_ConditionAndOrs[i].value ;
		info.arg1 = frame;
		UIDropDownMenu_AddButton(info);
	end
	UIDropDownMenu_JustifyText( frame, "CENTER" );
end

function TellMeWhen_AndOrMenuInit(self)
	UIDropDownMenu_Initialize(self, TellMeWhen_AndOrMenu, "DROPDOWN");
end

function TellMeWhen_ConditionCheckboxHandler()
	if ( TellMeWhen_ConditionEditorCheck1:GetChecked() ) then
		TellMeWhen_ConditionEditorGroup1:Show();
		TellMeWhen_ConditionEditorCheck2:Show();
	else
		TellMeWhen_ConditionEditorGroup1:Hide();
		TellMeWhen_ConditionEditorCheck2:Hide();
		TellMeWhen_ConditionEditorCheck2:SetChecked(false);
	end

	if ( TellMeWhen_ConditionEditorCheck2:GetChecked() ) then
		TellMeWhen_ConditionEditorGroup2:Show();
		TellMeWhen_ConditionEditorCheck3:Show();
	else
		TellMeWhen_ConditionEditorGroup2:Hide();
		TellMeWhen_ConditionEditorCheck3:Hide();
		TellMeWhen_ConditionEditorCheck3:SetChecked(false);
	end
	
	if ( TellMeWhen_ConditionEditorCheck2:GetChecked() ) then
		TellMeWhen_ConditionEditorGroup2:Show();
	else
		TellMeWhen_ConditionEditorGroup2:Hide();
	end
	if ( TellMeWhen_ConditionEditorCheck3:GetChecked() ) then
		TellMeWhen_ConditionEditorGroup3:Show();
	else
		TellMeWhen_ConditionEditorGroup3:Hide();
	end
end

function TellMeWhen_ConditionEditorResetOnClick()
	TellMeWhen_ClearConditionDialog();
end

function TellMeWhen_ConditionEditorOkayOnClick()
	local groupID = TellMeWhen_CurrentIcon["groupID"];
	local iconID = TellMeWhen_CurrentIcon["iconID"];
	local conditions = {};

	if ( TellMeWhen_ConditionEditorCheck1:GetChecked() ) then
		local condition1 = {
			ConditionType		= "",
			ConditionOperator	= "",
			ConditionLevel		= "",
			ConditionAndOr		= "AND",
		};
		condition1.ConditionType = UIDropDownMenu_GetSelectedValue(TellMeWhen_ConditionEditorType1);
		condition1.ConditionOperator = UIDropDownMenu_GetSelectedValue(TellMeWhen_ConditionEditorOperator1);
		condition1.ConditionLevel = TellMeWhen_ConditionEditorEdit1:GetText();
		table.insert(conditions, condition1);

		if ( TellMeWhen_ConditionEditorCheck2:GetChecked() ) then
			local condition2 = {
				ConditionType		= "",
				ConditionOperator	= "",
				ConditionLevel		= "",
				ConditionAndOr		= "",
			};
			condition2.ConditionType = UIDropDownMenu_GetSelectedValue(TellMeWhen_ConditionEditorType2);
			condition2.ConditionOperator = UIDropDownMenu_GetSelectedValue(TellMeWhen_ConditionEditorOperator2);
			condition2.ConditionLevel = TellMeWhen_ConditionEditorEdit2:GetText();
			condition2.ConditionAndOr = UIDropDownMenu_GetSelectedValue(TellMeWhen_ConditionEditorAndOr2);
			table.insert(conditions, condition2);

			if ( TellMeWhen_ConditionEditorCheck3:GetChecked() ) then
				local condition3 = {
					ConditionType		= "",
					ConditionOperator	= "",
					ConditionLevel		= "",
					ConditionAndOr		= "",
				};
				condition3.ConditionType = UIDropDownMenu_GetSelectedValue(TellMeWhen_ConditionEditorType3);
				condition3.ConditionOperator = UIDropDownMenu_GetSelectedValue(TellMeWhen_ConditionEditorOperator3);
				condition3.ConditionLevel = TellMeWhen_ConditionEditorEdit3:GetText();
				condition3.ConditionAndOr = UIDropDownMenu_GetSelectedValue(TellMeWhen_ConditionEditorAndOr3);
				table.insert(conditions, condition3);
			end	
		end	
	end	

	TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["Conditions"] = conditions;
end

function TellMeWhen_LoadConditionDialog()
	local groupID = TellMeWhen_CurrentIcon["groupID"];
	local iconID = TellMeWhen_CurrentIcon["iconID"];
	local conditions = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["Conditions"];

	if ( #conditions >= 1 ) then
		TellMeWhen_SetUIDropdownText(TellMeWhen_ConditionEditorType1, conditions[1].ConditionType, TellMeWhen_IconMenu_ConditionTypes);
		TellMeWhen_SetUIDropdownText(TellMeWhen_ConditionEditorOperator1, conditions[1].ConditionOperator, TellMeWhen_IconMenu_ConditionOperators);
		TellMeWhen_ConditionEditorEdit1:SetText(conditions[1].ConditionLevel);
		TellMeWhen_ConditionEditorCheck1:SetChecked(true);
	end
	
	if ( #conditions >= 2 ) then
		TellMeWhen_SetUIDropdownText(TellMeWhen_ConditionEditorType2, conditions[2].ConditionType, TellMeWhen_IconMenu_ConditionTypes);
		TellMeWhen_SetUIDropdownText(TellMeWhen_ConditionEditorOperator2, conditions[2].ConditionOperator, TellMeWhen_IconMenu_ConditionOperators);
		TellMeWhen_ConditionEditorEdit2:SetText(conditions[2].ConditionLevel);
		TellMeWhen_SetUIDropdownText(TellMeWhen_ConditionEditorAndOr2, conditions[2].ConditionAndOr, TellMeWhen_IconMenu_ConditionAndOrs);
		TellMeWhen_ConditionEditorCheck2:SetChecked(true);
	end
	
	if ( #conditions >= 3 ) then
		TellMeWhen_SetUIDropdownText(TellMeWhen_ConditionEditorType3, conditions[3].ConditionType, TellMeWhen_IconMenu_ConditionTypes);
		TellMeWhen_SetUIDropdownText(TellMeWhen_ConditionEditorOperator3, conditions[3].ConditionOperator, TellMeWhen_IconMenu_ConditionOperators);
		TellMeWhen_ConditionEditorEdit3:SetText(conditions[3].ConditionLevel);
		TellMeWhen_SetUIDropdownText(TellMeWhen_ConditionEditorAndOr3, conditions[3].ConditionAndOr, TellMeWhen_IconMenu_ConditionAndOrs);
		TellMeWhen_ConditionEditorCheck3:SetChecked(true);
	end

	TellMeWhen_ConditionCheckboxHandler();
	TellMeWhen_ConditionEditorFrame:Show();
end

function TellMeWhen_ClearConditionDialog()
	UIDropDownMenu_SetSelectedValue(TellMeWhen_ConditionEditorType1, "HEALTH");
	UIDropDownMenu_SetSelectedValue(TellMeWhen_ConditionEditorType2, "HEALTH");
	UIDropDownMenu_SetSelectedValue(TellMeWhen_ConditionEditorType3, "HEALTH");
	UIDropDownMenu_SetSelectedValue(TellMeWhen_ConditionEditorOperator1, "==");
	UIDropDownMenu_SetSelectedValue(TellMeWhen_ConditionEditorOperator2, "==");
	UIDropDownMenu_SetSelectedValue(TellMeWhen_ConditionEditorOperator3, "==");
	UIDropDownMenu_SetText(TellMeWhen_ConditionEditorType1, "");
	UIDropDownMenu_SetText(TellMeWhen_ConditionEditorType2, "");
	UIDropDownMenu_SetText(TellMeWhen_ConditionEditorType3, "");
	UIDropDownMenu_SetText(TellMeWhen_ConditionEditorOperator1, "");
	UIDropDownMenu_SetText(TellMeWhen_ConditionEditorOperator2, "");
	UIDropDownMenu_SetText(TellMeWhen_ConditionEditorOperator3, "");
	TellMeWhen_ConditionEditorEdit1:SetText("");
	TellMeWhen_ConditionEditorEdit2:SetText("");
	TellMeWhen_ConditionEditorEdit3:SetText("");
	UIDropDownMenu_SetSelectedValue(TellMeWhen_ConditionEditorAndOr2, "AND");
	UIDropDownMenu_SetSelectedValue(TellMeWhen_ConditionEditorAndOr3, "AND");
	UIDropDownMenu_SetText(TellMeWhen_ConditionEditorAndOr2, "");
	UIDropDownMenu_SetText(TellMeWhen_ConditionEditorAndOr3, "");
	TellMeWhen_ConditionEditorCheck1:SetChecked(false);
	TellMeWhen_ConditionEditorCheck2:SetChecked(false);
	TellMeWhen_ConditionEditorCheck3:SetChecked(false);
	TellMeWhen_ConditionCheckboxHandler();
	TellMeWhen_ConditionEditorFrame:Show();
end

function TellMeWhen_SetUIDropdownText(frame, value, table)
	UIDropDownMenu_SetSelectedValue(frame, value);
	for i=1,#table do
		if ( table[i].value == value ) then
			UIDropDownMenu_SetText(frame, table[i].text);
			return;
		end
	end
	UIDropDownMenu_SetText(frame, "");
end

function TellMeWhen_LoadIconAlpha()
	local groupID = TellMeWhen_CurrentIcon["groupID"];
	local iconID = TellMeWhen_CurrentIcon["iconID"];
	local alpha = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["Alpha"];
	
	if ( alpha == nil ) then
		alpha = 100;
	end
	
	TellMeWhen_IconAlphaSlider:SetValue(alpha);
	
	TellMeWhen_IconAlphaFrame:Show();
end

function TellMeWhen_IconAlphaOkayOnClick()
	local groupID = TellMeWhen_CurrentIcon["groupID"];
	local iconID = TellMeWhen_CurrentIcon["iconID"];
	TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID]["Alpha"] = TellMeWhen_IconAlphaSlider:GetValue();
end

