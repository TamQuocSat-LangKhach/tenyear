local duchi = fk.CreateSkill {
  name = "duchi",
}

Fk:loadTranslationTable{
  ["duchi"] = "督持",
  [":duchi"] = "每回合限一次，当你成为其他角色使用牌的目标后，你可以从牌堆底摸一张牌并展示所有手牌，若颜色均相同，此牌对你无效。",

  ["$duchi1"] = "今督众将临战，当使敌入寇无功。",
  ["$duchi2"] = "吴军远道而来，彼疲军也。",
}

duchi:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duchi.name) and
      player:usedSkillTimes(duchi.name, Player.HistoryTurn) == 0 and
      data.from ~= player
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, duchi.name, "bottom")
    if player.dead or player:isKongcheng() then return end
    local cards = table.simpleClone(player:getCardIds("h"))
    player:showCards(cards)
    if player.dead or player:isKongcheng() then return end
    if table.every(cards, function(id)
      return Fk:getCardById(id).color == Fk:getCardById(cards[1]).color or
        Fk:getCardById(id).color == Card.NoColor
    end) then
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      table.insertIfNeed(data.use.nullifiedTargets, player)
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        data:cancelTarget(player)
      end
    end
  end,
})

return duchi
