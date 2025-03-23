local xiongsuan = fk.CreateSkill {
  name = "ty__xiongsuan"
}

Fk:loadTranslationTable{
  ['ty__xiongsuan'] = '凶算',
  ['#ty__xiongsuan'] = '凶算:弃一张手牌并对一名角色造成1点伤害，你摸三张牌，若不为你，你失去体力',
  [':ty__xiongsuan'] = '出牌阶段限一次，你可以弃置一张手牌并对一名角色造成1点伤害，然后摸三张牌。若该角色不为你，你失去1点体力。',
  ['$ty__xiongsuan1'] = '此战虽凶，得益颇高。',
  ['$ty__xiongsuan2'] = '谋算计策，吾二人尚有险招。',
}

xiongsuan:addEffect('active', {
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  prompt = "#ty__xiongsuan",
  can_use = function(self, player)
    return player:usedSkillTimes(xiongsuan.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (skill, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCards("H"), to_select)
      and not skill:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and #cards == 1
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke("xiongsuan")
    local discards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = xiongsuan.name
    })
    if #discards > 0 then
      room:damage { from = player, to = room:getPlayerById(effect.tos[1]), damage = 1, skillName = xiongsuan.name }
      player:drawCards(3, xiongsuan.name)
      if not player.dead and effect.from ~= effect.tos[1] then
        room:loseHp(player, 1, xiongsuan.name)
      end
    end
  end,
})

return xiongsuan
