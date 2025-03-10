local sanshou = fk.CreateSkill {
  name = "sanshou"
}

Fk:loadTranslationTable{
  ['sanshou'] = '三首',
  [':sanshou'] = '当你受到伤害时，你可以亮出牌堆顶的三张牌，若其中有本回合所有角色均未使用过的牌的类型，防止此伤害。',
  ['$sanshou1'] = '三公既现，领大道而立黄天。',
  ['$sanshou2'] = '天地三才，载厚德以驱魍魉。',
}

sanshou:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = U.turnOverCardsFromDrawPile(player, 3, sanshou.name)
    local mark = player:getTableMark("sanshou-turn")
    if #mark ~= 3 then
      mark = {0, 0, 0}
    end
    if not table.every(mark, function (value) return value == 1 end) then
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event ~= nil then
        local mark_change = false
        room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if mark[use.card.type] == 0 then
            mark_change = true
            mark[use.card.type] = 1
          end
        end, turn_event.id)
        if mark_change then
          room:setPlayerMark(player, "sanshou-turn", mark)
        end
      end
    end
    local yes = false
    for _, id in ipairs(cards) do
      if mark[Fk:getCardById(id).type] == 0 then
        room:setCardEmotion(id, "judgegood")
        yes = true
      else
        room:setCardEmotion(id, "judgebad")
      end
    end
    room:delay(1000)
    room:cleanProcessingArea(cards, sanshou.name)
    return yes
  end,
})

return sanshou
