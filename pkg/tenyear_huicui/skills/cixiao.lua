local cixiao = fk.CreateSkill {
  name = "cixiao",
}

Fk:loadTranslationTable{
  ["cixiao"] = "慈孝",
  [":cixiao"] = "准备阶段，若场上没有“义子”，你可以令一名其他角色获得一个“义子”标记；若场上有“义子”标记，你可以弃置一张牌移动“义子”标记。"..
  "拥有“义子”标记的角色获得技能〖叛弑〗。",

  ["#cixiao-choose"] = "慈孝：你可以选择一名其他角色成为“义子”",
  ["#cixiao-discard"] = "慈孝：你可以弃置一张牌，转移“义子”标记",
  ["@@panshi_son"] = "义子",

  ["$cixiao1"] = "吾儿奉先，天下无敌！",
  ["$cixiao2"] = "父慈子孝，义理为先！"
}

cixiao:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cixiao.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:getMark("@@panshi_son") == 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local son = table.find(room.alive_players, function (p)
      return p:getMark("@@panshi_son") > 0
    end)
    if son then
      local to, cards = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 1,
        min_num = 1,
        max_num = 1,
        targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return p:getMark("@@panshi_son") == 0
        end),
        skill_name = cixiao.name,
        prompt = "#cixiao-discard",
        cancelable = true,
        will_throw = true,
      })
      if #to > 0 and #cards > 0 then
        event:setCostData(self, {tos = to, cards = cards })
        return true
      end
    else
      local to = room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#cixiao-choose",
        skill_name = cixiao.name,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    local to = event:getCostData(self).tos[1]
    if event:getCostData(self).cards then
      room:throwCard(cost_data.cards, cixiao.name, player, player)
    end
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@@panshi_son", 0)
      room:handleAddLoseSkills(p, "-panshi")
    end
    if not to.dead then
      room:setPlayerMark(to, "@@panshi_son", 1)
      room:handleAddLoseSkills(to, "panshi")
    end
  end,
})

return cixiao
