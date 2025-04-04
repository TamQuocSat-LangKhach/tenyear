local yingshui = fk.CreateSkill {
  name = "yingshui",
}

Fk:loadTranslationTable{
  ["yingshui"] = "营说",
  [":yingshui"] = "出牌阶段限一次，你可以将一张牌交给你攻击范围内的一名角色，其选择：1.你对其造成1点伤害；2.将至少两张装备牌交给你。",

  ["#yingshui"] = "营说：交给一名角色一张牌，其选择交给你两张装备牌或你对其造成伤害",
  ["#yingshui-give"] = "营说：你需交给 %src 至少两张装备牌，否则其对你造成1点伤害",

  ["$yingshui1"] = "道之以德，齐之以礼。",
  ["$yingshui2"] = "施恩行惠，赡之以义。",
}

yingshui:addEffect("active", {
  anim_type = "offensive",
  prompt = "#yingshui",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yingshui.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and player:inMyAttackRange(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, yingshui.name, nil, false, player)
    if target.dead then return end
    if player.dead or #target:getCardIds("he") < 2 then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = yingshui.name,
      }
    else
      local cards = room:askToCards(target, {
        min_num = 2,
        max_num = 999,
        include_equip = true,
        pattern = ".|.|.|.|.|equip",
        prompt = "#yingshui-give:"..player.id,
        skill_name = yingshui.name,
      })
      if #cards > 1 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, yingshui.name, nil, true, target)
      else
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = yingshui.name,
        }
      end
    end
  end,
})

return yingshui
