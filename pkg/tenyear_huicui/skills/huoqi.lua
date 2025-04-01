local huoqi = fk.CreateSkill {
  name = "huoqi",
}

Fk:loadTranslationTable{
  ["huoqi"] = "活气",
  [":huoqi"] = "出牌阶段限一次，你可以弃置一张牌，然后令一名体力最少的角色回复1点体力并摸一张牌。",

  ["#huoqi"] = "活气：弃置一张牌，令一名体力最少的角色回复1点体力并摸一张牌",
}

huoqi:addEffect("active", {
  anim_type = "support",
  prompt = "#huoqi",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(huoqi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return to_select:isWounded() and
      table.every(Fk:currentRoom().alive_players, function(p)
        return to_select.hp <= p.hp
      end)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, huoqi.name, player, player)
    if target:isWounded() and not target.dead then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = huoqi.name,
      }
    end
    if not target.dead then
      target:drawCards(1, huoqi.name)
    end
  end,
})

return huoqi
