local linghui = fk.CreateSkill {
  name = "linghui"
}

Fk:loadTranslationTable{
  ['linghui'] = '灵慧',
  ['#linghui-use'] = '灵慧：你可以使用其中的一张牌，然后获得剩余的随机一张',
  [':linghui'] = '一名角色的结束阶段，若其为你或有角色于本回合内进入过濒死状态，你可以观看牌堆顶的三张牌，你可以使用其中一张牌，然后随机获得剩余牌中的一张。',
  ['$linghui1'] = '福兮祸所依，祸兮福所伏。',
  ['$linghui2'] = '枯桑知风，沧海知寒。',
}

linghui:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(linghui.name) and target.phase == Player.Finish then
      if player == target then return true end
      local logic = player.room.logic
      local dyingevents = logic.event_recorder[GameEvent.Dying] or Util.DummyTable
      local turnevents = logic.event_recorder[GameEvent.Turn] or Util.DummyTable
      return #dyingevents > 0 and #turnevents > 0 and dyingevents[#dyingevents].id > turnevents[#turnevents].id
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = U.turnOverCardsFromDrawPile(player, 3, linghui.name, false)
    local use = room:askToUseRealCard(player, {
      pattern = ids,
      skill_name = linghui.name,
      prompt = "#linghui-use",
      expand_pile = ids,
      bypass_times = true,
      extra_data = {extraUse = true},
    })
    if not player.dead and use then
      local toObtain = table.filter(ids, function (id)
        return room:getCardArea(id) == Card.Processing
      end)
      if #toObtain > 0 then
        room:obtainCard(player, table.random(toObtain, 1), false, fk.ReasonJustMove, player.id, linghui.name)
      end
    end
    U.returnCardsToDrawPile(player, ids, linghui.name, true, false)
  end,
})

return linghui
