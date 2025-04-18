local tanluan = fk.CreateSkill{
  name = "tanluan",
}

Fk:loadTranslationTable{
  ["tanluan"] = "探乱",
  [":tanluan"] = "出牌阶段限一次，你可以使用一张本回合因弃置而进入弃牌堆的牌，若因此使用的牌对其他角色造成了伤害，〖蛮后〗视为未发动过。",

  ["#tanluan"] = "探乱：使用一张本回合因弃置而进入弃牌堆的牌，若造成伤害则重置“蛮后”",

  ["$tanluan1"] = "",
  ["$tanluan2"] = "",
}

tanluan:addEffect("active", {
  prompt = "#tanluan",
  anim_type = "offensive",
  max_phase_use_time = 1,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local all_cards, cards = {}, {}
    room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) then
              if move.moveReason == fk.ReasonDiscard and
                table.insertIfNeed(all_cards, info.cardId) then
                table.insertIfNeed(cards, info.cardId)
              else
                table.insertIfNeed(all_cards, info.cardId)
              end
            end
          end
        end
      end
    end, nil, Player.HistoryTurn)
    if #cards == 0 then return end
    local use = room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = tanluan.name,
      prompt = "#tanluan",
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = cards,
      },
    })
    if use and use.damageDealt and
      table.find(room.players, function (p)
        return p ~= player and use.damageDealt[p] ~= nil
      end) then
      player:setSkillUseHistory("manhou", 0, Player.HistoryPhase)
    end
  end,
})

tanluan:addLoseEffect(function (self, player, is_death)
  player:setSkillUseHistory(tanluan.name, 0, Player.HistoryPhase)
end)

return tanluan