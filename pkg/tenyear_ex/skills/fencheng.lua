local fencheng = fk.CreateSkill {
  name = "ty_ex__fencheng",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ty_ex__fencheng"] = "焚城",
  [":ty_ex__fencheng"] = "限定技，出牌阶段，你可以选择一名角色，从该角色开始，所有其他角色依次选择一项：1.弃置至少X张牌"..
  "（X为上一名角色因此弃置的牌数+1）；2.你对其造成2点火焰伤害。",

  ["#ty_ex__fencheng"] = "焚城：选择一名角色，从该角色开始结算“焚城”！",
  ["#ty_ex__fencheng-discard"] = "焚城：弃置至少%arg张牌，否则受到2点火焰伤害",

  ["$ty_ex__fencheng1"] = "堆薪聚垛，以燃焚天之焰！",
  ["$ty_ex__fencheng2"] = "就让这熊熊烈焰，为尔等送葬！",
}

fencheng:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty_ex__fencheng",
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(fencheng.name, Player.HistoryGame) == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local first = effect.tos[1]
    local targets = {first}
    local temp = first.next
    while temp ~= first do
      if not temp.dead then
        table.insert(targets, temp)
      end
      temp = temp.next
    end
    table.removeOne(targets, player)
    local n = 0
    for _, target in ipairs(targets) do
      if not target.dead then
        local cards = room:askToDiscard(target, {
          min_num = n + 1,
          max_num = 999,
          include_equip = true,
          skill_name = fencheng.name,
          cancelable = true,
          prompt = "#ty_ex__fencheng-discard:::"..(n + 1),
        })
        if #cards == 0 then
          room:damage{
            from = player,
            to = target,
            damage = 2,
            damageType = fk.FireDamage,
            skillName = fencheng.name,
          }
          n = 0
        else
          n = #cards
        end
      end
    end
  end
})

return fencheng
