local xiongsuan = fk.CreateSkill {
  name = "ty__xiongsuan",
}

Fk:loadTranslationTable{
  ["ty__xiongsuan"] = "凶算",
  [":ty__xiongsuan"] = "出牌阶段限一次，你可以弃置一张手牌并对一名角色造成1点伤害，然后摸三张牌。若该角色不为你，你失去1点体力。",

  ["#ty__xiongsuan"] = "凶算：弃一张手牌并对一名角色造成1点伤害，你摸三张牌，若不为你，你失去1点体力",

  ["$ty__xiongsuan1"] = "此战虽凶，得益颇高。",
  ["$ty__xiongsuan2"] = "谋算计策，吾二人尚有险招。",
}

xiongsuan:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty__xiongsuan",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xiongsuan.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (skill, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
      and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, xiongsuan.name, player, player)
    if not target.dead then
      room:damage {
        from = player,
        to = target,
        damage = 1,
        skillName = xiongsuan.name,
      }
    end
    if not player.dead then
      player:drawCards(3, xiongsuan.name)
    end
    if not player.dead and target ~= player then
      room:loseHp(player, 1, xiongsuan.name)
    end
  end,
})

return xiongsuan
