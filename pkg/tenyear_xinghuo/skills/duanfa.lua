local duanfa = fk.CreateSkill {
  name = "duanfa"
}

Fk:loadTranslationTable{
  ['duanfa'] = '断发',
  [':duanfa'] = '出牌阶段，你可以弃置任意张黑色牌，然后摸等量的牌（你每阶段以此法弃置的牌数总和不能大于体力上限）。',
  ['$duanfa1'] = '身体发肤，受之父母。',
  ['$duanfa2'] = '今断发以明志，尚不可证吾之心意？',
}

duanfa:addEffect('active', {
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:getMark("duanfa-phase") < player.maxHp
  end,
  target_num = 0,
  min_card_num = 1,
  max_card_num = function(player)
    return player.maxHp - player:getMark("duanfa-phase")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < (player.maxHp - player:getMark("duanfa-phase")) and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, duanfa.name, player)
    room:drawCards(player, #effect.cards, duanfa.name)
    room:addPlayerMark(player, "duanfa-phase", #effect.cards)
  end
})

return duanfa
