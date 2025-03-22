local qimei = fk.CreateSkill {
  name = "ty__qimei",
}

Fk:loadTranslationTable{
  ["ty__qimei"] = "齐眉",
  [":ty__qimei"] = "出牌阶段限一次，你可以选择一名其他角色，你与其各摸两张牌并各展示两张手牌，根据展示牌的花色数，你执行以下效果：<br>"..
  "1，你可以依次使用这些牌；<br>2，你与其复原武将牌；<br>3，你与其重铸这些牌；<br>4，你与其各摸一张牌。",

  ["#ty__qimei"] = "齐眉：与一名角色各摸两张牌然后各展示两张牌，根据展示牌花色数执行效果",
  ["#ty__qimei-show"] = "齐眉：请展示两张手牌",
  ["#ty__qimei-use"] = "齐眉：你可以使用这些牌",

  ["$ty__qimei1"] = "此生愿作比翼鸟，双宿双飞不分离。",
  ["$ty__qimei2"] = "与君共度晨昏，此生之所愿。",
}

qimei:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#ty__qimei",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(qimei.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:drawCards(2, qimei.name)
    if not target.dead then
      target:drawCards(2, qimei.name)
    end
    local cards1 = {}
    if not player.dead and not player:isKongcheng() then
      cards1 = room:askToCards(player, {
        min_num = math.min(player:getHandcardNum(), 2),
        max_num = 2,
        include_equip = false,
        skill_name = qimei.name,
        cancelable = false,
        prompt = "#ty__qimei-show",
      })
    end
    local cards2 = {}
    if not target.dead and not target:isKongcheng() then
      cards2 = room:askToCards(target, {
        min_num = math.min(player:getHandcardNum(), 2),
        max_num = 2,
        include_equip = false,
        skill_name = qimei.name,
        cancelable = false,
        prompt = "#ty__qimei-show",
      })
    end
    if #cards1 + #cards2 == 0 then return end
    local suits = {}
    for _, id in ipairs(cards1) do
      if Fk:getCardById(id).suit ~= Card.NoSuit then
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
    end
    for _, id in ipairs(cards2) do
      if Fk:getCardById(id).suit ~= Card.NoSuit then
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
    end
    if #cards1 > 0 then
      player:showCards(cards1)
    end
    cards2 = table.filter(cards2, function (id)
      return table.contains(target:getCardIds("h"), id)
    end)
    if #cards2 > 0 then
      target:showCards(cards2)
    end
    if #suits == 1 then
      while not player.dead do
        cards1 = table.filter(cards1, function(id)
          return table.contains(player:getCardIds("h"), id)
        end)
        cards2 = table.filter(cards2, function(id)
          return table.contains(target:getCardIds("h"), id)
        end)
        if #cards1 + #cards2 == 0 then return end
        local use = room:askToUseRealCard(player, {
          pattern = table.connect(cards1, cards2),
          skill_name = qimei.name,
          prompt = "#ty__qimei-use",
          extra_data = {
            bypass_times = false,
            extraUse = true,
            expand_pile = cards2,
          },
          skip = true
        })
        if use then
          table.removeOne(cards1, use.card:getEffectiveId())
          table.removeOne(cards2, use.card:getEffectiveId())
          room:useCard(use)
        else
          return
        end
      end
    elseif #suits == 2 then
      if not player.dead then
        player:reset()
      end
      if not target.dead then
        target:reset()
      end
    elseif #suits == 3 then
      cards1 = table.filter(cards1, function (id)
        return table.contains(player:getCardIds("h"), id)
      end)
      if #cards1 > 0 and not player.dead then
        room:recastCard(cards1, player, qimei.name)
      end
      cards2 = table.filter(cards2, function (id)
        return table.contains(target:getCardIds("h"), id)
      end)
      if #cards2 > 0 and not target.dead then
        room:recastCard(cards2, target, qimei.name)
      end
    elseif #suits == 4 then
      if not player.dead then
        player:drawCards(1, qimei.name)
      end
      if not target.dead then
        target:drawCards(1, qimei.name)
      end
    end
  end,
})

return qimei
