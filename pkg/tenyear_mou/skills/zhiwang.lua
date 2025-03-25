local zhiwang = fk.CreateSkill {
  name = "zhiwang",
}

Fk:loadTranslationTable{
  ["zhiwang"] = "质亡",
  [":zhiwang"] = "每回合限一次，当你受到牌造成的伤害进入濒死状态时，你可以将此伤害改为无来源伤害并选择一名其他角色，当前回合结束时，"..
  "其使用弃牌堆中令你进入濒死状态的牌。",

  ["#zhiwang-choose"] = "质亡：将伤害改为无伤害来源，并令一名角色本回合结束可以使用使你进入濒死状态的牌",
  ["@@zhiwang-turn"] = "质亡",
  ["#zhiwang-use"] = "质亡：请使用这些牌",
}

zhiwang:addEffect(fk.EnterDying, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhiwang.name) and
      data.damage and data.damage.card and
      player:usedEffectTimes(zhiwang.name, Player.HistoryTurn) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#zhiwang-choose",
      skill_name = zhiwang.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage.from = nil
    local to = event:getCostData(self).tos[1]
    room:addTableMarkIfNeed(to, "@@zhiwang-turn", player.id)
  end,
})

zhiwang:addEffect(fk.TurnEnd, {
  anim_type = "special",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@zhiwang-turn") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@@zhiwang-turn")
    local cards = {}
    for _, id in ipairs(mark) do
      local p = room:getPlayerById(id)
      room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
        if e.data.who == p and e.data.damage and e.data.damage.card and not e.data.damage.card:isVirtual() then
          if table.contains(room.discard_pile, e.data.damage.card.id) then
            table.insertIfNeed(cards, e.data.damage.card.id)
          end
        end
      end, Player.HistoryTurn)
    end
    if #cards == 0 then return false end
    while not player.dead and #cards > 0 do
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = zhiwang.name,
        prompt = "#zhiwang-use",
        extra_data = {
          bypass_times = true,
          extraUse = true,
          expand_pile = cards,
        },
        cancelable = true,
        skip = true,
      })
      if use then
        table.removeOne(cards, use.card:getEffectiveId())
        room:useCard(use)
      else
        return
      end
    end
  end,
})

return zhiwang
