local mansi = fk.CreateSkill {
  name = "mansi"
}

Fk:loadTranslationTable{
  ['mansi'] = '蛮嗣',
  ['#mansi'] = '蛮嗣：你可以将所有手牌当【南蛮入侵】使用',
  ['@mansi'] = '蛮嗣',
  [':mansi'] = '出牌阶段限一次，你可以将所有手牌当【南蛮入侵】使用；当一名角色受到【南蛮入侵】的伤害后，你摸一张牌。',
  ['$mansi1'] = '承父母庇护，得此福气。',
  ['$mansi2'] = '多谢父母怜爱。',
}

mansi:addEffect('viewas', {
  anim_type = "offensive",
  prompt = "#mansi",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("savage_assault")
    card:addSubcards(player:getCardIds(Player.Hand))
    card.skillName = mansi.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(mansi.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
})

mansi:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mansi.name) and data.card and data.card.trueName == "savage_assault"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("mansi")
    room:notifySkillInvoked(player, "mansi", "drawcard")
    player:drawCards(1, mansi.name)
    room:addPlayerMark(player, "@mansi", 1)
  end,
  can_refresh = function(self, event, target, player, data)
    return player == target and data == mansi and player:getMark("@mansi") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@mansi", 0)
  end,
})

return mansi
