local benshi = fk.CreateSkill {
  name = "benshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["benshi"] = "奔矢",
  [":benshi"] = "锁定技，你使用【杀】须指定攻击范围内所有角色为目标。你的攻击范围+1。",

  ["$benshi1"] = "今，或为鱼肉，或为刀俎。",
  ["$benshi2"] = "所征徭者必死，可先斩之。",
}

benshi:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(benshi.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if player:inMyAttackRange(p) and not table.contains(data.tos, p) and not player:isProhibited(p, data.card) then
        room:doIndicate(player, {p})
        data:addTarget(p)
      end
    end
  end,
})

benshi:addEffect("atkrange", {
  correct_func = function(self, from, to)
    return from:hasSkill(benshi.name) and 1 or 0
  end,
})

return benshi
