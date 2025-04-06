local yinshih = fk.CreateSkill {
  name = "yinshih",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yinshih"] = "隐世",
  [":yinshih"] = "锁定技，你每回合首次受到无色牌或非游戏牌造成的伤害时，防止此伤害。当场上有角色判定【八卦阵】时，你获得其生效的判定牌。",

  ["$yinshih1"] = "南阳隐世，耕读传家。",
  ["$yinshih2"] = "手扶耒耜，不闻风雷。",
}

yinshih:addEffect(fk.FinishJudge, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yinshih.name) and
      table.contains({"eight_diagram", "#eight_diagram_skill"}, data.reason) and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, yinshih.name)
  end,
})

yinshih:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yinshih.name) and
      player == target and (not data.card or data.card.color == Card.NoColor) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      #player.room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data
        return damage.to == player and (not damage.card or damage.card.color == Card.NoColor)
      end, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
  end,
})

return yinshih
