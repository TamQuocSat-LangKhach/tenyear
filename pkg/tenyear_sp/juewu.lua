local juewu = fk.CreateSkill {
  name = "juewu"
}

Fk:loadTranslationTable{
  ['juewu'] = '绝武',
  ['#juewu-viewas'] = '发动 绝武，将点数为2的牌转化为任意伤害牌使用',
  ['#juewu_trigger'] = '绝武',
  ['@@juewu-inhand'] = '绝武',
  ['#juewu_filter'] = '绝武',
  [':juewu'] = '你可以将点数为2的牌当伤害牌或【水淹七军】使用（每回合每种牌名限一次）。当你得到其他角色的牌后，这些牌的点数视为2。',
  ['$juewu1'] = '此身屹沧海，覆手潮立，浪涌三十六天。',
  ['$juewu2'] = '青龙啸肃月，长刀裂空，威降一十九将。',
}

juewu:addEffect('viewas', {
  prompt = "#juewu-viewas",
  anim_type = "offensive",
  pattern = ".",
  handly_pile = true,
  interaction = function(self, player)
    local names = player:getMark("juewu_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          table.insertIfNeed(names, card.name)
        end
      end
      table.insertIfNeed(names, "ty__drowning")
      player:setMark("juewu_names", names)
    end
    local choices = U.getViewAsCardNames(player, "juewu", names, nil, player:getTableMark("juewu-turn"))
    return U.CardNameBox {
      choices = choices,
      all_choices = names,
      default_choice = "juewu"
    }
  end,
  card_filter = function(self, player, to_select, selected)
    if Fk.all_card_types[skill.interaction.data] == nil or #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    if card.number == 2 then
      return true
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or Fk.all_card_types[skill.interaction.data] == nil then return nil end
    local card = Fk:cloneCard(skill.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = juewu.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getTableMark("juewu-turn")
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "juewu-turn", mark)
  end,
  enabled_at_play = Util.TrueFunc,
  enabled_at_response = function(self, player, response)
    if response then return false end
    if Fk.currentResponsePattern == nil then return false end
    local names = player:getMark("juewu_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          table.insertIfNeed(names, card.name)
        end
      end
      table.insertIfNeed(names, "ty__drowning")
      player:setMark("juewu_names", names)
    end
    local mark = player:getTableMark("juewu-turn")
    local choices = {}
    for _, name in pairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = juewu.name
      if not table.contains(mark, to_use.trueName) and Exppattern:Parse(Fk.currentResponsePattern):match(to_use) then
        return true
      end
    end
  end,
  on_lose = function(self, player, is_death)
    player.room:setPlayerMark(player, "juewu-turn", 0)
  end
})

juewu:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(juewu) then return false end
    local cards = {}
    local handcards = player:getCardIds(Player.Hand)
    for _, move in ipairs(data) do
      if move.to == player.id and move.from and move.from ~= player.id and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.contains({Player.Hand, Player.Equip}, info.fromArea) and  table.contains(handcards, id) then
            table.insert(cards, id)
          end
        end
      end
    end
    cards = U.moveCardsHoldingAreaCheck(player.room, cards)
    if #cards > 0 then
      event:setCostData(skill, cards)
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(event:getCostData(skill)) do
      room:setCardMark(Fk:getCardById(id), "@@juewu-inhand", 1)
    end
  end,
})

juewu:addEffect('filter', {
  mute = true,
  card_filter = function(self, player, card, isJudgeEvent)
    return card:getMark("@@juewu-inhand") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard(card.name, card.suit, 2)
  end,
})

return juewu
