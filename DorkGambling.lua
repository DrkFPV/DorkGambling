local _, core = ...;

local function random_key(tab)
  local keys = {}
  for k in pairs(tab) do table.insert(keys, k) end
  return tab[keys[math.random(#keys)]]
end


local function getTableSize(t)
  local count = 0
  for _, _ in pairs(t) do
      count = count + 1
  end
  return count
end

local function getOtherPlayer(tab,key)
  for k , _ in pairs(tab) do
    if k ~= key then
      return k
    end
  end
end

local function tableFind(tab,el)
  for index, value in pairs(tab) do
      if value == el then
          return index
      end
  end
end

local function debugPlayersInGame()
  print('Players In Current core.game: ')
  for k, v in pairs(game.players) do
    print(v["name"], v["rolled"])
  end
end

function core:dgMessage(msg, chatType)
  local msg = '[DorkGambling]: '.. msg
  SendChatMessage(msg,chatType)
end

function DebugGame()
  return core
end

local function playerIsInGame(playerName)
  for k in pairs(game.players) do
    if k == playerName then
      return true
    end
  end
  return false
end

local function processRoll(roller, rollResult, rollMin, rollMax)
  if core.game.gameType == 'Death Roll' then
    if roller == core.game.currentPlayer and rollMax == core.game.currentRoll and rollMin == 1 then
      if rollResult == 1 then
        local winner = getOtherPlayer(core.game.players,roller) 
        dgMessage(winner .. " Wins! " .. roller .." pays " .. winner .. " {bet} gold!" , "Party")
        core.game = nil
      else
        core.game.currentPlayer = getOtherPlayer(core.game.players,roller)
        core.game.currentRoll = rollResult
        dgMessage(core.game.currentPlayer .. ' next: (/roll ' .. core.game.currentRoll ..')' ,'Party')
      end
    end

  elseif core.game.gameType == 'High Low' then
    if rollMax == core.game.currentRoll and rollMin == 1 and playerIsInGame(roller) then 
      if core.game.players[roller].roll == nil then
        core.game.players[roller].roll = rollResult
        --Check for highest or lowest rolls.. and ties.. 
        if core.game.highRoll < rollResult then 
          core.game.highRoll = rollResult
          core.game.highPlayer = roller
        elseif core.game.highRoll == rollResult then
          table.insert(core.game.highTie, playerName)
        end

        if core.game.lowRoll > rollResult then
          core.game.lowRoll = rollResult
          core.game.lowPlayer = roller
        elseif core.game.lowRoll == rollResult then
          table.insert(core.game.lowTie, playerName)
        end

        if core.game:allPlayersRolled() then
          core.game.gameStame = 'WaitingForRolls'
          dgMessage('The core.game is over!','Party')
          dgMessage(core.game.lowPlayer .. ' owes ' .. core.game.highPlayer .. ' ' .. (game.highRoll - core.game.lowRoll) .. ' gold!','Party')  
          core.game = {}
        end
      end
    end
  end
end

---@param gameType string game type
---@param bet number the gold bet
function core.newGame(gameType, bet)
  if core.game ~= nil then
    if core.game.gameState ~= nil then
      print('Game In Progress')
      return core.game
    end
  end
  return {
    gameType = core.gameType,
    gameState = 'WaitingForPlayers',
    players = {},
    server = GetRealmName(),
    maxNumPlayers = core.gameModes[gameType].maxPlayers,
    minNumPlayers = core.gameModes[gameType].minPlayers,
    numPlayers = 0,
    currentRoll = bet,
    highRoll = 0,
    highPlayer = nil,
    highTie = {},
    lowRoll = 9999999999,
    lowPlayer = nil,
    lowTie = {},
    gameCanStart = function (self)
      return self.numPlayers >= self.minNumPlayers
    end,
    pickRandomPlayer = function (self)
      if self.numPlayers > 1 then
        return random_key(self.players).name
      else
        return nil
      end
    end,
    allPlayersRolled = function (self)
      if core.gameType == 'High Low' or core.gameType == 'Coin Toss' then
        for k,v in pairs(self.players) do
          if v.roll == nil then
            return false
          end
        end
        return true
      end
      return nil
    end
  }
end

---@param playerName string player name to add
local function addPlayerToGame(playerName)
  if core.game.players[playerName] == nil  then
    core.game.players[playerName] = {rolled = nil, name = playerName}
    core.game.numPlayers = core.game.numPlayers + 1
  end
end

---@param playerName string player name to remove
local function removePlayerFromGame(playerName)
  if core.game.players[playerName] ~= nil then
    core.game.players[playerName] = nil
    core.game.numPlayers = core.game.numPlayers - 1
  end
end

function core:restartGame()
  print('restarting core.game')
  core.game = nil
end

local function dorkGamblingCommands(msg)
  if msg == '' then
    core.config:toggle();
    return
  end
end

function core:init(event, name, ...)
  if name ~= "DorkGambling" then return end;

  SLASH_DORKGAMBLING1, SLASH_DORKGAMBLING2, SLASH_DORKGAMBLING3  = "/dg", "/dork", "/DorkGambling"
  SlashCmdList.DORKGAMBLING = dorkGamblingCommands;
  core.config:toggle();
end

function core:TextEventHandler(event, ...)
  if GetNumGroupMembers() == 0 or core.game == nil then
    return
  elseif event == "CHAT_MSG_SYSTEM" and core.game ~= nil then
    if core.game.state == 'In Progress' then
      local message = ...
      local roller, rollResult, rollMin, rollMax = string.match(message, "(.+) rolls (%d+) %((%d+)-(%d+)%)");
      if roller and rollResult and rollMin and rollMax then 
        processRoll(roller, tonumber(rollResult), tonumber(rollMin), tonumber(rollMax))
      end
    end
  elseif (event == "CHAT_MSG_PARTY" or "CHAT_MSG_PARTY_LEADER") then
    if core.game.state == 'Waiting' then
      local msg, roller = ...
      if msg == '1' then
        addPlayerToGame(string.match(roller, "(%a+)"))
      elseif msg == '-1' then
        removePlayerFromGame(string.match(roller, "(%a+)"))
      end
      core.config:updatePlayerCount()
    end
  end
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.init);
---@class player
---@field public name string @name of the player
---@field public rolled number @what the player rolled


--rolled = nil, name = playerName

---@class testGame
---@field public core.gameType string @this is a test comment
---@field public core.gameState string @this is a test comment
---@field public players table<string,player> array of players

---@type testGame
--local TestGame;