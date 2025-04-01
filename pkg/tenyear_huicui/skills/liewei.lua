local liewei = fk.CreateSkill {
  name = "ty__liewei",
}

Fk:loadTranslationTable{
  ["ty__liewei"] = "裂围",
  [":ty__liewei"] = "每回合限X次（X为你的体力值，你的回合内无此限制），有角色进入濒死状态时，你可以摸一张牌。",

  ["$ty__liewei1"] = "都给我交出来！",
  ["$ty__liewei2"] = "还有点用，暂且饶你一命！",
}

liewei:addEffect(fk.EnterDying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(liewei.name) and
      (player.room.current == player or player:usedSkillTimes(liewei.name, Player.HistoryTurn) < player.hp)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, liewei.name)
  end,
})

return liewei
