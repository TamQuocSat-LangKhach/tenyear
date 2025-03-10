local ty__qingcheng = fk.CreateSkill {
  name = "ty__qingcheng"
}

Fk:loadTranslationTable{
  ['ty__qingcheng'] = '倾城',
  [':ty__qingcheng'] = '出牌阶段限一次，你可以与一名手牌数不大于你的男性角色交换手牌。',
  ['$ty__qingcheng1'] = '我和你们真是投缘呐。',
  ['$ty__qingcheng2'] = '哼，眼睛都都直了呀。',
}

ty__qingcheng:addEffect('active', {
  anim_type = "control",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(ty__qingcheng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= player.id and target:isMale() and player:getHandcardNum() >= target:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local cards1 = table.clone(room:getPlayerById(effect.from).player_cards[Player.Hand])
    local cards2 = table.clone(room:getPlayerById(effect.tos[1]).player_cards[Player.Hand])
    local move1 = {
      from = effect.from,
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = ty__qingcheng.name,
    }
    local move2 = {
      from = effect.tos[1],
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = ty__qingcheng.name,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = table.filter(cards1, function(id) return room:getCardArea(id) == Card.Processing end),
      fromArea = Card.Processing,
      to = effect.tos[1],
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = ty__qingcheng.name,
    }
    local move4 = {
      ids = table.filter(cards2, function(id) return room:getCardArea(id) == Card.Processing end),
      fromArea = Card.Processing,
      to = effect.from,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = ty__qingcheng.name,
    }
    room:moveCards(move3, move4)
  end,
})

return ty__qingcheng
