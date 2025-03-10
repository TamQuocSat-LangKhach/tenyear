local jigu = fk.CreateSkill {
  name = "jigu"
}

Fk:loadTranslationTable{
  ['jigu'] = '激鼓',
  ['@@jigu-inhand'] = '激鼓',
  [':jigu'] = '锁定技，游戏开始时，你的初始手牌增加“激鼓”标记且不计入手牌上限。当你造成或受到伤害后，若你于此轮内发动过此技能的次数小于本局游戏已进入回合的角色数，且你装备区里的牌数等于你手牌区里的“激鼓”牌数，你摸X张牌（X为你空置的装备栏数）。',
  ['$jigu1'] = '我接着奏乐，诸公接着舞！',
  ['$jigu2'] = '这不是鼓，而是曹公的脸面。',
}

jigu:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(skill.name) then return false end
    local handcards = player:getCardIds(Player.Hand)
    if #handcards > 0 then
      return true
    end
  end,
  on_use = function(self, event, target, player)
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      Fk:getCardById(id):setMark("@@jigu-inhand", 1)
    end
  end,
})

jigu:addEffect(fk.Damage, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(skill.name) then return false end
    local record = player:getMark("jiguused_record")
    if record == 0 then
      local players = table.map(player.room.players, Util.IdMapper)
      player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
        table.removeOne(players, e.data[1].id)
        return #players == 0
      end, Player.HistoryGame)
      record = #player.room.players - #players
      if #players == 0 then
        player.room:setPlayerMark(player, "jiguused_record", record)
      end
    end
    if player:getMark("jiguused-round") < record then
      local x = #player:getCardIds(Player.Equip)
      if x == #table.filter(handcards, function (id)
        return Fk:getCardById(id):getMark("@@jigu-inhand") > 0
      end) then
        x = #player:getAvailableEquipSlots() - x
        if x > 0 then
          event:setCostData(skill, x)
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:addPlayerMark(player, "jiguused-round")
    player:drawCards(event:getCostData(skill), jigu.name)
  end,
})

jigu:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(skill.name) then return false end
    local record = player:getMark("jiguused_record")
    if record == 0 then
      local players = table.map(player.room.players, Util.IdMapper)
      player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
        table.removeOne(players, e.data[1].id)
        return #players == 0
      end, Player.HistoryGame)
      record = #player.room.players - #players
      if #players == 0 then
        player.room:setPlayerMark(player, "jiguused_record", record)
      end
    end
    if player:getMark("jiguused-round") < record then
      local x = #player:getCardIds(Player.Equip)
      if x == #table.filter(handcards, function (id)
        return Fk:getCardById(id):getMark("@@jigu-inhand") > 0
      end) then
        x = #player:getAvailableEquipSlots() - x
        if x > 0 then
          event:setCostData(skill, x)
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:addPlayerMark(player, "jiguused-round")
    player:drawCards(event:getCostData(skill), jigu.name)
  end,
})

jigu:addEffect('lose', {
  can_trigger = function(self, player)
    return true
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      Fk:getCardById(id):setMark("@@jigu-inhand", 0)
    end
  end,
})

local jigu_maxcards = fk.CreateSkill {
  name = "#jigu_maxcards"
}
jigu_maxcards:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return card:getMark("@@jigu-inhand") > 0
  end,
})
jigu:addRelatedSkill(jigu_maxcards)

return jigu
