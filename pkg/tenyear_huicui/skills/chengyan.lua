local chengyan = fk.CreateSkill {
  name = "chengyan",
}

Fk:loadTranslationTable{
  ["chengyan"] = "乘烟",
  [":chengyan"] = "当你使用【杀】或普通锦囊牌指定其他角色为目标后，你可以摸一张牌并展示之，若为【杀】或普通锦囊牌，"..
  "则改为视为对目标使用展示牌，否则你摸一张牌并标记为“笛”。",

  ["#chengyan-invoke"] = "乘烟：是否摸一张牌？若是【杀】或普通锦囊牌，则将此%arg改为摸到牌的效果",

  ["$chengyan1"] = "素女乘烟去，白玉凤凰声。",
  ["$chengyan2"] = "香魄成飞仙，凤箫月中闻。",
}

chengyan:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengyan.name) and data.firstTarget and
      not table.contains(data.card.skillNames, chengyan.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(data.use.tos, function (p)
        return p ~= player
      end)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chengyan.name,
      prompt = "#chengyan-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(1)
    if #cards == 0 or player.dead or not table.contains(player:getCardIds("h"), cards[1]) then return end
    room:showCards(cards, player)
    if player.dead then return end
    local card = Fk:getCardById(cards[1])
    if (card.trueName == "slash" or card:isCommonTrick()) and not card.is_passive then
      data.use.nullifiedTargets = table.simpleClone(room.players)
      local new_tos = table.simpleClone(data.use.tos)
      table.removeOne(new_tos, player)
      room:sortByAction(new_tos)
      room:useVirtualCard(card.name, nil, player, new_tos, chengyan.name, true)
    elseif not player.dead then
      player:drawCards(1, chengyan.name, nil, player:hasSkill("xidi", true) and "@@xidi-inhand" or nil)
    end
  end,
})

return chengyan
