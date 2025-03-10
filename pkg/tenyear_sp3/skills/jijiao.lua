local jijiao = fk.CreateSkill {
  name = "jijiao"
}

Fk:loadTranslationTable{
  ['jijiao'] = '继椒',
  ['#jijiao-active'] = '发动 继椒，令一名角色获得弃牌堆中你使用或弃置的所有普通锦囊牌',
  ['@@jijiao-inhand'] = '继椒',
  ['#jijiao_delay'] = '继椒',
  [':jijiao'] = '限定技，出牌阶段，你可以令一名角色获得弃牌堆中本局游戏你使用和弃置的所有普通锦囊牌，这些牌不能被抵消。每回合结束后，若此回合内牌堆洗过牌或有角色死亡，复原此技能。',
  ['$jijiao1'] = '哀吾姊早逝，幸陛下垂怜。',
  ['$jijiao2'] = '居椒之殊荣，妾得之惶恐。',
}

jijiao:addEffect('active', {
  name = jijiao.name,
  prompt = "#jijiao-active",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(jijiao.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local ids = {}
    local discard_pile = table.simpleClone(room.discard_pile)
    local logic = room.logic
    local events = logic.event_recorder[GameEvent.MoveCards] or Util.DummyTable
    for i = #events, 1, -1 do
      local e = events[i]
      local move_by_use = false
      local parentUseEvent = e:findParent(GameEvent.UseCard)
      if parentUseEvent then
        local use = parentUseEvent.data[1]
        if use.from == effect.from then
          move_by_use = true
        end
      end
      for _, move in ipairs(e.data) do
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.removeOne(discard_pile, id) and Fk:getCardById(id):isCommonTrick() then
            if move.toArea == Card.DiscardPile then
              if move.moveReason == fk.ReasonUse and move_by_use then
                table.insert(ids, id)
              elseif move.moveReason == fk.ReasonDiscard and move.from == player.id then
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  table.insert(ids, id)
                end
              end
            end
          end
        end
      end
      if #discard_pile == 0 then break end
    end

    if #ids > 0 then
      room:obtainCard(target.id, ids, false, fk.ReasonJustMove, target.id, jijiao.name, "@@jijiao-inhand")
    end
  end,
})

jijiao:addEffect(fk.TurnEnd, {
  name = "#jijiao_delay",
  anim_type = "special",
  can_trigger = function(self, event, player)
    if player:hasSkill(jijiao) and player:usedSkillTimes("jijiao", Player.HistoryGame) > 0 then
      if player:getMark("jijiao-turn") > 0 then return true end
      local logic = player.room.logic
      local deathevents = logic.event_recorder[GameEvent.Death] or Util.DummyTable
      local turnevents = logic.event_recorder[GameEvent.Turn] or Util.DummyTable
      return #deathevents > 0 and #turnevents > 0 and deathevents[#deathevents].id > turnevents[#turnevents].id
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, player)
    player:setSkillUseHistory("jijiao", 0, Player.HistoryGame)
  end,
  can_refresh = function(self, event, player)
    if event == fk.PreCardUse then
      return not data.card:isVirtual() and data.card:getMark("@@jijiao-inhand") > 0
    else
      return player:getMark("jijiao-turn") == 0
    end
  end,
  on_refresh = function(self, event, player)
    if event == fk.PreCardUse then
      local room = player.room
      data.unoffsetableList = table.map(room.alive_players, Util.IdMapper)
    else
      player.room:setPlayerMark(player, "jijiao-turn", 1)
    end
  end,
})

return jijiao
