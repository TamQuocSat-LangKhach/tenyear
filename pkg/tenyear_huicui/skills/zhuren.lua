local zhuren = fk.CreateSkill {
  name = "zhuren",
}

Fk:loadTranslationTable{
  ["zhuren"] = "铸刃",
  [":zhuren"] = "出牌阶段限一次，你可以弃置一张手牌。根据此牌的花色点数，你有一定概率打造成功并获得一张武器牌"..
  "（若打造失败或武器已有则改为摸一张【杀】，花色决定武器名称，点数决定成功率）。此武器牌进入弃牌堆时销毁。",

  ["#zhuren"] = "铸刃：弃置一张手牌，根据此牌花色点数打造专属武器！",

  ["$zhuren1"] = "造刀三千口，用法各不同。",
  ["$zhuren2"] = "此刀，可劈铁珠之筒。",
}

local U = require "packages/utility/utility"

zhuren:addEffect("active", {
  anim_type = "special",
  prompt = "#zhuren",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zhuren.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local card = Fk:getCardById(effect.cards[1])
    room:throwCard(effect.cards, zhuren.name, player, player)
    if player.dead then return end
    local get
    local name = "slash"
    if card.name == "lightning" then
      name = "thunder_blade"
    elseif card.suit == Card.Heart then
      name = "red_spear"
    elseif card.suit == Card.Diamond then
      name = "quenched_blade"
    elseif card.suit == Card.Spade then
      name = "poisonous_dagger"
    elseif card.suit == Card.Club then
      name = "water_sword"
    end
    if name ~= "slash" and name ~= "thunder_blade" then
      if (0 < card.number and card.number < 5 and math.random() > 0.85) or
        (4 < card.number and card.number < 9 and math.random() > 0.9) or
        (8 < card.number and card.number < 13 and math.random() > 0.95) then
        name = "slash"
      end
    end
    if name ~= "slash" then
      get = table.find(U.prepareDeriveCards(room, {
        {"red_spear", Card.Heart, 1},
        {"quenched_blade", Card.Diamond, 1},
        {"poisonous_dagger", Card.Spade, 1},
        {"water_sword", Card.Club, 1},
        {"thunder_blade", Card.Spade, 1}
      }, "zhuren_derivecards"), function (id)
          return room:getCardArea(id) == Card.Void and Fk:getCardById(id).name == name
        end)
      if not get then
        name = "slash"
      end
    end
    if name == "slash" then
      room:setCardEmotion(effect.cards[1], "judgebad")
    else
      room:setCardEmotion(effect.cards[1], "judgegood")
    end
    room:delay(1000)
    if name == "slash" then
      local ids = room:getCardsFromPileByRule("slash")
      if #ids > 0 then
        room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, zhuren.name, nil, true, player)
      end
    elseif get then
      room:setCardMark(Fk:getCardById(get), MarkEnum.DestructIntoDiscard, 1)
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonJustMove, zhuren.name, nil, true, player)
    end
  end,
})

return zhuren
