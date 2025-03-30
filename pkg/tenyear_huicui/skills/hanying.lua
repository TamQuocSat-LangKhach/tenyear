local hanying = fk.CreateSkill {
  name = "hanying",
}

Fk:loadTranslationTable{
  ["hanying"] = "寒英",
  [":hanying"] = "准备阶段，你可以展示牌堆顶第一张装备牌，然后令一名手牌数等于你的角色使用之。",

  ["#hanying-choose"] = "寒英：选择一名手牌数等于你的角色，令其使用%arg",

  ["$hanying1"] = "寒梅不争春，空任群芳妒。",
  ["$hanying2"] = "三九寒天，尤有寒英凌霜。",
}

hanying:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hanying.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = nil
    for _, id in ipairs(room.draw_pile) do
      local c = Fk:getCardById(id)
      if c.type == Card.TypeEquip then
        card = c
        break
      end
    end
    if card == nil then return end
    room:turnOverCardsFromDrawPile(player, {card.id}, hanying.name)
    local targets = table.filter(room.alive_players, function (p)
      return p:getHandcardNum() == player:getHandcardNum() and p:canUseTo(card, p)
    end)
    if #targets == 0 then
      room:cleanProcessingArea({card.id})
      return
    end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#hanying-choose:::"..card:toLogString(),
      skill_name = hanying.name,
      cancelable = false,
    })[1]
    room:useCard{
      from = to,
      tos = { to },
      card = card,
    }
  end
})

return hanying
