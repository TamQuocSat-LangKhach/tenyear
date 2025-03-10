local zhuiji = fk.CreateSkill {
  name = "ty__zhuiji",
}

Fk:loadTranslationTable{
  ['ty__zhuiji'] = '追击',
  [':ty__zhuiji'] = '锁定技，你对其他角色使用牌结算后，本回合你计算与其距离视为1。',
}

zhuiji:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.tos and
      table.find(TargetGroup:getRealTargets(data.tos), function (id)
        return id ~= player.id and not table.contains(player:getTableMark("ty__zhuiji-turn"), id) and
          not player.room:getPlayerById(id).dead
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      if id ~= player.id and not room:getPlayerById(id).dead then
        room:addTableMark(player, "ty__zhuiji-turn", id)
      end
    end
  end,
})

zhuiji:addEffect('distance', {
  name = "#ty__zhuiji_distance",
  fixed_func = function(self, from, to)
    if table.contains(from:getTableMark("ty__zhuiji-turn"), to.id) then
      return 1
    end
  end,
})

return zhuiji
