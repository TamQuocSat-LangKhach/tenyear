local xiangshu = fk.CreateSkill {
  name = "xiangshu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xiangshu"] = "襄戍",
  [":xiangshu"] = "限定技，结束阶段，若你本回合造成过伤害，你可以令一名已受伤角色回复X点体力并摸X张牌（X为你本回合造成的伤害值且最多为5）。",

  ["#xiangshu-invoke"] = "襄戍：你可以令一名已受伤角色回复%arg点体力并摸%arg张牌",

  ["$xiangshu1"] = "得道多襄，为公是瞻！",
  ["$xiangshu2"] = "愿为中原，永戍北疆！",
}

xiangshu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiangshu.name) and player.phase == Player.Finish and
      player:usedSkillTimes(xiangshu.name, Player.HistoryGame) == 0 and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data.from == player
      end) > 0 and
      table.find(player.room.alive_players, function(p)
        return p:isWounded()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    room.logic:getActualDamageEvents(1, function(e)
      if e.data.from == player then
        n = n + e.data.damage
      end
      if n > 4 then
        return true
      end
    end)
    local targets = table.filter(room.alive_players, function(p)
      return p:isWounded()
    end)
    n = math.min(n, 5)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xiangshu-invoke:::"..n,
      skill_name = xiangshu.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to, choice = n})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = event:getCostData(self).choice
    room:recover{
      who = to,
      num = n,
      recoverBy = player,
      skillName = xiangshu.name,
    }
    if not to.dead then
      to:drawCards(n, xiangshu.name)
    end
  end,
})

return xiangshu
