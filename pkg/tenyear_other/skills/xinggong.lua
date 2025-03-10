local xinggong = fk.CreateSkill {
  name = "xinggong"
}

Fk:loadTranslationTable{
  ['xinggong'] = '兴功',
  ['#xinggong'] = '兴功：获得任意张本回合进入弃牌堆的牌，若大于体力值则受到超出张数的伤害！',
  [':xinggong'] = '出牌阶段限一次，你可以选择获得任意张本回合进入弃牌堆的牌，若张数大于当前体力值，每超出一张对自己造成1点伤害。',
}

xinggong:addEffect('active', {
  anim_type = "drawcard",
  prompt = "#xinggong",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(xinggong.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local all_cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(all_cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    if #all_cards == 0 then return end
    local cards = room:askToChooseCards(player, {
      min = 1,
      max = #all_cards,
      flag = { card_data = { { "pile_discard", all_cards } } },
      skill_name = xinggong.name,
      prompt = "#xinggong"
    })
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, xinggong.name, nil, true, player.id)
    if not player.dead and #cards > player.hp then
      room:damage{
        from = player,
        to = player,
        damage = #cards - player.hp,
        skillName = xinggong.name,
      }
    end
  end,
})

return xinggong
