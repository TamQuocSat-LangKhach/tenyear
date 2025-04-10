local cuijue = fk.CreateSkill {
  name = "cuijue",
}

Fk:loadTranslationTable{
  ["cuijue"] = "摧决",
  [":cuijue"] = "出牌阶段，你可以弃置一张牌，然后对攻击范围内距离最远且本回合未以此法选择过的一名其他角色造成1点伤害。",

  ["#cuijue"] = "摧决：弃置一张牌，然后对攻击范围内距离最远且本回合未指定过的角色造成伤害",
  ["#cuijue-choose"] = "摧决：选择其中一名角色对其造成1点伤害",

  ["$cuijue1"] = "当锋摧决，贯遐洞坚。",
  ["$cuijue2"] = "殒身不恤，死战成仁。",
}

cuijue:addEffect("active", {
  anim_type = "offensive",
  prompt = "#cuijue",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude() and player:usedSkillTimes(cuijue.name, Player.HistoryPhase) < 20
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, cuijue.name, player, player)
    if player.dead then return end
    local targets = table.filter(room.alive_players, function (p)
      return player:inMyAttackRange(p) and table.every(room.alive_players, function (q)
        return player:inMyAttackRange(q) and player:distanceTo(p) >= player:distanceTo(q)
      end)
    end)
    targets = table.filter(targets, function (p)
      return not table.contains(player:getTableMark("cuijue-turn"), p.id)
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#cuijue-choose",
      skill_name = cuijue.name,
      cancelable = false,
    })[1]
    room:addTableMarkIfNeed(player, "cuijue-turn", to.id)
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = cuijue.name,
    }
  end,
})

cuijue:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "cuijue-turn", 0)
end)

return cuijue
