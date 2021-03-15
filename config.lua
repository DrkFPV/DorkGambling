local _, core = ...;
core.Config = {};

local Config = core.Config;
local DorkGambling;
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

function Config:Toggle()
    local menu = DorkGambling or Config:CreateMenu();
    menu:SetShown(not menu:IsShown())
end

function Config:RegisterTextEvents()
    DorkGambling:RegisterEvent("CHAT_MSG_SYSTEM");
    DorkGambling:RegisterEvent("CHAT_MSG_PARTY");
    DorkGambling:RegisterEvent("CHAT_MSG_PARTY_LEADER");
    DorkGambling:SetScript("OnEvent", core.TextEventHandler)
end

function Config:UnregisterTextEvents()
end


function Config:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text, xSize, ySize)
    local btn = CreateFrame("Button", nil, DorkGambling, "GameMenuButtonTemplate");
    btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
    btn:SetSize(xSize,ySize);
    btn:SetText(text);
    btn:SetNormalFontObject("GameFontNormalLarge");
    btn:SetHighlightFontObject("GameFontHighlightLarge");
    return btn;
end

function Config:SetGameType(newValue)
    core.SelectedGameType = core.gameModes[newValue].name;
    UIDropDownMenu_SetText(DorkGambling.gameTypeDropDown, core.SelectedGameType);
    print(core.SelectedGameType)
    CloseDropDownMenus();
end

function core:StartGame()
    core.game = core.game or core.newGame(core.SelectedGameType, core.currentBet)
    if core.game.state == nil then
        DorkGambling.startBtn:SetText('Start Roll');
        Config:RegisterTextEvents();
        core.game.state = 'Waiting';
    elseif (core.game.state == 'Waiting') then
        DorkGambling.startBtn:SetText('In Progress');
        core.game.state = 'In Progress'
    end
end

function Config:CreateMenu()
    DorkGambling = CreateFrame("FRAME", "DorkGambling", UIParent, "UIPanelDialogTemplate");
    --------------------
    -- Make Draggable --
    --------------------
    DorkGambling:SetMovable(true)
    DorkGambling:EnableMouse(true)
    DorkGambling:RegisterForDrag("LeftButton")
    DorkGambling:SetScript("OnDragStart", DorkGambling.StartMoving)
    DorkGambling:SetScript("OnDragStop", DorkGambling.StopMovingOrSizing)

    DorkGambling:SetSize(200,300);
    DorkGambling:SetPoint("Center", UIParent, "Center");

    DorkGambling.Title:SetFontObject("GameFontHighlight");
    DorkGambling.Title:SetPoint("Left", DorkGamblingTitleBG, "Left", 6, 2);
    DorkGambling.Title:SetText("Dork Gambling");

    ------------------------------
    -- Game Type DropDown menu ---
    ------------------------------
    DorkGambling.gameTypeDropDown = CreateFrame("Frame", "GameTypeDropDown", DorkGambling , "UIDropDownMenuTemplate");
    GameTypeDropDown.displayMode = "Menu";
    UIDropDownMenu_Initialize(DorkGambling.gameTypeDropDown, 
    function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = Config.SetGameType;
        for k,v in pairs(core.gameModes) do            
            info.text, info.arg1, info.checked = v.name, k, v.name == core.SelectedGameType
            UIDropDownMenu_AddButton(info)
        end
    end)
    DorkGambling.gameTypeDropDown:SetPoint('CENTER', DorkGamblingDialogBG, "TOP", 0, -20 );
    UIDropDownMenu_SetWidth(DorkGambling.gameTypeDropDown, 150)
    core.SelectedGameType = core.gameModes["Death Roll"].name;
    UIDropDownMenu_SetText(DorkGambling.gameTypeDropDown, core.SelectedGameType)

    ---------------------------
    ---- BUTTONS, MARRAAAZZZ---
    ---------------------------

    DorkGambling.startBtn = self:CreateButton("CENTER", DorkGambling.gameTypeDropDown, "TOP", 50, -50, "Start", 80, 20)
    DorkGambling.startBtn:SetScript("OnClick", core.StartGame)

    ---------------------------
    -- Input for bet ammount --
    ---------------------------
    DorkGambling.editbox = CreateFrame("EditBox", nil, DorkGambling, "InputBoxTemplate")
    DorkGambling.editbox:SetMultiLine(false)
    DorkGambling.editbox:SetPoint("CENTER", DorkGamblingDialogBG, "TOP", -40, -53);
    DorkGambling.editbox:SetFontObject("ChatFontNormal")
    DorkGambling.editbox:SetWidth(80)
    DorkGambling.editbox:SetHeight(20)
    DorkGambling.editbox:SetText(1000)
    DorkGambling.editbox:SetAutoFocus(false)
    DorkGambling.editbox:SetNumeric();
    DorkGambling.editbox:SetScript("OnEscapePressed", function() 
        DorkGambling.currentBet = DorkGambling.editbox:GetNumber();    
    end)
    DorkGambling.editbox:SetScript("OnEnterPressed", function()
        DorkGambling.currentBet = DorkGambling.editbox:GetNumber();
    end
    )

    -------------
    -- Divider --
    -------------
    DorkGambling.line = DorkGambling:CreateTexture()
    DorkGambling.line:SetTexture("Interface/BUTTONS/WHITE8X8")
    DorkGambling.line:SetColorTexture(1 ,1, 1, .2)
    DorkGambling.line:SetSize(180, 2)
    DorkGambling.line:SetPoint("CENTER",DorkGamblingDialogBG, "TOP",0,-75)

    

    ------------------
    --- texts --------
    ------------------
    DorkGambling.playerCount = DorkGambling:CreateFontString("Player Count:","DorkGamblingDialogBG");
    DorkGambling.playerCount:SetFontObject("GameFontNormal");
    DorkGambling.playerCount:SetPoint("TOP", DorkGambling.line, "CENTER", 0, -2);
    DorkGambling.playerCount:SetText("Players in game: 0");

    DorkGambling:Hide();
    return DorkGambling
end

---@param playerCount number
function Config:UpdatePlayerCount()
    if core.game.numPlayers ~= nil then
        DorkGambling.playerCount:SetText("Players in game: " .. core.game.numPlayers .. " (max:"..core.game.maxNumPlayers..")");
    end
    if core.game:gameCanStart() then
        DorkGambling.playerCount:SetFontObject("GameFontGreen");
    else
        DorkGambling.playerCount:SetFontObject("GameFontNormal");
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