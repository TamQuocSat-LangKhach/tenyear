local ty__zhubi = fk.CreateSkill {
  name = "ty__zhubi"
}

Fk:loadTranslationTable{
  ["ty__zhubi"] = "铸币",
  ["#ty__zhubi-invoke"] = "铸币：是否将一张【无中生有】置于牌堆顶？",
  [":ty__zhubi"] = "当<font color='red'>♦</font>牌因弃置而进入弃牌堆后，你可从牌堆或弃牌堆将一张【无中生有】置于牌堆顶。",
  ["$ty__zhubi1"] = "铸币平市，百货可居。",
  ["$ty__zhubi2"] = "做钱直百，府库皆实。",
}

ty__zhubi:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty__zhubi.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).suit == Card.Diamond then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty__zhubi.name,
      prompt = "#ty__zhubi-invoke"
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule("ex_nihilo")
    if #cards > 0 then
      local id = cards[1]
      table.removeOne(room.draw_pile, id)
      table.insert(room.draw_pile, 1, id)
    else
      cards = room:getCardsFromPileByRule("ex_nihilo", 1, "discardPile")
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          fromArea = Card.DiscardPile,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = ty__zhubi.name,
        })
      end
    end
  end,
})

return ty__zhubi
