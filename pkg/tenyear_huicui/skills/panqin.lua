local panqin = fk.CreateSkill{
  name = "ty__panqin",
}

Fk:loadTranslationTable{
  ["ty__panqin"] = "叛侵",
  [":ty__panqin"] = "出牌阶段结束时，或弃牌阶段结束时，你可以将本阶段你因弃置进入弃牌堆且仍在弃牌堆的牌当【南蛮入侵】使用，"..
  "然后若此牌目标数不小于这些牌的数量，你执行并移除〖蛮王〗的最后一项，然后加1点体力上限并回复1点体力。",

  ["#ty__panqin-invoke"] = "叛侵：你可以将弃牌堆中你弃置的牌当【南蛮入侵】使用",
  ["#ty__panqin_delete-invoke"] = "叛侵：你可以将弃牌堆中你弃置的牌当【南蛮入侵】使用，执行并移除“蛮王”的最后一项，加1点体力上限并回复1点体力",

  ["$ty__panqin1"] = "百兽嘶鸣筋骨振，蛮王起兮万人随！",
  ["$ty__panqin2"] = "呼勒格诗惹之民，召南中群雄复起！",
}

local function doManwang(player, i)
  local room = player.room
  if i == 1 then
    room:handleAddLoseSkills(player, "ty__panqin")
  elseif i == 2 then
    player:drawCards(1, "ty__manwang")
  elseif i == 3 then
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "ty__manwang",
      }
    end
  elseif i == 4 then
    player:drawCards(2, "ty__manwang")
    room:handleAddLoseSkills(player, "-ty__panqin")
  end
end

panqin:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(panqin.name) and (player.phase == Player.Play or player.phase == Player.Discard) then
      local ids = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand) and
                table.contains(player.room.discard_pile, info.cardId) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
      end, Player.HistoryPhase)
      if #ids == 0 then return end
      local card = Fk:cloneCard("savage_assault")
      card:addSubcards(ids)
      local tos = table.filter(player.room:getOtherPlayers(player, false), function(p)
        return not player:isProhibited(p, card)
      end)
      if not player:prohibitUse(card) and #tos > 0 then
        event:setCostData(self, {cards = ids, tos = tos})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards_num = #event:getCostData(self).cards
    local tos_num = #event:getCostData(self).tos
    return room:askToSkillInvoke(player, {
      skill_name = panqin.name,
      prompt = (player:getMark("manwang") < 4 and tos_num >= cards_num) and "#ty__panqin_delete-invoke" or "#ty__panqin-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    local tos = event:getCostData(self).tos
    room:useVirtualCard("savage_assault", cards, player, tos, panqin.name)
    if #tos >= #cards and not player.dead then
      doManwang(player, 4 - player:getMark("ty__manwang"))
      if player:getMark("ty__manwang") < 4 and not player.dead then
        room:addPlayerMark(player, "ty__manwang")
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
