local ty__shangyi = fk.CreateSkill {
  name = "ty__shangyi"
}

Fk:loadTranslationTable{
  ['ty__shangyi'] = '尚义',
  ['#ty__shangyi'] = '尚义：令一名角色观看你的手牌，然后你观看其手牌并可以弃置其中一张♠牌和一张♣牌',
  [':ty__shangyi'] = '出牌阶段限一次，你可以令一名其他角色观看你的手牌。若如此做，你观看其手牌并可以弃置其中的一张♠牌和一张♣牌。',
  ['$ty__shangyi1'] = '大丈夫为人坦荡，看下手牌算什么。',
  ['$ty__shangyi2'] = '敌情已了然于胸，即刻出发！',
}

ty__shangyi:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#ty__shangyi",
  can_use = function(self, player)
    return player:usedSkillTimes(ty__shangyi.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    U.viewCards(target, player:getCardIds("h"), ty__shangyi.name)
    if player.dead or target.dead or target:isKongcheng() then return end
    local cards = room:askToPoxi(player, {
      poxi_type = ty__shangyi.name,
      data = { { target.general, target:getCardIds("h") } },
      cancelable = true,
    })
    if #cards > 0 then
      room:throwCard(cards, ty__shangyi.name, target, player)
    end
  end,
})

return ty__shangyi
