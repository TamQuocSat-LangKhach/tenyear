local youqi = fk.CreateSkill {
  name = "youqi"
}

Fk:loadTranslationTable{
  ['youqi'] = '幽栖',
  ['yinlu'] = '引路',
  [':youqi'] = '锁定技，其他角色因“引路”弃置牌时，你有概率获得此牌，该角色距离你越近，概率越高。',
  ['$youqi1'] = '寒烟锁旧山，坐看云起出。',
  ['$youqi2'] = '某隐居山野，不慕富贵功名。',
}

youqi:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(youqi.name) then
      for _, move in ipairs(data) do
        if move.skillName == "yinlu" and move.from and move.from ~= player.id then
          event:setCostData(skill, move)
          local x = 1 - (math.min(5, player:distanceTo(player.room:getPlayerById(move.from))) / 10)
          return x > math.random()  --据说，距离1 0.9概率，距离5以上 0.5概率
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local move_data = event:getCostData(skill)
    for _, info in ipairs(move_data.moveInfo) do
      player.room:obtainCard(player.id, info.cardId, true, fk.ReasonJustMove)
    end
  end,
})

return youqi
