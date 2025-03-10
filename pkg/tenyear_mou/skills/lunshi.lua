local lunshi = fk.CreateSkill {
  name = "tymou__lunshi"
}

Fk:loadTranslationTable{
  ['tymou__lunshi'] = '论势',
  ['#tymou__lunshi-viewas'] = '论势：你可将一张手牌当【无懈可击】使用',
  [':tymou__lunshi'] = '当你需要使用【无懈可击】抵消其他角色对除其外的角色使用的普通锦囊牌时，若你手牌中的红色和黑色牌数相等，你可以将一张手牌当不可被响应的【无懈可击】使用。',
  ['$tymou__lunshi1'] = '曹公济天下大难，必定霸王之业。',
  ['$tymou__lunshi2'] = '智者审于良主，袁公未知用人之机。',
}

-- ViewAsSkill
lunshi:addEffect('viewas', {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#tymou__lunshi-viewas",
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = lunshi.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function (self, player, use)
    use.disresponsiveList = table.map(player.room.players, Util.IdMapper)
  end,
  enabled_at_response = function (self, player, response)
    if not (
      not response and
      (
      response == nil or
      player:getMark("tymou__lunshi_activated") > 0
    ) and
      not player:isKongcheng()
    )
    then
      return false
    end

    local red, black = 0, 0
    for _, id in ipairs(player:getCardIds("h")) do
      local color = Fk:getCardById(id).color
      if color == Card.Black then
        black = black + 1
      elseif color == Card.Red then
        red = red + 1
      end
    end

    return red == black
  end,
})

-- TriggerSkill
lunshi:addEffect(fk.HandleAskForPlayCard, {
  can_refresh = function(self, event, target, player, data)
    if data.afterRequest and (data.extra_data or {}).lunshiEffected then
      return player:getMark("tymou__lunshi_activated") > 0
    end

    return
      player:hasSkill(lunshi) and
      data.eventData and
      data.eventData.from and
      data.eventData.to and
      data.eventData.from ~= player.id and
      data.eventData.to ~= data.eventData.from and
      data.eventData.card:isCommonTrick() and
      Exppattern:Parse(data.pattern):match(Fk:cloneCard("nullification"))
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.afterRequest then
      room:setPlayerMark(player, "tymou__lunshi_activated", 0)
    else
      room:setPlayerMark(player, "tymou__lunshi_activated", 1)
      data.extra_data = data.extra_data or {}
      data.extra_data.lunshiEffected = true
    end
  end,
})

return lunshi
