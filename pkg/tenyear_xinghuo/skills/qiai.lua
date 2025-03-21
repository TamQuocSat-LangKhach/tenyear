local qiai = fk.CreateSkill {
  name = "qiai",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["qiai"] = "七哀",
  [":qiai"] = "限定技，当你进入濒死状态时，你可以令所有其他角色同时交给你一张牌。",

  ["#qiai-give"] = "七哀：交给 %dest 一张牌",

  ["$qiai1"] = "未知身死处，何能两相完？",
  ["$qiai2"] = "悟彼下泉人，喟然伤心肝。",
}

qiai:addEffect(fk.EnterDying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiai.name) and
      player:usedSkillTimes(qiai.name, Player.HistoryGame) == 0 and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = qiai.name,
    }) then
      event:setCostData(self, {tos = room:getOtherPlayers(player)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local result = room:askToJointCards(player, {
      players = targets,
      min_num = 1,
      max_num = 1,
      cancelable = false,
      skill_name = qiai.name,
      prompt = "#qiai-give::" .. player.id,
    })
    local moveInfos = {}
    for _, p in ipairs(targets) do
      table.insert(moveInfos, {
        ids = result[p],
        from = p,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = p,
        skillName = qiai.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
  end,
})

return qiai
