local qiai = fk.CreateSkill {
  name = "qiai"
}

Fk:loadTranslationTable{
  ['qiai'] = '七哀',
  ['#qiai-give'] = '七哀：交给 %dest 一张牌',
  [':qiai'] = '限定技，当你进入濒死状态时，你可令每名其他角色同时交给你一张牌。',
  ['$qiai1'] = '未知身死处，何能两相完？',
  ['$qiai2'] = '悟彼下泉人，喟然伤心肝。',
}

qiai:addEffect(fk.EnterDying, {
  frequency = Skill.Limited,
  anim_type = "defensive",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(qiai.name) and target == player and player:usedSkillTimes(qiai.name, Player.HistoryGame) == 0 and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local players = table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end)
    local result = room:askToJointCard(players, {
      min_num = 1,
      max_num = 1,
      cancelable = false,
      skill_name = qiai.name,
      prompt = "#qiai-give::" .. player.id
    })
    local moveInfos = {}
    for _, p in ipairs(players) do
      table.insert(moveInfos, {
        ids = result[p.id],
        from = p.id,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = p.id,
        skillName = qiai.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
  end,
})

return qiai
