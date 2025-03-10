local cuijue = fk.CreateSkill {
  name = "cuijue"
}

Fk:loadTranslationTable{
  ['cuijue'] = '摧决',
  ['#cuijue'] = '摧决：你可弃置一张牌，然后对攻击范围内距离最远且本回合未指定过的角色造成伤害',
  ['#cuijue-choose'] = '摧决：选择其中一名角色对其造成1点伤害',
  [':cuijue'] = '出牌阶段，你可以弃置一张牌，然后对攻击范围内距离最远且本回合未以此法选择过的一名其他角色造成1点伤害。',
  ['$cuijue1'] = '当锋摧决，贯遐洞坚。',
  ['$cuijue2'] = '殒身不恤，死战成仁。',
}

cuijue:addEffect('active', {
  anim_type = "offensive",
  card_num = 1,
  target_num = 0,
  prompt = "#cuijue",
  can_use = function(self, player)
    return not player:isNude() and player:usedSkillTimes(cuijue.name, Player.HistoryPhase) < 20
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, cuijue.name, player, player)

    local farest = 0
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if player ~= p and player:inMyAttackRange(p) then
        local distance = player:distanceTo(p)
        if distance > farest then
          farest = distance
          targets = { p.id }
        elseif distance == farest then
          table.insert(targets, p.id)
        end
      end
    end

    targets = table.filter(targets, function(pId) return not table.contains(player:getTableMark("cuijue_targeted-turn"), pId) end)

    if #targets == 0 then
      return
    end
    local tos = room:askToChoosePlayers(player, {
      targets = Fk:getPlayerByIds(targets),
      min_num = 1,
      max_num = 1,
      prompt = "#cuijue-choose",
      skill_name = cuijue.name,
      cancelable = false
    })
    room:addTableMarkIfNeed(player, "cuijue_targeted-turn", tos[1].id)
    room:damage{
      from = player,
      to = room:getPlayerById(tos[1].id),
      damage = 1,
      skillName = cuijue.name,
    }
  end,
})

return cuijue
