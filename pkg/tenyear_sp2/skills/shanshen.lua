local shanshen = fk.CreateSkill {
  name = "shanshen"
}

Fk:loadTranslationTable{
  ['shanshen'] = '善身',
  [':shanshen'] = '当一名角色死亡时，你可令〖隅泣〗中的一个数字+2（单项不能超过5）。若你没有对其造成过伤害，你回复1点体力。',
  ['$shanshen1'] = '好善为德，坚守本心。',
  ['$shanshen2'] = '洁身自爱，独善其身。',
}

shanshen:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(shanshen.name)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    AddYuqi(player, shanshen.name, 2)
    if player:isWounded() and #player.room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data[1]
      if damage.from == player and damage.to == target then
        return true
      end
    end, nil, 0) == 0 then
      room:recover{
        who = player,
        num = 1,
        skillName = shanshen.name,
      }
    end
  end,
})

return shanshen
