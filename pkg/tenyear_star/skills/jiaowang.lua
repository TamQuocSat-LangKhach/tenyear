local jiaowang = fk.CreateSkill {
  name = "jiaowang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiaowang"] = "骄妄",
  [":jiaowang"] = "锁定技，每轮结束时，若本轮没有角色死亡，你失去1点体力并发动〖硝焰〗。",

  ["$jiaowang1"] = "剑顾四野，马踏青山，今谁堪敌手？",
  ["$jiaowang2"] = "并土四州，带甲百万，吾可居大否？"
}

jiaowang:addEffect(fk.RoundEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiaowang.name) and
      #player.room.logic:getEventsOfScope(GameEvent.Death, 1, Util.TrueFunc, Player.HistoryRound) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, jiaowang.name)
    local skill = Fk.skills["xiaoyan"]
    skill:doCost(event, target, player, data)
  end,
})

return jiaowang
