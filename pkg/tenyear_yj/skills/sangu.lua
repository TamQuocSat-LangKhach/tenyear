local sangu = fk.CreateSkill {
  name = "sangu"
}

Fk:loadTranslationTable{
  ['sangu'] = '三顾',
  ['#sangu-choose'] = '你可以发动 三顾，选择一名其他角色，指定其下个出牌阶段使用前三张牌的牌名',
  ['#sangu-declare'] = '三顾：宣言 %dest 在下个出牌阶段使用或打出的第 %arg 张牌的牌名',
  ['@$sangu'] = '三顾',
  ['#sangu_delay'] = '三顾',
  ['#sangu_filter'] = '三顾',
  [':sangu'] = '结束阶段，你可依次选择至多三张【杀】或普通锦囊牌（【借刀杀人】、【无懈可击】除外）并指定一名其他角色，其下个出牌阶段使用的前X张牌视为你选择的牌（X为你选择的牌数）。若你选择的牌均为本回合你使用过的牌，防止“三顾”牌对你造成的伤害。',
  ['$sangu1'] = '思报君恩，尽父子之忠。',
  ['$sangu2'] = '欲酬三顾，竭三代之力。',
}

sangu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(sangu.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#sangu-choose",
      skill_name = sangu.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(skill, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))
    local cards = player:getMark("sangu_cards")
    if type(cards) ~= "table" then
      local ban_cards = {"nullification", "collateral"}
      cards = table.filter(U.getUniversalCards(room, "bt", true), function (id)
        local card = Fk:getCardById(id)
        return card.trueName == "slash" or (card:isCommonTrick() and not table.contains(ban_cards, card.trueName))
      end)
      room:setPlayerMark(player, "sangu_cards", cards)
    end
    local cards_copy = table.simpleClone(cards)
    local names = {}
    for i = 1, 3, 1 do
      if #cards_copy == 0 then break end
      local result = U.askToChooseCardsAndChoices(player, {
        min_card_num = 1,
        max_card_num = 1,
        cards = cards_copy,
        choices = {"OK"},
        skill_name = sangu.name,
        prompt = "#sangu-declare::" .. to.id .. ":" .. tostring(i),
        all_choices = {"Cancel"}
      })
      if #result == 0 then break end
      table.removeOne(cards_copy, result[1])
      table.insert(names, Fk:getCardById(result[1]).trueName)
    end
    if #names == 0 then return false end
    local mark = to:getTableMark("@$sangu")
    table.insertTable(mark, names)
    room:setPlayerMark(to, "@$sangu", mark)

    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
    if turn_event == nil then return false end
    local end_id = turn_event.id
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      if use.from == player.id then
        table.removeOne(names, use.card.trueName)
      end
      return false
    end, end_id)
    if #names == 0 then
      room:addTableMark(player, "sangu_avoid", to.id)
    end
  end,
})

sangu:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:isAlive() and player.phase == Player.Play and #player:getTableMark("@$sangu") > 0 and player == target
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase)
      if phase_event ~= nil then
        room:setPlayerMark(player, "sangu_effect-phase", 1)
        player:filterHandcards()
        phase_event:addCleaner(function()
          room:setPlayerMark(player, "@$sangu", 0)
          player:filterHandcards()
          for _, p in ipairs(room.alive_players) do
            local mark = p:getTableMark("sangu_avoid")
            table.removeOne(mark, player.id)
            room:setPlayerMark(p, "sangu_avoid", #mark > 0 and mark or 0)
          end
        end)
      end
    end
  end,
})

sangu:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:isAlive() and player.phase == Player.Play and #player:getTableMark("@$sangu") > 0 then
      local mark = player:getTableMark("sangu_effect-phase")
      return mark ~= 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@$sangu")
    table.remove(mark, 1)
    room:setPlayerMark(player, "@$sangu", #mark > 0 and mark or 0)
    if #mark == 0 then
      room:setPlayerMark(player, "sangu_effect-phase", 0)
    end
    player:filterHandcards()
  end,
})

sangu:addEffect(fk.CardResponding, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:isAlive() and player.phase == Player.Play and #player:getTableMark("@$sangu") > 0 then
      local mark = player:getTableMark("sangu_effect-phase")
      return mark ~= 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@$sangu")
    table.remove(mark, 1)
    room:setPlayerMark(player, "@$sangu", #mark > 0 and mark or 0)
    if #mark == 0 then
      room:setPlayerMark(player, "sangu_effect-phase", 0)
    end
    player:filterHandcards()
  end,
})

sangu:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:isAlive() and player.phase == Player.Play and #player:getTableMark("@$sangu") > 0 then
      local mark = player:getTableMark("sangu_effect-phase")
      return mark ~= 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(event.data) do
      if move.from == player.id and move.moveReason == fk.ReasonRecast then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
})

sangu:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:isAlive() and player.phase == Player.Play then
      local data = event.data[1]
      return player == target and data.card and table.contains(data.card.skillNames, sangu.name)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      local card_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not card_event then return false end
      return table.contains(player:getTableMark("sangu_avoid"), card_event.data[1].from)
    end
  end,
})

sangu:addEffect('filter', {
  mute = true,
  card_filter = function(self, player, to_select)
    return player:getMark("sangu_effect-phase") ~= 0 and #player:getTableMark("@$sangu") > 0 and
      table.contains(player.player_cards[Player.Hand], to_select.id)
  end,
  view_as = function(self, player, to_select)
    local mark = player:getTableMark("@$sangu")
    if #mark > 0 then
      local card = Fk:cloneCard(mark[1], to_select.suit, to_select.number)
      card.skillName = sangu.name
      return card
    end
  end,
})

return sangu
