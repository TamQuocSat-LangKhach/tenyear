local ty__niluan = fk.CreateSkill {
  name = "ty__niluan"
}

Fk:loadTranslationTable{
  ['ty__niluan'] = '逆乱',
  [':ty__niluan'] = '出牌阶段，你可以将一张黑色牌当【杀】使用；你以此法使用的【杀】结算后，若此【杀】未造成伤害，其不计入使用次数限制。',
  ['$ty__niluan1'] = '如果不能功成名就，那就干脆为祸一方！',
  ['$ty__niluan2'] = '哈哈哈哈哈，天下之事皆无常！',
}

ty__niluan:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = ty__niluan.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response and player.phase == Player.Play
  end,
})

ty__niluan:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, ty__niluan.name) and not data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    if not data.extraUse then
      data.extraUse = true
      player:addCardUseHistory(data.card.trueName, -1)
    end
  end,
})

return ty__niluan
