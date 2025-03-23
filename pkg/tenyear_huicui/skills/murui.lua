local murui = fk.CreateSkill {
  name = "murui"
}

Fk:loadTranslationTable{
  ['murui'] = '暮锐',
  ['@murui'] = '暮锐',
  ['#murui-use'] = '暮锐：你可以使用一张牌，若造成伤害则摸两张牌并删除此时机',
  ['aoren'] = '鏖刃',
  [':murui'] = '你可以于以下时机使用一张牌：1.每轮开始时；2.有角色死亡的回合结束时；3.你的回合开始时。若此牌造成了伤害，则你摸两张牌并删除对应选项。',
  ['$murui1'] = '背水一战，将至绝地而何畏死。',
  ['$murui2'] = '破釜沉舟，置之死地而后生。',
}

-- RoundStart event
murui:addEffect(fk.RoundStart, {
  can_trigger = function(self, player)
    return player:hasSkill(murui) and player:getMark("@murui")[1] == 1
  end,
  on_cost = function (self, player, event)
    local room = player.room
    local use = room:askToUseCard(player, {
      skill_name = murui.name,
      pattern = nil,
      prompt = "#murui-use",
      extra_data = {
        bypass_times = true,
        extra_use = true
      },
      cancelable = false
    })
    if use then
      event:setCostData(self, use)
      return true
    end
  end,
  on_use = function (self, player, event)
    local room = player.room
    local use = table.simpleClone(event:getCostData(self))
    room:useCard(use)
    if use and use.damageDealt and not player.dead then
      local mark = player:getMark("@murui")
      mark[1] = "<font color='grey'>-</font>"
      room:setPlayerMark(player, "@murui", mark)
      room:addPlayerMark(player, "aoren", 1)
      player:drawCards(2, murui.name)
    end
  end,
})

-- TurnEnd event
murui:addEffect(fk.TurnEnd, {
  can_trigger = function(self, player)
    if not player:getMark("@murui")[2] == 1 then return false end
    local room = player.room
    return #room.logic:getEventsOfScope(GameEvent.Death, 1, Util.TrueFunc, Player.HistoryTurn) > 0
  end,
  on_cost = function (self, player, event)
    local room = player.room
    local use = room:askToUseCard(player, {
      skill_name = murui.name,
      pattern = nil,
      prompt = "#murui-use",
      extra_data = {
        bypass_times = true,
        extra_use = true
      },
      cancelable = false
    })
    if use then
      event:setCostData(self, use)
      return true
    end
  end,
  on_use = function (self, player, event)
    local room = player.room
    local use = table.simpleClone(event:getCostData(self))
    room:useCard(use)
    if use and use.damageDealt and not player.dead then
      local mark = player:getMark("@murui")
      mark[2] = "<font color='grey'>-</font>"
      room:setPlayerMark(player, "@murui", mark)
      room:addPlayerMark(player, "aoren", 1)
      player:drawCards(2, murui.name)
    end
  end,
})

-- TurnStart event
murui:addEffect(fk.TurnStart, {
  can_trigger = function(self, player, target)
    return target == player and player:getMark("@murui")[3] == 1
  end,
  on_cost = function (self, player, event)
    local room = player.room
    local use = room:askToUseCard(player, {
      skill_name = murui.name,
      pattern = nil,
      prompt = "#murui-use",
      extra_data = {
        bypass_times = true,
        extra_use = true
      },
      cancelable = false
    })
    if use then
      event:setCostData(self, use)
      return true
    end
  end,
  on_use = function (self, player, event)
    local room = player.room
    local use = table.simpleClone(event:getCostData(self))
    room:useCard(use)
    if use and use.damageDealt and not player.dead then
      local mark = player:getMark("@murui")
      mark[3] = "<font color='grey'>-</font>"
      room:setPlayerMark(player, "@murui", mark)
      room:addPlayerMark(player, "aoren", 1)
      player:drawCards(2, murui.name)
    end
  end,
})

murui.on_acquire = function (self, player, is_start)
  player.room:setPlayerMark(player, "@murui", {1, 1, 1})
end

murui.on_lose = function (self, player, is_start)
  player.room:setPlayerMark(player, "@murui", 0)
end

return murui
