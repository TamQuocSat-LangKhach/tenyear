local yingyu = fk.CreateSkill {
  name = "yingyu",
}

Fk:loadTranslationTable{
  ["yingyu"] = "媵予",
  [":yingyu"] = "准备阶段，你可以展示两名角色的各一张手牌，若花色不同，则你选择其中一名角色获得另一名角色的展示牌。",

  ["#yingyu-choose"] = "媵予：你可以展示两名角色各一张手牌，若花色不同，选择其中一名角色获得另一名角色的展示牌",
  ["#yingyu2-choose"] = "媵予：选择一名角色，其获得另一名角色的展示牌",

  ["$yingyu1"] = "妾身蒲柳，幸蒙将军不弃。",
  ["$yingyu2"] = "妾之所有，愿尽予君。",
}

yingyu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingyu.name) and
      (player.phase == Player.Start or
      (player.phase == Player.Finish and player:usedSkillTimes("yongbi", Player.HistoryGame) > 0)) and
      #table.filter(player.room.alive_players, function(p)
        return not p:isKongcheng()
      end) >= 2
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:isKongcheng()
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 2,
      max_num = 2,
      prompt = "#yingyu-choose",
      skill_name = yingyu.name,
      cancelable = true,
    })
    if #tos == 2 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    local id1 = room:askToChooseCard(player, {
      target = targets[1],
      flag = "h",
      skill_name = yingyu.name
    })
    local id2 = room:askToChooseCard(player, {
      target = targets[2],
      flag = "h",
      skill_name = yingyu.name
    })
    targets[1]:showCards(id1)
    if table.contains(targets[2]:getCardIds("h"), id2) then
      targets[2]:showCards(id2)
    end
    if Fk:getCardById(id1):compareSuitWith(Fk:getCardById(id2), true) then
      if player.dead or targets[1].dead or targets[2].dead then return end
      local tos = {}
      if table.contains(targets[1]:getCardIds("h"), id1) then
        table.insert(tos, targets[2])
      end
      if table.contains(targets[2]:getCardIds("h"), id2) then
        table.insert(tos, targets[1])
      end
      if #tos == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        prompt = "#yingyu2-choose",
        skill_name = yingyu.name,
        cancelable = false,
      })[1]
      if to == targets[1] then
        room:obtainCard(to, id2, true, fk.ReasonPrey, to, yingyu.name)
      else
        room:obtainCard(to, id1, true, fk.ReasonPrey, to, yingyu.name)
      end
    end
  end,
})

return yingyu
