local qiao = fk.CreateSkill {
  name = "qiao"
}

Fk:loadTranslationTable{
  ['qiao'] = '气傲',
  ['#qiao-invoke'] = '气傲：你可以弃置 %dest 一张牌，然后你弃置一张牌',
  [':qiao'] = '每回合限两次，当你成为其他角色使用牌的目标后，你可以弃置其一张牌，然后你弃置一张牌。',
  ['$qiao1'] = '吾六十何为不受兵邪？',
  ['$qiao2'] = '芝性骄傲，吾独不为屈。',
}

qiao:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiao.name) and data.from ~= player.id and
      not player.room:getPlayerById(data.from):isNude() and player:usedSkillTimes(qiao.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = qiao.name,
      prompt = "#qiao-invoke::" .. data.from
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local id = room:askToChooseCard(player, {
      target = from,
      flag = "he",
      skill_name = qiao.name
    })
    room:throwCard({id}, qiao.name, from, player)
    if not player:isNude() then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = qiao.name,
        cancelable = false
      })
    end
  end,
})

return qiao
