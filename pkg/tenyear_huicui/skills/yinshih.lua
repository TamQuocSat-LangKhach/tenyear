local yinshih = fk.CreateSkill {
  name = "yinshih"
}

Fk:loadTranslationTable{
  ['yinshih'] = '隐世',
  [':yinshih'] = '锁定技，你每回合首次受到无色牌或非游戏牌造成的伤害时，防止此伤害。当场上有角色判定【八卦阵】时，你获得其生效的判定牌。',
  ['$yinshih1'] = '南阳隐世，耕读传家。',
  ['$yinshih2'] = '手扶耒耜，不闻风雷。',
}

yinshih:addEffect(fk.FinishJudge, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(skill.name) then
      return table.contains({"eight_diagram", "#eight_diagram_skill"}, data.reason) and player.room:getCardArea(data.card) == Card.Processing
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.FinishJudge then
      player.room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonPrey, { skill_name = yinshih.name })
    end
  end,
})

yinshih:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yinshih.name) then
      return player == target and (not data.card or data.card.color == Card.NoColor) and player:getMark("yinshih_defensive-turn") == 0 and #player.room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data[1]
        return damage.to == player and (not damage.card or damage.card.color == Card.NoColor)
      end) == 0
    end
  end,
  on_use = function(self, event, target, player, data)
    if player == target then
      player.room:setPlayerMark(player, "yinshih_defensive-turn", 1)
      return true
    end
  end,
})

return yinshih
