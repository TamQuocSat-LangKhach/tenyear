local danlao = fk.CreateSkill {
  name = "ty__danlao",
}

Fk:loadTranslationTable{
  ["ty__danlao"] = "啖酪",
  [":ty__danlao"] = "当你成为【杀】或锦囊牌的目标后，若你不是唯一目标，你可以摸一张牌，然后此牌对你无效。",

  ["$ty__danlao1"] = "此酪味美，诸君何不与我共食之？",
  ["$ty__danlao2"] = "来来来，丞相美意，不可辜负啊。",
}

danlao:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(danlao.name) and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and
      #data.use.tos > 1
  end,
  on_use = function(self, event, target, player, data)
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)
    player:drawCards(1, danlao.name)
  end,
})

return danlao
