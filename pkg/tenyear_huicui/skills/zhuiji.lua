local zhuiji = fk.CreateSkill {
  name = "ty__zhuiji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__zhuiji"] = "追击",

  [":ty__zhuiji"] = "锁定技，你对其他角色使用牌结算后，本回合你计算与其距离视为1。",
}

zhuiji:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuiji.name) and
      table.find(data.tos, function (p)
        return p ~= player and not table.contains(player:getTableMark("ty__zhuiji-turn"), p.id) and not p.dead
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(data.tos) do
      if p ~= player and not p.dead then
        room:addTableMark(player, "ty__zhuiji-turn", p.id)
      end
    end
  end,
})

zhuiji:addEffect("distance", {
  fixed_func = function(self, from, to)
    if table.contains(from:getTableMark("ty__zhuiji-turn"), to.id) then
      return 1
    end
  end,
})

return zhuiji
