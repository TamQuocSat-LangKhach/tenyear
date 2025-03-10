local muwang = fk.CreateSkill {
  name = "muwang"
}

Fk:loadTranslationTable{
  ['muwang'] = '暮往',
  ['@@muwang-inhand-turn'] = '暮往',
  [':muwang'] = '锁定技，每回合限一次，当你的牌移至弃牌堆后，或由你使用、打出的牌移至弃牌堆后，若其中有基本牌或普通锦囊牌，你获得其中的基本牌和普通锦囊牌中的随机一张。当你于此回合内失去以此法得到的牌后，你弃置一张牌。',
  ['$muwang1'] = '授熟读十万书，腹中唯无降字。',
  ['$muwang2'] = '长河没日，天岂无再明之时！',
}

muwang:addEffect(fk.AfterCardsMove, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(muwang.name) then return false end
    local room = player.room
    if player:usedSkillTimes(muwang.name) == 0 then
      local cards = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              local card = Fk:getCardById(info.cardId, true)
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                (card.type == Card.TypeBasic or card:isCommonTrick()) then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          elseif move.from == nil and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResonpse) then
            local move_event = room.logic:getCurrentEvent()
            local parent_event = move_event.parent
            if parent_event ~= nil and (parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard) then
              local parent_data = parent_event.data[1]
              if parent_data.from == player.id then
                local card_ids = room:getSubcardsByRule(parent_data.card)
                for _, info in ipairs(move.moveInfo) do
                  local card = Fk:getCardById(info.cardId, true)
                  if table.contains(card_ids, info.cardId) and (card.type == Card.TypeBasic or card:isCommonTrick()) then
                    table.insertIfNeed(cards, info.cardId)
                  end
                end
              end
            end
          end
        end
      end
      cards = table.filter(cards, function(id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards > 0 then
        event:setCostData(skill, cards)
        return true
      end
    else
      local mark = player:getTableMark("muwang-turn")
      if #mark == 0 then return false end
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              table.contains(mark, info.cardId) then
              event:setCostData(skill, {})
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(muwang.name)
    if #event:getCostData(skill) > 0 then
      room:notifySkillInvoked(player, muwang.name, "drawcard")
      room:moveCardTo(table.random(event:getCostData(skill)), Card.PlayerHand, player, fk.ReasonJustMove, muwang.name,
        nil, true, player.id, "@@muwang-inhand-turn")
    else
      room:notifySkillInvoked(player, muwang.name, "negative")
      local mark = player:getTableMark("muwang-turn")
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) then
              table.removeOne(mark, info.cardId)
            end
          end
        end
      end
      room:setPlayerMark(player, "muwang-turn", mark)
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = muwang.name,
        cancelable = false,
      })
    end
  end,
})

muwang:addEffect(fk.AfterCardsMove, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local marked = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == muwang.name then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            table.insert(marked, id)
          end
        end
      end
    end
    if #marked > 0 then
      local mark = player:getTableMark("muwang-turn")
      table.insertTableIfNeed(mark, marked)
      room:setPlayerMark(player, "muwang-turn", mark)
    end
  end,
})

return muwang
