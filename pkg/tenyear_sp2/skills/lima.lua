local lima = fk.CreateSkill {
  name = "lima"
}

Fk:loadTranslationTable{
  ['lima'] = '骊马',
  [':lima'] = '锁定技，场上每有一张坐骑牌，你计算与其他角色的距离-1（至少为1）。',
}

lima:addEffect('distance', {
  correct_func = function(self, from, to)
    if from:hasSkill(lima.name) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        for _, id in ipairs(p:getCardIds("e")) do
          local card_type = Fk:getCardById(id).sub_type
          if card_type == Card.SubtypeOffensiveRide or card_type == Card.SubtypeDefensiveRide then
            n = n + 1
          end
        end
      end
      return -math.max(1, n)
    end
    return 0
  end,
})

return lima
