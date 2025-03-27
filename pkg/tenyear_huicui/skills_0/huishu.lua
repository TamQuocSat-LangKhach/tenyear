local huishu = fk.CreateSkill {
  name = "huishu",
  dynamic_desc = function(self, player)
    return
      "huishu_inner:" ..
      (player:getMark("huishu1") + 3) .. ":" ..
      (player:getMark("huishu2") + 1) .. ":" ..
      (player:getMark("huishu3") + 2)
  end,
}

Fk:loadTranslationTable{
  ['huishu'] = '慧淑',
  ['huishu1'] = '摸牌数',
  ['huishu2'] = '摸牌后弃牌数',
  ['huishu3'] = '获得锦囊所需弃牌数',
  [':huishu'] = '摸牌阶段结束时，你可以摸3张牌然后弃置1张手牌。若如此做，你本回合弃置超过2张牌时，从弃牌堆中随机获得等量的非基本牌。',
  ['$huishu1'] = '心有慧镜，善解百般人意。',
  ['$huishu2'] = '袖着静淑，可揾夜阑之泪。',
}

huishu:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = huishu.name})
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMark("huishu1") + 3, huishu.name)
    if not player.dead then
      local x = player:getMark("huishu2") + 1
      player.room:askToDiscard(player, {min_num = x, max_num = x, include_equip = false, skill_name = huishu.name, cancelable = false})
    end
  end,
})

huishu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(huishu) then return false end
    local room = player.room
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and player:usedSkillTimes(huishu.name) > 0 and player:getMark("_huishu-turn") == 0 then
            local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
            if not turn_event then return false end
            local end_id = turn_event.id
            local x = 0
            room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
              for _, move2 in ipairs(e.data) do
                if move2.from == player.id and move2.moveReason == fk.ReasonDiscard then
                  for _, info2 in ipairs(move2.moveInfo) do
                    if info2.fromArea == Card.PlayerHand or info2.fromArea == Card.PlayerEquip then
                      x = x + 1
                    end
                  end
                end
              end
              return false
            end, end_id)
            return x > player:getMark("huishu3") + 2 and table.find(room.discard_pile, function (id)
              return Fk:getCardById(id) ~= Card.TypeBasic
            end)
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", player:getMark("huishu3") + 2, "discardPile")
    if #cards > 0 then
      room:setPlayerMark(player, "_huishu-turn", 1)
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player.id, huishu.name)
    end
  end,
})

huishu.on_acquire = function (skill, player, is_start)
  local room = player.room
  room:setPlayerMark(player, "huishu1", 0)
  room:setPlayerMark(player, "huishu2", 0)
  room:setPlayerMark(player, "huishu3", 0)
  room:setPlayerMark(player, "@" .. huishu.name, {3, 1, 2})
end

huishu.on_lose = function (skill, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "huishu1", 0)
  room:setPlayerMark(player, "huishu2", 0)
  room:setPlayerMark(player, "huishu3", 0)
  room:setPlayerMark(player, "@" .. huishu.name, 0)
end

return huishu
