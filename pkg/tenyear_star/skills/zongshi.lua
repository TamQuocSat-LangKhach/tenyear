local zongshiy = fk.CreateSkill {
  name = "zongshiy",
}

Fk:loadTranslationTable{
  ["zongshiy"] = "纵势",
  [":zongshiy"] = "出牌阶段，你可以展示一张基本牌或普通锦囊牌，然后将此花色的所有其他手牌当这张牌使用（此牌可指定的目标数改为以此法使用的牌数）。",

  ["#zongshiy"] = "纵势：展示一张基本牌或普通锦囊牌，将所有此花色的其他手牌当此牌使用",
  ["#zongshiy-use"] = "纵势：将所有其他同花色手牌当【%arg】使用，并可指定至多%arg2个目标",
  ["#zongshiy-choose"] = "纵势：为此【%arg】指定至多%arg2个目标（无距离限制）",

  ["$zongshiy1"] = "四世三公之家，当为天下之望。",
  ["$zongshiy2"] = "大势在我，可怀问鼎之心。",
}

zongshiy:addEffect("active", {
  prompt = function(self, player, selected_cards)
    if #selected_cards == 0 then
      return "#zongshiy"
    else
      local card = Fk:getCardById(selected_cards[1])
      local n = #table.filter(player:getCardIds("h"), function (id)
        return id ~= selected_cards[1] and Fk:getCardById(id).suit == card.suit
      end)
      return "#zongshiy-use:::"..card.name..":"..n
    end
  end,
  card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and table.contains(player:getCardIds("h"), to_select) then
      local card = Fk:getCardById(to_select)
      if card.type == Card.TypeBasic or card:isCommonTrick() then
        if card.skill:getMinTargetNum(player) > 1 then return end
        local suit = card.suit
        if suit == Card.NoSuit then return false end
        local cards = table.filter(player:getCardIds("h"), function (id)
          return id ~= to_select and Fk:getCardById(id):compareSuitWith(card)
        end)
        if #cards == 0 then return false end
        local to_use = Fk:cloneCard(card.name)
        to_use.skillName = zongshiy.name
        to_use:addSubcards(cards)
        return table.find(Fk:currentRoom().alive_players, function (p)
          return to_use.skill:modTargetFilter(player, p, {}, card, {bypass_distances = true})
        end)
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    player:showCards(effect.cards)
    if player.dead then return end
    local cards = table.filter(player:getCardIds("h"), function (id)
      return id ~= effect.cards[1] and Fk:getCardById(id):compareSuitWith(Fk:getCardById(effect.cards[1]))
    end)
    if #cards == 0 then return end
    local card = Fk:cloneCard(Fk:getCardById(effect.cards[1]).name)
    card.skillName = zongshiy.name
    card:addSubcards(cards)
    if player:prohibitUse(card) then return end

    local targets = table.filter(room.alive_players, function (p)
      return card.skill:modTargetFilter(player, p, {}, card, {bypass_distances = true})
    end)
    if #targets == 0 then return end
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #cards,
      prompt = "#zongshiy-choose:::"..card.name..":"..#cards,
      skill_name = zongshiy.name,
      cancelable = false,
    })
    room:useCard{
      from = player,
      tos = targets,
      card = card,
      extraUse = (player.phase ~= Player.Play),
    }
  end,
})

return zongshiy
