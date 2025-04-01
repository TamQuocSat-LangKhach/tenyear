local chenlue = fk.CreateSkill {
  name = "chenlue",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["chenlue"] = "沉略",
  [":chenlue"] = "限定技，出牌阶段，你可以从牌堆、弃牌堆、场上或其他角色的手牌中获得所有“死士”牌，此阶段结束时，将这些牌移出游戏直到你死亡。",

  ["#chenlue"] = "沉略：获得所有“死士”，此阶段结束时移出游戏！",
  ["#chenlue_pile"] = "沉略",

  ["$chenlue1"] = "怀泰山之重，必立以千仞。",
  ["$chenlue2"] = "万世之勋待取，此乃亮剑之时。",
}

chenlue:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#chenlue",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(chenlue.name, Player.HistoryGame) == 0 and player:getMark("sanshi") ~= 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local areas = {Card.PlayerEquip, Card.PlayerJudge, Card.DrawPile, Card.DiscardPile}
    local cards = table.filter(player:getTableMark("sanshi"), function (id)
      local area = room:getCardArea(id)
      return table.contains(areas, area) or (area == Card.PlayerHand and not table.contains(player:getCardIds("h"), id))
    end)
    if #cards > 0 then
      room:setPlayerMark(player, "chenlue-phase", cards)
      room.logic:getCurrentEvent():findParent(GameEvent.Phase, true):addCleaner(function()
        if not player.dead then
          player:addToPile("#chenlue_pile", cards, true, chenlue.name)
        end
      end)
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, chenlue.name, nil, true, player)
    end
  end,
})

return chenlue
