local panqin = fk.CreateSkill {
  name = "ty__panqin"
}

Fk:loadTranslationTable{
  ['ty__panqin'] = '叛侵',
  ['@[:]ty__manwang'] = '蛮王',
  ['#ty__panqin_delete-invoke'] = '叛侵：将弃牌堆中你弃置的牌当【南蛮入侵】使用，然后执行并移除〖蛮王〗的最后一项，加1点体力上限并回复1点体力',
  ['#ty__panqin-invoke'] = '叛侵：你可将弃牌堆中你弃置的牌当【南蛮入侵】使用',
  [':ty__panqin'] = '出牌阶段或弃牌阶段结束时，你可以将本阶段你因弃置进入弃牌堆且仍在弃牌堆的牌当【南蛮入侵】使用，然后若此牌目标数不小于这些牌的数量，你执行并移除〖蛮王〗的最后一项，然后加1点体力上限并回复1点体力。',
}

panqin:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(panqin.name) and (player.phase == Player.Play or player.phase == Player.Discard) then
      local ids = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile and move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand) and table.contains(player.room.discard_pile, info.cardId) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
        return false
      end, Player.HistoryPhase)
      if #ids == 0 then return false end
      local card = Fk:cloneCard("savage_assault")
      card:addSubcards(ids)
      local tos = table.filter(player.room:getOtherPlayers(player), function(p) return not player:isProhibited(p, card) end)
      if not player:prohibitUse(card) and #tos > 0 then
        event:setCostData(self, {ids, tos})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local cards_num = #event:getCostData(self)[1]
    local tos_num = #event:getCostData(self)[2]
    local promot = (#player:getTableMark("@[:]ty__manwang") > 0 and tos_num >= cards_num) and "#ty__panqin_delete-invoke" or "#ty__panqin-invoke"
    if player.room:askToSkillInvoke(player, {
      skill_name = panqin.name,
      prompt = promot
    }) then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self)[1]
    local tos = event:getCostData(self)[2]
    room:useVirtualCard("savage_assault", cards, player, tos, panqin.name)
    if #tos >= #cards then
      doManwang(player, #player:getTableMark("@[:]ty__manwang"))
      local mark = player:getTableMark("@[:]ty__manwang")
      if #mark > 0 then
        room:removeTableMark(player, "@[:]ty__manwang", mark[#mark])
        room:changeMaxHp(player, 1)
        if player:isWounded() and not player.dead then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = panqin.name,
          }
        end
      end
    end
  end,
})

return panqin
