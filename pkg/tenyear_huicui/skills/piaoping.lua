local piaoping = fk.CreateSkill {
  name = "piaoping",
  tags = { Skill.Switch, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["piaoping"] = "漂萍",
  [":piaoping"] = "锁定技，转换技，当你使用一张牌时，阳：你摸X张牌；阴：你弃置X张牌（X为本回合〖漂萍〗发动次数且至多为你当前体力值）。",

  ["$piaoping1"] = "奔波四处，前途未明。",
  ["$piaoping2"] = "辗转各地，功业难寻。",
}

piaoping:addEffect(fk.CardUsing, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(piaoping.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.min(player:usedSkillTimes(piaoping.name, Player.HistoryTurn), player.hp)
    if player:getSwitchSkillState(piaoping.name, true) == fk.SwitchYang then
      player:drawCards(n, piaoping.name)
    else
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = piaoping.name,
        cancelable = false,
        skip = false,
      })
    end
  end,
})

return piaoping
