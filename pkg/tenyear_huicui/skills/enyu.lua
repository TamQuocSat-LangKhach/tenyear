local enyu = fk.CreateSkill {
  name = "enyu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["enyu"] = "恩遇",
  [":enyu"] = "锁定技，当你成为其他角色使用【杀】或普通锦囊牌的目标后，若你本回合已成为过同名牌的目标，此牌对你无效。",

  ["$enyu1"] = "君以国士待我，我必国士报之。",
  ["$enyu2"] = "吾本乡野腐儒，幸隆君之大恩。",
}

enyu:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(enyu.name) and data.from ~= player and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
        local use = e.data
        return use.card.trueName == data.card.trueName and table.contains(use.tos, player)
      end, Player.HistoryTurn) > 1
  end,
  on_use = function(self, event, target, player, data)
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)
  end,
})

return enyu
