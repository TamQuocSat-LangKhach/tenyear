local ty__jici = fk.CreateSkill {
  name = "ty__jici"
}

Fk:loadTranslationTable{
  ['ty__jici'] = '激词',
  ['@ty__raoshe'] = '饶舌',
  [':ty__jici'] = '锁定技，当你的拼点牌亮出后，若此牌点数小于等于X，则点数+X（X为“饶舌”标记的数量）且你获得本次拼点中点数最大的牌。你死亡时，杀死你的角色弃置7-X张牌并失去1点体力。',
  ['$ty__jici1'] = '天数有变，神器更易，而归于有德之人，此自然之理也。',
  ['$ty__jici2'] = '王命之师，囊括五湖，席卷三江，威取中国，定霸华夏。',
}

ty__jici:addEffect(fk.PindianCardsDisplayed, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty__jici) then
      if data.from == player then
        return data.fromCard.number <= player:getMark("@ty__raoshe")
      elseif table.contains(data.tos, player) then
        return data.results[player.id].toCard.number <= player:getMark("@ty__raoshe")
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card
    if data.from == player then
      card = data.fromCard
    elseif table.contains(data.tos, player) then
      card = data.results[player.id].toCard
    end
    card.number = card.number + player:getMark("@ty__raoshe")
    if player.dead then return end
    local n = card.number
    if data.fromCard.number > n then
      n = data.fromCard.number
    end
    for _, result in pairs(data.results) do
      if result.toCard.number > n then
        n = result.toCard.number
      end
    end
    local cards = {}
    if data.fromCard.number == n and room:getCardArea(data.fromCard) == Card.Processing then
      table.insertIfNeed(cards, data.fromCard)
    end
    for _, result in pairs(data.results) do
      if result.toCard.number == n and room:getCardArea(result.toCard) == Card.Processing then
        table.insertIfNeed(cards, result.toCard)
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, ty__jici.name, "", true, player.id)
    end
  end,
})

ty__jici:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__jici, false, true) and data.damage and data.damage.from and not data.damage.from.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 7 - player:getMark("@ty__raoshe")
    if n > 0 then
      room:askToDiscard(data.damage.from, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = ty__jici.name,
        cancelable = false,
      })
      if data.damage.from.dead then return false end
    end
    room:loseHp(data.damage.from, 1, ty__jici.name)
  end,
})

return ty__jici
