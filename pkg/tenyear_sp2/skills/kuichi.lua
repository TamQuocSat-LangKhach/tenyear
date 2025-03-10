local kuichi = fk.CreateSkill {
  name = "kuichi"
}

Fk:loadTranslationTable{
  ['kuichi'] = '匮饬',
  [':kuichi'] = '锁定技，回合结束时，若你本回合摸牌数和造成的伤害值均不小于你的体力上限，你失去1点体力。',
  ['$kuichi1'] = '久战沙场，遗伤无数。',
  ['$kuichi2'] = '人无完人，千虑亦有一失。',
}

kuichi:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(skill.name) then
      local room = player.room
      local n = 0
      room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data[1]
        if damage.from == player then
          n = n + damage.damage
        end
      end, Player.HistoryTurn)
      if n < player.maxHp then return false end
      n = 0
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player.id and move.moveReason == fk.ReasonDraw then
            n = n + #move.moveInfo
          end
        end
      end, Player.HistoryTurn)
      return n >= player.maxHp
    end
  end,
  on_use = function(self, event, target, player)
    player.room:loseHp(player, 1, kuichi.name)
  end,
})

return kuichi
