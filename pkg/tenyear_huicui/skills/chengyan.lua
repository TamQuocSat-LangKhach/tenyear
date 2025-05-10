local chengyan = fk.CreateSkill {
  name = "chengyan",
}

Fk:loadTranslationTable{
  ["chengyan"] = "乘烟",
  [":chengyan"] = "当你使用【杀】或普通锦囊牌指定其他角色为目标后，你可以摸一张牌并展示之，若为【杀】或普通锦囊牌，"..
  "则对目标其他角色中是展示牌牌名合法目标的角色无效，改为视为对这些角色使用一张此牌名的牌；若不为【杀】或普通锦囊牌，你摸一张牌并标记为“笛”。",

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
    local card = Fk:cloneCard(Fk:getCardById(cards[1]).trueName)
    card.skillName = chengyan.name
    if card.name == "slash" or card:isCommonTrick() then
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      local new_tos = {}
      for _, p in ipairs(data.use.tos) do
        if p ~= player and player:canUseTo(card, p, {bypass_distances = true, bypass_times = true}) then
          table.insert(new_tos, p)
          table.insert(data.use.nullifiedTargets, p)
        end
      end
      if #new_tos > 0 then
        room:sortByAction(new_tos)
        room:useVirtualCard(card.name, nil, player, new_tos, chengyan.name, true)
      end
    elseif not player.dead then
      player:drawCards(1, chengyan.name, nil, player:hasSkill("xidi", true) and "@@xidi-inhand" or nil)
    end
  end,
})

return chengyan
