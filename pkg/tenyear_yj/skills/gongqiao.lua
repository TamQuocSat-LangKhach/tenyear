local gongqiao = fk.CreateSkill {
  name = "gongqiao",
}

Fk:loadTranslationTable {
  ["gongqiao"] = "工巧",
  [":gongqiao"] = "出牌阶段限一次，你可以将一张手牌置入你的装备区（替换原装备，视为没有效果的“工巧”装备牌）。"..
  "若你的装备区里有以此法置入的：基本牌，你使用基本牌的数值+1；锦囊牌，你每回合首次使用一种类别的牌后摸一张牌；装备牌，你的手牌上限+3。",

  ["#gongqiao"] = "工巧：将一张手牌置入你的装备区",

  ["$gongqiao1"] = "怀兼爱之心，琢世间百器。",
  ["$gongqiao2"] = "机巧用尽，方化腐朽为神奇！",
}

gongqiao:addEffect("active", {
  anim_type = "support",
  prompt = "#gongqiao",
  max_phase_use_time = 1,
  card_num = 1,
  target_num = 0,
  can_use = function (self, player)
    return player:usedEffectTimes(gongqiao.name, Player.HistoryPhase) == 0 and #player:getAvailableEquipSlots() > 0
  end,
  interaction = function(self, player)
    return UI.ComboBox { choices = player:getAvailableEquipSlots() }
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local card = Fk:getCardById(effect.cards[1])
    local mapper = {
      [Player.WeaponSlot] = "weapon",
      [Player.ArmorSlot] = "armor",
      [Player.OffensiveRideSlot] = "offensive_horse",
      [Player.DefensiveRideSlot] = "defensive_horse",
      [Player.TreasureSlot] = "treasure",
    }
    room:setCardMark(card, gongqiao.name, mapper[self.interaction.data])
    player:filterHandcards()
    room:moveCardIntoEquip(player, effect.cards, gongqiao.name, true, player)
  end,
})

gongqiao:addEffect("filter", {
  card_filter = function(self, to_select, player, isJudgeEvent)
    return to_select:getMark(gongqiao.name) ~= 0
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard(to_select:getMark(gongqiao.name).."__gongqiao", to_select.suit, to_select.number)
  end,
})

gongqiao:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea ~= Card.PlayerEquip and move.toArea ~= Card.Processing then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId, true):getMark(gongqiao.name) ~= 0 then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea ~= Card.PlayerEquip and move.toArea ~= Card.Processing then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            player.room:setCardMark(Fk:getCardById(info.cardId, true), gongqiao.name, 0)
          end
        end
      end
    end
  end,
})

gongqiao:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(gongqiao.name) and data.card.type == Card.TypeBasic and
      table.find(player:getCardIds("e"), function (id)
        return Fk:getCardById(id):getMark(gongqiao.name) ~= 0 and Fk:getCardById(id, true).type == Card.TypeBasic
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.additionalRecover = (data.additionalRecover or 0) + 1
    if data.card.name == "analeptic" and not (data.extra_data and data.extra_data.analepticRecover) then
      data.extra_data = data.extra_data or {}
      data.extra_data.additionalDrank = (data.extra_data.additionalDrank or 0) + 1
    end
  end,
})

gongqiao:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(gongqiao.name) and
      table.find(player:getCardIds("e"), function (id)
        return Fk:getCardById(id):getMark(gongqiao.name) ~= 0 and Fk:getCardById(id, true).type == Card.TypeTrick
      end) then
      local use_events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == player and use.card.type == data.card.type
      end, Player.HistoryTurn)
      return #use_events == 1 and use_events[1].data == data
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, gongqiao.name)
  end,
})

gongqiao:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(gongqiao.name) and
      table.find(player:getCardIds("e"), function (id)
        return Fk:getCardById(id):getMark(gongqiao.name) ~= 0 and Fk:getCardById(id, true).type == Card.TypeEquip
      end) then
      return 3
    end
  end,
})

return gongqiao
