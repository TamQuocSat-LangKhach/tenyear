local dianhua = fk.CreateSkill {
  name = "dianhua"
}

Fk:loadTranslationTable{
  ['dianhua'] = '点化',
  [':dianhua'] = '准备阶段或结束阶段，你可以观看牌堆顶的X张牌（X为你的标记数）。若如此做，你将这些牌以任意顺序放回牌堆顶或牌堆底。',
  ['$dianhua1'] = '大道无形，点化无为。',
  ['$dianhua2'] = '得此点化，必得大道。',
}

dianhua:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dianhua.name) and (player.phase == Player.Start or player.phase == Player.Finish) and
      not table.every({"spade", "club", "heart", "diamond"}, function(suit)
        return player:getMark("@@falu"..suit) == 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local n = 0
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("@@falu"..suit) > 0 then
        n = n + 1
      end
    end
    if n > 0 and player.room:askToSkillInvoke(player, { skill_name = dianhua.name }) then
      event:setCostData(skill, n)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToGuanxing(player, {
      cards = room:getNCards(event:getCostData(skill))
    })
  end,
})

return dianhua
