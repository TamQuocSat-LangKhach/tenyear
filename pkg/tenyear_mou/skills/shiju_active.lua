local shiju_active = fk.CreateSkill {
  name = "shiju&"
}

Fk:loadTranslationTable{
  ['shiju&'] = '势举',
  ['#shiju-active'] = '发动 势举，选择一张牌交给一名拥有“势举”的角色',
  ['shiju'] = '势举',
  ['#shiju-use'] = '势举：你可以使用%arg，令%src增加攻击范围',
  ['@shiju-turn'] = '势举范围',
  [':shiju&'] = '出牌阶段限一次，你可以将一张牌交给谋蒋济。',
}

shiju_active:addEffect('active', {
  anim_type = "support",
  prompt = "#shiju-active",
  card_num = 1,
  target_num = 1,

  can_use = function(self, player)
    local targetRecorded = player:getTableMark("shiju_targets-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(shiju_active) and not table.contains(targetRecorded, p.id)
    end)
  end,

  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,

  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select):hasSkill(shiju_active) and
      not table.contains(player:getTableMark("shiju_targets-phase"), to_select)
  end,

  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:broadcastSkillInvoke("shiju")
    room:addTableMarkIfNeed(player, "shiju_targets-phase", target.id)
    local id = effect.cards[1]
    room:moveCardTo(id, Player.Hand, target, fk.ReasonGive, shiju_active.name, nil, false, player.id)
    if target.dead or room:getCardArea(id) ~= Card.PlayerHand or room:getCardOwner(id) ~= target then return end
    local card = Fk:getCardById(id)
    if card.type ~= Card.TypeEquip then return end
    if not (target:canUseTo(card, target) and room:askToSkillInvoke(target, { skill_name = "shiju", prompt = "#shiju-use:"..player.id.."::"..card:toLogString() })) then return end
    local no_draw = table.every(target:getCardIds(Player.Equip), function (cid)
      return Fk:getCardById(cid).sub_type ~= card.sub_type
    end)
    room:useCard({
      from = target.id,
      tos = { {target.id} },
      card = card,
    })
    if not player.dead and not target.dead then
      local x = #target:getCardIds(Player.Equip)
      if x > 0 then
        x = x + player:getMark("shiju-turn")
        room:setPlayerMark(player, "shiju-turn", x)
        room:setPlayerMark(player, "@shiju-turn", "+" .. tostring(x))
      end
    end
    if no_draw then return end
    if not target.dead then
      room:drawCards(target, 2, shiju_active.name)
    end
    if not player.dead then
      room:drawCards(player, 2, shiju_active.name)
    end
  end,
})

return shiju_active
