local zhiwang = fk.CreateSkill {
  name = "zhiwang"
}

Fk:loadTranslationTable{
  ['zhiwang'] = '质亡',
  ['#zhiwang-choose'] = '质亡：将伤害改为无伤害来源，并令一名角色本回合结束可以使用使你进入濒死状态的牌',
  ['@@zhiwang-turn'] = '质亡',
  ['#zhiwang-use'] = '质亡：请使用这些牌',
  [':zhiwang'] = '每回合限一次，当你受到牌造成的伤害进入濒死状态时，你可以将此伤害改为无来源伤害并选择一名其他角色，当前回合结束时，其使用弃牌堆中令你进入濒死状态的牌。',
}

zhiwang:addEffect(fk.EnterDying, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhiwang.name, false, true) and data.damage and data.damage.card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#zhiwang-choose",
      skill_name = zhiwang.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage.from = nil
    local to = room:getPlayerById(event:getCostData(self))
    room:addTableMarkIfNeed(to, "@@zhiwang-turn", player.id)
  end,
})

zhiwang:addEffect(fk.TurnEnd, {
  name = "#zhiwang_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@zhiwang-turn") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@@zhiwang-turn")
    local cards = {}
    for _, id in ipairs(mark) do
      local p = room:getPlayerById(id)
      room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
        if e.data[1].who == p.id and e.data[1].damage and e.data[1].damage.card and U.isPureCard(e.data[1].damage.card) then
          if table.contains(room.discard_pile, e.data[1].damage.card.id) then
            table.insertIfNeed(cards, e.data[1].damage.card.id)
          end
        end
        return false
      end, Player.HistoryTurn)
    end
    if #cards == 0 then return false end
    while not player.dead and #cards > 0 do
      local use = room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = "zhiwang",
        prompt = "#zhiwang-use",
        expand_pile = cards,
        bypass_times = true,
        extra_data = {extraUse = true},
        cancelable = true,
        skip = true
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
