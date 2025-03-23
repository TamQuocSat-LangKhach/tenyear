local huoqi = fk.CreateSkill {
  name = "huoqi"
}

Fk:loadTranslationTable{
  ['huoqi'] = '活气',
  ['#huoqi'] = '活气：弃置一张牌，令一名体力最少的角色回复1点体力并摸一张牌',
  [':huoqi'] = '出牌阶段限一次，你可以弃置一张牌，然后令一名体力最少的角色回复1点体力并摸一张牌。',
}

huoqi:addEffect('active', {
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#huoqi",
  can_use = function(self, player)
    return player:usedSkillTimes(huoqi.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return target:isWounded() and table.every(Fk:currentRoom().alive_players, function(p) return target.hp <= p.hp end)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, huoqi.name, player, player)
    if target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = huoqi.name
      })
    end
    if not target.dead then
      target:drawCards(1, huoqi.name)
    end
  end,
})

return huoqi
