local xianshuai = fk.CreateSkill {
  name = "xianshuai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xianshuai"] = "先率",
  [":xianshuai"] = "锁定技，一名角色造成伤害后，若此伤害是本轮第一次造成伤害，你摸一张牌；若伤害来源为你，你对受到伤害的角色造成1点伤害。",

  ["$xianshuai1"] = "九州齐喑，首义瞩吾！",
  ["$xianshuai2"] = "雄兵一击，则天下大白！",
}

xianshuai:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xianshuai.name) and target and player:usedSkillTimes(xianshuai.name, Player.HistoryRound) == 0 then
      local damage_event = player.room.logic:getActualDamageEvents(1, Util.TrueFunc, Player.HistoryRound)
      return #damage_event == 1 and damage_event[1].data == data
    end
  end,
  on_cost = function (self, event, target, player, data)
    if target == player and not data.to.dead then
      event:setCostData(self, {tos = {data.to}})
    else
      event:setCostData(self, nil)
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, xianshuai.name)
    if target == player and not data.to.dead then
      player.room:damage{
        from = player,
        to = data.to,
        damage = 1,
        skillName = xianshuai.name,
      }
    end
  end,
})

return xianshuai
