local qinqing = fk.CreateSkill {
  name = "ty__qinqing",
}

Fk:loadTranslationTable{
  ["ty__qinqing"] = "寝情",
  [":ty__qinqing"] = "结束阶段，你可以弃置攻击范围内含有一号位的一名其他角色的一张牌，然后若其手牌数比一号位多，你摸一张牌。",

  ["#ty__qinqing-choose"] = "寝情：弃置一名角色一张牌，然后若其手牌数多于 %dest，你摸一张牌",

  ["$ty__qinqing1"] = "陛下今日不理朝政，退下吧！",
  ["$ty__qinqing2"] = "此事咱家自会传达陛下。",
}

qinqing:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qinqing.name) and player.phase == Player.Finish and
      table.find(player.room.alive_players, function(p)
        return p:inMyAttackRange(player.room:getPlayerBySeat(1))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:inMyAttackRange(room:getPlayerBySeat(1))
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__qinqing-choose::"..room:getPlayerBySeat(1).id,
      skill_name = qinqing.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = qinqing.name,
    })
    room:throwCard(id, qinqing.name, to, player)
    if player.dead or to.dead then return end
    if to:getHandcardNum() > room:getPlayerBySeat(1):getHandcardNum() then
      player:drawCards(1, qinqing.name)
    end
  end,
})

return qinqing
