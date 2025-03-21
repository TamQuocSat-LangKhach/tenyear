local ty__qinqing = fk.CreateSkill {
  name = "ty__qinqing"
}

Fk:loadTranslationTable{
  ['ty__qinqing'] = '寝情',
  ['#ty__qinqing-choose'] = '寝情：弃置一名角色一张牌，然后若其手牌数多于一号位，你摸一张牌',
  [':ty__qinqing'] = '结束阶段，你可以弃置攻击范围内含有一号位的一名其他角色的一张牌，然后若其手牌数比一号位多，你摸一张张牌。',
  ['$ty__qinqing1'] = '陛下今日不理朝政，退下吧！',
  ['$ty__qinqing2'] = '此事咱家自会传达陛下。',
}

ty__qinqing:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Finish and player:hasSkill(ty__qinqing.name) then
      local lord = player.room:getPlayerBySeat(1)
      return lord and not lord.dead and table.find(player.room.alive_players, function(p) return p:inMyAttackRange(lord) end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local lord =  player.room:getPlayerBySeat(1)
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:inMyAttackRange(lord) and not p:isNude() end), Util.IdMapper)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__qinqing-choose",
      skill_name = ty__qinqing.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local cid = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = ty__qinqing.name
    })
    room:throwCard({cid}, ty__qinqing.name, to, player)
    local lord = player.room:getPlayerBySeat(1)
    if player.dead or to.dead or lord.dead then return end
    if to:getHandcardNum() > lord:getHandcardNum() then
      player:drawCards(1, ty__qinqing.name)
    end
  end,
})

return ty__qinqing
