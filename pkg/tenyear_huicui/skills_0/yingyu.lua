local yingyu = fk.CreateSkill {
  name = "yingyu"
}

Fk:loadTranslationTable{
  ['yingyu'] = '媵予',
  ['yongbi'] = '拥嬖',
  ['#yingyu-choose'] = '媵予：你可以展示两名角色各一张手牌，若花色不同，选择其中一名角色获得另一名角色的展示牌',
  ['#yingyu2-choose'] = '媵予：选择一名角色，其获得另一名角色的展示牌',
  [':yingyu'] = '准备阶段，你可以展示两名角色的各一张手牌，若花色不同，则你选择其中的一名角色获得另一名角色的展示牌。',
  ['$yingyu1'] = '妾身蒲柳，幸蒙将军不弃。',
  ['$yingyu2'] = '妾之所有，愿尽予君。',
}

yingyu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingyu.name) and
      (player.phase == Player.Start or (player.phase == Player.Finish and player:usedSkillTimes("yongbi", Player.HistoryGame) > 0))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isKongcheng() end), Util.IdMapper)
    if #targets < 2 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 2,
      max_num = 2,
      prompt = "#yingyu-choose",
      skill_name = yingyu.name,
      cancelable = true
    })
    if #tos == 2 then
      event:setCostData(self, tos)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    local target1 = room:getPlayerById(cost_data[1])
    local target2 = room:getPlayerById(cost_data[2])
    room:doIndicate(player.id, {cost_data[1]})
    local id1 = room:askToChooseCard(player, {
      target = target1,
      flag = "h",
      skill_name = yingyu.name
    })
    room:doIndicate(player.id, {cost_data[2]})
    local id2 = room:askToChooseCard(player, {
      target = target2,
      flag = "h",
      skill_name = yingyu.name
    })
    target1:showCards(id1)
    target2:showCards(id2)
    if Fk:getCardById(id1).suit ~= Fk:getCardById(id2).suit and
      Fk:getCardById(id1).suit ~= Card.NoSuit and Fk:getCardById(id2).suit ~= Card.NoSuit then
      local to = room:askToChoosePlayers(player, {
        targets = cost_data,
        min_num = 1,
        max_num = 1,
        prompt = "#yingyu2-choose",
        skill_name = yingyu.name,
        cancelable = false
      })
      if #to > 0 then
        to = to[1]
      else
        to = table.random(cost_data)
      end
      if to == target1.id then
        room:obtainCard(cost_data[1], id2, true, fk.ReasonPrey)
      else
        room:obtainCard(cost_data[2], id1, true, fk.ReasonPrey)
      end
    end
  end,
})

return yingyu
