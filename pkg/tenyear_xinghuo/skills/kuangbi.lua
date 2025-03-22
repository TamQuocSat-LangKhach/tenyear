local kuangbi = fk.CreateSkill {
  name = "ty_ex__kuangbi",
}

Fk:loadTranslationTable{
  ["ty_ex__kuangbi"] = "匡弼",
  [":ty_ex__kuangbi"] = "出牌阶段开始时，你可以令一名其他角色将一至三张牌置于你的武将牌上，本阶段结束时将“匡弼”牌置入弃牌堆。"..
  "当你于有“匡弼”牌时使用牌时，若你：有与之花色相同的“匡弼”牌，则随机将其中一张置入弃牌堆，然后你与该角色各摸一张牌；"..
  "没有与之花色相同的“匡弼”牌，则随机将一张置入弃牌堆，然后你摸一张牌。",

  ["#ty_ex__kuangbi-choose"] = "匡弼：你可以令一名角色将一至三张牌置为你的“匡弼”牌",
  ["#ty_ex__kuangbi-ask"] = "匡弼：将一至三张牌置为 %src 的“匡弼”牌",

  ["$ty_ex__kuangbi1"] = "江东多娇，士当弼国以全方圆。",
  ["$ty_ex__kuangbi2"] = "吴垒锦绣，卿当匡佐使延万年。",
}

kuangbi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  derived_piles = "ty_ex__kuangbi",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuangbi.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = target.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(target, {
      skill_name = kuangbi.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#ty_ex__kuangbi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = target.room
    local to = event:getCostData(self).tos[1]
    local cards = room:askToCards(to, {
      skill_name = kuangbi.name,
      include_equip = true,
      min_num = 1,
      max_num = 3,
      prompt = "#ty_ex__kuangbi-ask:"..player.id,
      cancelable = false,
    })
    room:setPlayerMark(player, kuangbi.name, to.id)
    player:addToPile(kuangbi.name, cards, false, kuangbi.name, target)
  end,
})

kuangbi:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile(kuangbi.name) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = target.room
    local cards = target:getPile(kuangbi.name)
    local ids = table.filter(cards, function(id)
      return Fk:getCardById(id).suit == data.card.suit
    end)
    local throw = #ids > 0 and table.random(ids) or table.random(cards)
    room:moveCardTo(throw, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, kuangbi.name)
    if not player.dead then
      player:drawCards(1, kuangbi.name)
    end
    if #ids == 0 then return end
    local to = room:getPlayerById(player:getMark(kuangbi.name))
    if not to.dead then
      room:doIndicate(player, {to})
      to:drawCards(1, kuangbi.name)
    end
  end,
})
kuangbi:addEffect(fk.EventPhaseEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and #player:getPile(kuangbi.name) > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:moveCardTo(player:getPile(kuangbi.name), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, kuangbi.name)
  end,
})

return kuangbi
