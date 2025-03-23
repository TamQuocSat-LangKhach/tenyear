local shezang = fk.CreateSkill {
  name = "shezang"
}

Fk:loadTranslationTable{
  ['shezang'] = '奢葬',
  [':shezang'] = '每轮限一次，当你进入濒死状态时，或一名角色于你的回合内进入濒死状态时，你可以从牌堆底获得不同花色的牌各一张。',
  ['$shezang1'] = '世间千百物，物物皆相思。',
  ['$shezang2'] = '伊人将逝，何物为葬？',
}

shezang:addEffect(fk.EnterDying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and (target == player or player.phase ~= Player.NotActive) and
      player:usedSkillTimes(shezang.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {1, 2, 3, 4}
    local cards = {}
    local id = -1
    for i = #room.draw_pile, 1, -1 do
      id = room.draw_pile[i]
      if table.removeOne(suits, Fk:getCardById(id).suit) then
        table.insert(cards, id)
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = shezang.name,
        moveVisible = true
      })
    end
  end,
})

return shezang
