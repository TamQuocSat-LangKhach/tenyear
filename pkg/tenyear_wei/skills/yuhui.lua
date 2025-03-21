local yuhui = fk.CreateSkill {
  name = "yuhui",
}

Fk:loadTranslationTable{
  ["yuhui"] = "御麾",
  [":yuhui"] = "结束阶段，你可以选择一名吴势力的其他角色，其出牌阶段开始时可以交给你一张红色基本牌并发动一次X为1的〖斡衡〗。",

  ["#yuhui-choose"] = "御麾：选择任意名吴势力角色，其出牌阶段开始时可以交给你一张牌发动“斡衡”",
  ["#yuhui-active"] = "御麾：是否交给 %src 一张红色基本牌，令一名角色摸或弃一张牌？",

  ["$yuhui1"] = "惠用张仪，昭得范雎，朕拥卿足矣！",
  ["$yuhui2"] = "南靖交越，北复荆襄，使吴成帝业。",
}

yuhui:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(yuhui.name) and player.phase == Player.Finish and
      table.find(player.room.alive_players, function (p)
        return p ~= player and p.kingdom == "wu"
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p ~= player and p.kingdom == "wu"
    end)
    local tos = room:askToChoosePlayers(player, {
      skill_name = yuhui.name,
      min_num = 1,
      max_num = 9,
      targets = targets,
      prompt = "#yuhui-choose",
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local tos = event:getCostData(self).tos
    player.room:setPlayerMark(player, yuhui.name, table.map(tos, Util.IdMapper))
  end,

  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark(yuhui.name) ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, yuhui.name, 0)
  end,
})

yuhui:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target.phase == Player.Play and table.contains(player:getTableMark(yuhui.name), target.id) and
      not target.dead and not player.dead and not target:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      pattern = ".|.|heart,diamond|.|.|basic",
      prompt = "#yuhui-active:"..player.id,
      skill_name = yuhui.name,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, player, fk.ReasonGive, yuhui.name, nil, false, target)
    if target.dead then return end
    local success, dat = room:askToUseActiveSkill(target, {
      skill_name = "woheng",
      prompt = "#woheng:::1",
      cancelable = true,
      no_indicate = false,
      skip = true,
    })
    if success and dat then
      local to = dat.targets[1]
      if dat.interaction == "woheng_draw" then
        to:drawCards(1, "woheng")
      else
        room:askToDiscard(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = "woheng",
          cancelable = false,
        })
      end
      if target.dead then return end
      if to:getHandcardNum() ~= target:getHandcardNum() then
        target:drawCards(2, "woheng")
      end
    end
  end,
})

return yuhui
