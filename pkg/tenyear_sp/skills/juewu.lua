local juewu = fk.CreateSkill {
  name = "juewu",
}

Fk:loadTranslationTable{
  ["juewu"] = "绝武",
  [":juewu"] = "你可以将点数为2的牌当伤害牌或【水淹七军】使用（每回合每种牌名限一次）。当你得到其他角色的牌后，这些牌的点数视为2。",

  ["#juewu"] = "绝武：将点数为2的牌当任意伤害牌使用",

  ["$juewu1"] = "此身屹沧海，覆手潮立，浪涌三十六天。",
  ["$juewu2"] = "青龙啸肃月，长刀裂空，威降一十九将。",
}

local U = require "packages/utility/utility"

juewu:addAcquireEffect(function (self, player, is_start)
  local names = {}
  for _, id in ipairs(Fk:getAllCardIds()) do
    local card = Fk:getCardById(id, true)
    if card.is_damage_card and not card.is_derived then
      table.insertIfNeed(names, card.name)
    end
  end
  table.insertIfNeed(names, "ty__drowning")
  player.room:setPlayerMark(player, juewu.name, names)
end)

juewu:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#juewu",
  pattern = ".",
  interaction = function(self, player)
    local all_names = player:getMark(juewu.name)
    local names = player:getViewAsCardNames(juewu.name, all_names, nil, player:getTableMark("juewu-turn"))
    return U.CardNameBox { choices = names, all_choices = all_names, }
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if Fk.all_card_types[self.interaction.data] == nil or #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    if card.number == 2 then
      return true
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or Fk.all_card_types[self.interaction.data] == nil then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = juewu.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, "juewu-turn", use.card.trueName)
  end,
  enabled_at_response = function(self, player, response)
    return not response and
      #player:getViewAsCardNames(juewu.name, player:getMark(juewu.name), nil, player:getTableMark("juewu-turn")) > 0
  end,
})

juewu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(juewu.name) then
      local cards = {}
      for _, move in ipairs(data) do
        if move.to == player and move.from and move.from ~= player and move.toArea == Player.Hand then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if table.contains({Player.Hand, Player.Equip}, info.fromArea) and
              table.contains(player:getCardIds("h"), id) then
              table.insert(cards, id)
            end
          end
        end
      end
      cards = player.room.logic:moveCardsHoldingAreaCheck(cards)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(event:getCostData(self).cards) do
      room:setCardMark(Fk:getCardById(id), "juewu-inhand", 1)
    end
    player:filterHandcards()
  end,
})

juewu:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return card:getMark("juewu-inhand") > 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard(card.name, card.suit, 2)
  end,
})

return juewu
