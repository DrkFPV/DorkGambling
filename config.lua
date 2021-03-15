local _, core = ...;
core.config = {};

local config = core.config;
local dorkGambling;
core.gameModes = {
    ["Death Roll"] = {
        minPlayers =2,
        maxPlayers =2,
        name = 'Death Roll',
        checked = true},
    ["Coin Toss"] = {
        minPlayers=2,
        maxPlayers=40, 
        name = 'Coin Toss',
        checked = false
    },
    ["High Low"] = {
        minPlayers=2,
        maxPlayers=40, 
        name = 'High Low',
        checked = false
    }
  }

function config:toggle()
    local menu = dorkGambling or config:CreateMenu();
    menu:SetShown(not menu:IsShown())
end

function config:registerTextEvents()
    dorkGambling:RegisterEvent("CHAT_MSG_SYSTEM");
    dorkGambling:RegisterEvent("CHAT_MSG_PARTY");
    dorkGambling:RegisterEvent("CHAT_MSG_PARTY_LEADER");
    dorkGambling:SetScript("OnEvent", core.TextEventHandler)
end

function config:unregisterTextEvents()
end


function config:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text, xSize, ySize)
    local btn = CreateFrame("Button", nil, dorkGambling, "GameMenuButtonTemplate");
    btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
    btn:SetSize(xSize,ySize);
    btn:SetText(text);
    btn:SetNormalFontObject("GameFontNormalLarge");
    btn:SetHighlightFontObject("GameFontHighlightLarge");
    return btn;
end

function config:SetGameType(newValue)
    core.SelectedGameType = core.gameModes[newValue].name;
    UIDropDownMenu_SetText(dorkGambling.gameTypeDropDown, core.SelectedGameType);
    print(core.SelectedGameType)
    CloseDropDownMenus();
end

function core:startGame()
    core.game = core.game or core.newGame(core.SelectedGameType, core.currentBet)
    if core.game.state == nil then
        dorkGambling.startBtn:SetText('Start Roll');
        config:registerTextEvents();
        core.game.state = 'Waiting';
    elseif (core.game.state == 'Waiting') then
        dorkGambling.startBtn:SetText('In Progress');
        core.game.state = 'In Progress'
    end
end

