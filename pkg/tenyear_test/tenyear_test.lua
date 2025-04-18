
local lukang = General(extension, "wm__lukang", "wu", 4)
local kegou = fk.CreateTriggerSkill{
  name = "kegou",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) then
      local events = player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn)
      return #events == 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    cards = table.filter(cards, function (id)
      return table.every(cards, function (id2)
        return Fk:getCardById(id).number >= Fk:getCardById(id2).number
      end)
    end)
    room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
  end,
}
local jiduan = fk.CreateTriggerSkill{
  name = "jiduan",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.firstTarget and
      table.find(AimGroup:getAllTargets(data.tos), function (id)
        return not player.room:getPlayerById(id):isKongcheng() and not table.contains(player:getTableMark("jiduan-turn"), id)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
      return not room:getPlayerById(id):isKongcheng() and not table.contains(player:getTableMark("jiduan-turn"), id)
    end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jiduan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    if data.card.number ~= 13 then
      room:addTableMark(player, "jiduan-turn", to.id)
    end
    if to:isKongcheng() then return end
    local prompt = "#jiduan0-show"
    if data.card.number > 0 and data.card.number < 14 then
      prompt = "#jiduan-show:::"..data.card.number
    end
    local card = room:askForCard(to, 1, 1, false, self.name, false, nil, "#jiduan-show:::"..data.card.number)
    local yes = prompt ~= "#jiduan0-show" and Fk:getCardById(card[1]).number < data.card.number
    to:showCards(card)
    if player.dead or to.dead or not yes then return end
    local choices = {"jiduan_discard::"..to.id, "jiduan_draw::"..to.id}
    local choice = room:askForChoice(player, choices, self.name)
    if choice:startsWith("jiduan_discard") then
      if table.find(to:getCardIds("h"), function (id)
        return not to:prohibitDiscard(id) and table.contains({1, 2, 3, 4}, Fk:getCardById(id).suit)
      end) then
        local success, dat = room:askForUseActiveSkill(to, "jiduan_active", "#jiduan-discard", false)
        if success and dat then
        else
          dat = {}
          dat.cards = {}
          local suits = {1, 2, 3, 4}
          for _, id in ipairs(to:getCardIds("h")) do
            local suit = Fk:getCardById(id).suit
            if table.contains(suits, suit) and not to:prohibitDiscard(id) then
              table.insert(dat.cards, id)
              table.removeOne(suits, suit)
              if #suits == 0 then
                break
              end
            end
          end
        end
        if #dat.cards > 0 then
          room:throwCard(dat.cards, self.name, to, to)
        end
      end
    else
      local suits = table.filter({1, 2, 3, 4}, function (suit)
        return not table.find(to:getCardIds("h"), function (id)
          return Fk:getCardById(id).suit == suit
        end)
      end)
      if #suits == 0 then return end
      local cards = {}
      local id = -1
      for i = #room.draw_pile, 1, -1 do
        id = room.draw_pile[i]
        if table.removeOne(suits, Fk:getCardById(id).suit) then
          table.insert(cards, id)
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonDraw, self.name, nil, false, to.id)
      end
    end
  end,
}
local jiduan_active = fk.CreateActiveSkill{
  name = "jiduan_active",
  min_card_num = 1,
  target_num = 0,
  card_filter = function (self, to_select, selected, user)
    return table.contains(Self:getCardIds("h"), to_select) and
    not table.find(selected, function (id)
      return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id))
    end) and not Self:prohibitDiscard(to_select)
  end,
  feasible = function (self, selected, selected_cards)
    return #selected == 0 and #selected_cards > 0 and
      not table.find(Self:getCardIds("h"), function (id)
        return Fk:getCardById(id).suit ~= Card.NoSuit and
          not table.find(selected_cards, function (id2)
            return Fk:getCardById(id):compareSuitWith(Fk:getCardById(id2))
          end) and
          not Self:prohibitDiscard(id)
      end)
  end,
}
local dixian = fk.CreateActiveSkill{
  name = "dixian",
  anim_type = "drawcard",
  frequency = Skill.Limited,
  min_card_num = 1,
  target_num = 0,
  prompt = "#dixian",
  can_use = function (self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select)
    return not Self:prohibitDiscard(Fk:getCardById(to_select)) and table.contains(Self:getCardIds("h"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local cards = {}
    for i = 13, 1, -1 do
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number == i then
          table.insert(cards, id)
          if #cards == #effect.cards then
            break
          end
        end
      end
      if #cards == #effect.cards then
        break
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id, "@@dixian-inhand")
    end
  end,
}
local dixian_maxcards = fk.CreateMaxCardsSkill{
  name = "#dixian_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@dixian-inhand") > 0
  end,
}
--[[Fk:loadTranslationTable{
  ["kegou"] = "克构",
  [":kegou"] = "锁定技，其他角色回合结束时，你随机获得本回合进入弃牌堆的点数最大的一张牌。",
}
Fk:loadTranslationTable{
  ["jiduan"] = "急断",
  [":jiduan"] = "每回合每名角色限一次，当你使用牌指定目标后，你可以令其中一名角色展示一张手牌，若点数小于你使用的牌，你选择一项："..
  "1.其弃置每种花色的手牌各一张；2.其摸手牌中没有的花色各一张牌。若你使用的牌点数为K，则不计入此技能次数限制。",
  ["#jiduan-choose"] = "急断：令一名角色展示一张手牌，若点数小于你使用的牌则令其弃牌或摸牌",
  ["#jiduan0-show"] = "急断：请展示一张手牌",
  ["#jiduan-show"] = "急断：请展示一张手牌，若点数小于%arg则执行效果",
  ["jiduan_discard"] = "%dest 弃置每种花色手牌各一张",
  ["jiduan_draw"] = "%dest 摸手牌中缺少的花色牌各一张",
  ["jiduan_active"] = "急断",
  ["#jiduan-discard"] = "急断：请弃置每种花色的手牌各一张",
}
Fk:loadTranslationTable{
  ["dixian"] = "砥贤",
  [":dixian"] = "限定技，出牌阶段，你可以弃置任意张手牌，从牌堆中按点数从大到小顺序获得等量的牌，这些牌不计入手牌上限。",
  ["#dixian"] = "砥贤：弃置任意张手牌，从牌堆按点数从大到小获得等量的牌",
  ["@@dixian-inhand"] = "砥贤",
}]]
