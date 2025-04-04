local zhanyu = fk.CreateSkill{
  name = "zhanyu",
}

Fk:loadTranslationTable{
  ["zhanyu"] = "占欲",
  [":zhanyu"] = "回合开始时，你可以展示一张手牌，令所有其他角色随机弃置一张相同花色的手牌，然后你获得其中一张牌。",

  ["#zhanyu-invoke"] = "占欲：展示一张手牌，令其他角色随机弃一张相同花色的牌，然后你获得其中一张",
  ["#zhanyu-prey"] = "占欲：获得其中一张牌",

  ["$zhanyu1"] = "尔等是何身份？也配与我同席！",
  ["$zhanyu2"] = "我有的，你们都不许有。",
}

zhanyu:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhanyu.name) and not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = zhanyu.name,
      cancelable = true,
      prompt = "#zhanyu-invoke",
    })
    if #card > 0 then
      event:setCostData(self, {tos = room:getOtherPlayers(player, false), cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suit = Fk:getCardById(event:getCostData(self).cards[1]).suit
    player:showCards(event:getCostData(self).cards)
    if suit == Card.NoSuit then return end
    local cards = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and not p:isKongcheng() then
        local ids = table.filter(p:getCardIds("h"), function (id)
          return Fk:getCardById(id).suit == suit and not p:prohibitDiscard(id)
        end)
        if #ids > 0 then
          local id = table.random(ids)
          table.insertIfNeed(cards, id)
          room:throwCard(id, zhanyu.name, p, p)
        end
      end
    end
    if player.dead then return end
    cards = table.filter(cards, function (id)
      return table.contains(room.discard_pile, id)
    end)
    if #cards > 0 then
      local card = room:askToChooseCard(player, {
        target = player,
        flag = { card_data = {{ "pile_discard", cards }} },
        skill_name = zhanyu.name,
        prompt = "#zhanyu-prey",
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, zhanyu.name, nil, true, player)
    end
  end,
})

return zhanyu
