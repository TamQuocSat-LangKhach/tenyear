local quzhou = fk.CreateSkill {
  name = "quzhou"
}

Fk:loadTranslationTable{
  ['quzhou'] = '趋舟',
  ['#quzhou'] = '趋舟：你可以亮出牌堆顶牌直到使用亮出的【杀】或选择获得亮出的牌',
  ['quzhou_gain'] = '获得此流程中亮出的所有牌',
  ['quzhou_reveal'] = '继续亮出牌堆顶一张牌，重复此流程',
  [':quzhou'] = '出牌阶段限一次，你可以亮出牌堆顶一张牌，若此牌为：【杀】，你使用之；不为【杀】，你选择一项：1.获得此流程中亮出的所有牌；2.若此流程中亮出的牌数小于存活人数，你重复此流程。',
  ['$quzhou1'] = '冲！冲！',
  ['$quzhou2'] = '靠近！靠近！',
}

quzhou:addEffect('active', {
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = "#quzhou",
  can_use = function(self, player)
    return player:usedSkillTimes(quzhou.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local idsRevealt = {}

    while #idsRevealt <= #room.alive_players do
      local ids = room:getNCards(1)
      room:moveCardTo(ids, Card.Processing, nil, fk.ReasonJustMove, quzhou.name, nil, true, player.id)
      table.insert(idsRevealt, ids[1])

      if Fk:getCardById(ids[1]).trueName == "slash" then
        room:askToUseRealCard(player, {
          pattern = ids,
          skill_name = quzhou.name,
          expand_pile = ids,
          extra_data = { bypass_times = true, extraUse = true },
        })
        break
      else
        local choices = { "quzhou_gain" }
        if #idsRevealt < #room.alive_players then
          table.insert(choices, "quzhou_reveal")
        end

        local choice = room:askToChoice(player, {
          choices = choices,
          skill_name = quzhou.name
        })
        if choice == "quzhou_gain" then
          room:obtainCard(player, idsRevealt, true, fk.ReasonPrey, player.id, quzhou.name)
          break
        end
      end
    end

    local inProcessing = table.filter(idsRevealt, function(id) return room:getCardArea(id) == Card.Processing end)
    if #inProcessing > 0 then
      room:moveCardTo(inProcessing, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, quzhou.name, nil, true, player.id)
    end
  end,
})

return quzhou
