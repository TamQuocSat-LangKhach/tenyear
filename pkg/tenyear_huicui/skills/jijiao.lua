local jijiao = fk.CreateSkill {
  name = "jijiao",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["jijiao"] = "继椒",
  [":jijiao"] = "限定技，出牌阶段，你可以令一名角色获得弃牌堆中本局游戏你使用和弃置的所有普通锦囊牌，这些牌不能被抵消。每回合结束后，"..
  "若此回合内牌堆洗过牌或有角色死亡，此技能视为未发动过。",

  ["#jijiao"] = "继椒：令一名角色获得弃牌堆中你使用或弃置的所有普通锦囊牌！",
  ["@@jijiao-inhand"] = "继椒",

  ["$jijiao1"] = "哀吾姊早逝，幸陛下垂怜。",
  ["$jijiao2"] = "居椒之殊荣，妾得之惶恐。",
}

jijiao:addEffect("active", {
  name = jijiao.name,
  prompt = "#jijiao",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jijiao.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local ids = {}
    room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
      local use_event = e:findParent(GameEvent.UseCard)
      if use_event and use_event.data.from == player then
        for _, move in ipairs(e.data) do
          if move.moveReason == fk.ReasonUse and move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId):isCommonTrick() and table.contains(Card:getIdList(use_event.data.card), info.cardId) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
      else
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId):isCommonTrick() and
                (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
      end
    end, Player.HistoryGame)
    ids = table.filter(ids, function (id)
      return table.contains(room.discard_pile, id)
    end)
    if #ids > 0 then
      room:obtainCard(target, ids, false, fk.ReasonJustMove, target, jijiao.name, "@@jijiao-inhand")
    end
  end,
})

jijiao:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(jijiao.name) and player:usedSkillTimes(jijiao.name, Player.HistoryGame) > 0 and
      (player:getMark("jijiao-turn") > 0 or
      #player.room.logic:getEventsOfScope(GameEvent.Death, 1, Util.TrueFunc, Player.HistoryTurn) > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory("jijiao", 0, Player.HistoryGame)
  end,
})
jijiao:addEffect(fk.AfterDrawPileShuffle, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "jijiao-turn", 1)
  end,
})

jijiao:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return data.card:getMark("@@jijiao-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.unoffsetableList = table.simpleClone(player.room.players)
  end,
})

return jijiao
