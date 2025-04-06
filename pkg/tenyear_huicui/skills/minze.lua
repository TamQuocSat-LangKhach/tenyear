local minze = fk.CreateSkill {
  name = "minze",
}

Fk:loadTranslationTable{
  ["minze"] = "悯泽",
  [":minze"] = "出牌阶段每名角色限一次，你可以将至多两张牌名不同的牌交给一名手牌数小于你的角色。结束阶段，你将手牌补至X张"..
  "（X为本回合你因此技能失去牌的牌名数，至多为5）。",

  ["#minze"] = "悯泽：交给一名角色至多两张不同牌名的牌，结束阶段你将手牌补至交出的牌名数",

  ["$minze1"] = "百姓千载皆苦，勿以苛政待之。",
  ["$minze2"] = "黎庶待哺，人主当施恩德泽。",
}

minze:addEffect("active", {
  anim_type = "support",
  prompt = "#minze",
  min_card_num = 1,
  max_card_num = 2,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:getCardById(to_select).trueName ~= Fk:getCardById(selected[1]).trueName
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and player:getHandcardNum() > to_select:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    for _, id in ipairs(effect.cards) do
      room:addTableMarkIfNeed(player, "minze-turn", Fk:getCardById(id).trueName)
    end
    room:obtainCard(target, effect.cards, false, fk.ReasonGive, player, minze.name)
  end,
})

minze:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and
      player:getHandcardNum() < math.min(#player:getTableMark("minze-turn"), 5)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.min(#player:getTableMark("minze-turn"), 5) - player:getHandcardNum(), minze.name)
  end,
})

return minze
