local ty__lianzhu = fk.CreateSkill {
  name = "ty__lianzhu"
}

Fk:loadTranslationTable{
  ['ty__lianzhu'] = '连诛',
  ['#ty__lianzhu'] = '连诛：展示并交给一名其他角色一张牌，根据颜色执行效果',
  ['#ty__lianzhu-discard'] = '连诛：你需弃置两张牌，否则 %src 摸两张牌',
  [':ty__lianzhu'] = '出牌阶段限一次，你可以展示并交给一名其他角色一张牌，若此牌为：红色，你摸一张牌；黑色，其选择一项：1.你摸两张牌；2.弃置两张牌。',
  ['$ty__lianzhu1'] = '坐上这华盖车，可真威风啊。',
  ['$ty__lianzhu2'] = '跟着我爷爷，还有什么好怕的？',
}

ty__lianzhu:addEffect('active', {
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#ty__lianzhu",
  can_use = function(self, player)
    return player:usedSkillTimes(ty__lianzhu.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    player:showCards(effect.cards)
    if player.dead or not table.contains(player:getCardIds("h"), effect.cards[1]) then return end
    local card = Fk:getCardById(effect.cards[1])
    room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonGive, ty__lianzhu.name, nil, true, target.id)
    if player.dead then return end
    if card.color == Card.Red then
      player:drawCards(1, ty__lianzhu.name)
    elseif card.color == Card.Black then
      local min_num = 2
      local max_num = 2
      local discard_result = room:askToDiscard(target, {
        min_num = min_num,
        max_num = max_num,
        include_equip = true,
        skill_name = ty__lianzhu.name,
        cancelable = true,
        pattern = ".",
        prompt = "#ty__lianzhu-discard:"..player.id
      })
      if #discard_result ~= 2 then
        player:drawCards(2, ty__lianzhu.name)
      end
    end
  end,
})

return ty__lianzhu
