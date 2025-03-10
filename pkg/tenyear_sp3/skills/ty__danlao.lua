local ty__danlao = fk.CreateSkill {
  name = "ty__danlao"
}

Fk:loadTranslationTable{
  ['ty__danlao'] = '啖酪',
  ['#ty__danlao-invoke'] = '啖酪：你可以摸一张牌，令 %arg 对你无效',
  [':ty__danlao'] = '当你成为【杀】或锦囊牌的目标后，若你不是唯一目标，你可以摸一张牌，然后此牌对你无效。',
  ['$ty__danlao1'] = '此酪味美，诸君何不与我共食之？',
  ['$ty__danlao2'] = '来来来，丞相美意，不可辜负啊。',
}

ty__danlao:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__danlao.name) and (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and not U.isOnlyTarget(player, data, event)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty__danlao.name,
      prompt = "#ty__danlao-invoke:::"..data.card:toLogString()
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, ty__danlao.name)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
})

return ty__danlao