function config:CreateMenu()
    dorkGambling = CreateFrame("FRAME", "dorkGambling", UIParent, "UIPanelDialogTemplate");
    --------------------
    -- Make Draggable --
    --------------------
    dorkGambling:SetMovable(true)
    dorkGambling:EnableMouse(true)
    dorkGambling:RegisterForDrag("LeftButton")
    dorkGambling:SetScript("OnDragStart", dorkGambling.StartMoving)
    dorkGambling:SetScript("OnDragStop", dorkGambling.StopMovingOrSizing)

    dorkGambling:SetSize(200,300);
    dorkGambling:SetPoint("Center", UIParent, "Center");

    dorkGambling.Title:SetFontObject("GameFontHighlight");
    dorkGambling.Title:SetPoint("Left", dorkGamblingTitleBG, "Left", 6, 2);
    dorkGambling.Title:SetText("Dork Gambling");

    ------------------------------
    -- Game Type DropDown menu ---
    ------------------------------
    dorkGambling.gameTypeDropDown = CreateFrame("Frame", "GameTypeDropDown", dorkGambling , "UIDropDownMenuTemplate");
    GameTypeDropDown.displayMode = "Menu";
    UIDropDownMenu_Initialize(dorkGambling.gameTypeDropDown, 
    function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = config.SetGameType;
        for k,v in pairs(core.gameModes) do            
            info.text, info.arg1, info.checked = v.name, k, v.name == core.SelectedGameType
            UIDropDownMenu_AddButton(info)
        end
    end)
    dorkGambling.gameTypeDropDown:SetPoint('CENTER', dorkGamblingDialogBG, "TOP", 0, -20 );
    UIDropDownMenu_SetWidth(dorkGambling.gameTypeDropDown, 150)
    core.SelectedGameType = core.gameModes["Death Roll"].name;
    UIDropDownMenu_SetText(dorkGambling.gameTypeDropDown, core.SelectedGameType)

    ---------------------------
    ---- BUTTONS, MARRAAAZZZ---
    ---------------------------

    dorkGambling.startBtn = self:CreateButton("CENTER", dorkGambling.gameTypeDropDown, "TOP", 50, -50, "Start", 80, 20)
    dorkGambling.startBtn:SetScript("OnClick", core.startGame)

    ---------------------------
    -- Input for bet ammount --
    ---------------------------
    dorkGambling.editbox = CreateFrame("EditBox", nil, dorkGambling, "InputBoxTemplate")
    dorkGambling.editbox:SetMultiLine(false)
    dorkGambling.editbox:SetPoint("CENTER", dorkGamblingDialogBG, "TOP", -40, -53);
    dorkGambling.editbox:SetFontObject("ChatFontNormal")
    dorkGambling.editbox:SetWidth(80)
    dorkGambling.editbox:SetHeight(20)
    dorkGambling.editbox:SetText(1000)
    dorkGambling.editbox:SetAutoFocus(false)
    dorkGambling.editbox:SetNumeric();
    dorkGambling.editbox:SetScript("OnEscapePressed", function() 
        dorkGambling.currentBet = dorkGambling.editbox:GetNumber();    
    end)
    dorkGambling.editbox:SetScript("OnEnterPressed", function()
        dorkGambling.currentBet = dorkGambling.editbox:GetNumber();
    end
    )

    -------------
    -- Divider --
    -------------
    dorkGambling.line = dorkGambling:CreateTexture()
    dorkGambling.line:SetTexture("Interface/BUTTONS/WHITE8X8")
    dorkGambling.line:SetColorTexture(1 ,1, 1, .2)
    dorkGambling.line:SetSize(180, 2)
    dorkGambling.line:SetPoint("CENTER",dorkGamblingDialogBG, "TOP",0,-75)

    

    ------------------
    --- texts --------
    ------------------
    dorkGambling.playerCount = dorkGambling:CreateFontString("Player Count:","dorkGamblingDialogBG");
    dorkGambling.playerCount:SetFontObject("GameFontNormal");
    dorkGambling.playerCount:SetPoint("TOP", dorkGambling.line, "CENTER", 0, -2);
    dorkGambling.playerCount:SetText("Players in game: 0");

    dorkGambling:Hide();
    return dorkGambling
end

function config:updatePlayerCount()
    if core.game.numPlayers ~= nil then
        dorkGambling.playerCount:SetText("Players in game: " .. core.game.numPlayers .. " (max:"..core.game.maxNumPlayers..")");
    end
    if core.game:gameCanStart() then
        dorkGambling.playerCount:SetFontObject("GameFontGreen");
    else
        dorkGambling.playerCount:SetFontObject("GameFontNormal");
    end

end

-- gameType = gameType,
-- gameState = 'WaitingForPlayers',
-- players = {},
-- server = server,
-- maxNumPlayers = gameModes[gameType].maxPlayers,
-- minNumPlayers = gameModes[gameType].minPlayers,
-- numPlayers = 0,
-- currentRoll = 1000,
-- highRoll = 0,
-- highPlayer = nil,
-- highTie = {},
-- lowRoll = 9999999999,
-- lowPlayer = nil,
-- lowTie = {},
-- gameCanStart = function (self)
--   return self.numPlayers >= self.minNumPlayers
-- end,
-- pickRandomPlayer = function (self)
--   if self.numPlayers > 1 then
--     return random_key(self.players).name
--   else
--     return nil
--   end
-- end,
-- allPlayersRolled = function (self)
--   if gameType == 'HighLow' or gameType == 'Bracket' then
--     for k,v in pairs(self.players) do
--       if v.roll == nil then
--         return false
--       end
--     end
--     return true
--   end
--   return nil
-- end