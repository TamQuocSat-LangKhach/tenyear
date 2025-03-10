local shiju = fk.CreateSkill {
  name = "shiju"
}

Fk:loadTranslationTable{
  ['shiju'] = '势举',
  ['shiju&'] = '势举',
  ['#shiju_self-active'] = '势举：你可以选择你的一张牌，若此牌为装备牌则使用之并获得收益',
  ['#shiju_self-use'] = '势举：你可以使用%arg，令你增加攻击范围',
  ['@shiju-turn'] = '势举范围',
  [':shiju'] = '一名角色的出牌阶段限一次，其可以将一张牌交给你（若其为你，则改为你选择你的一张牌，若此牌为你装备区里的牌，你获得之），若此牌为装备牌，你可以使用之，并令其攻击范围于此回合内+X（X为你装备区里的牌数），若你于使用此牌之前的装备区里有与此牌副类别相同的牌，你与其各摸两张牌。',
  ['$shiju1'] = '借力为己用，可攀青云直上。',
  ['$shiju2'] = '应势而动，事半而功倍。',
}

shiju:addEffect('active', {
  anim_type = "support",
  attached_skill_name = "shiju&",
  prompt = "#shiju_self-active",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(shiju.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local id = effect.cards[1]
    if room:getCardArea(id) == Card.PlayerEquip then
      room:moveCardTo(effect.cards, Player.Hand, player, fk.ReasonPrey, shiju.name, nil, false, player.id)
    end
    if player.dead or room:getCardArea(id) ~= Card.PlayerHand or room:getCardOwner(id) ~= player then return end
    local card = Fk:getCardById(id)
    if card.type ~= Card.TypeEquip then return end
    if not (player:canUseTo(card, player)) then
      return
    end
    if not room:askToSkillInvoke(player, { skill_name = shiju.name, prompt = "#shiju_self-use:::" .. card:toLogString() }) then
      return
    end
    local no_draw = table.every(player:getCardIds(Player.Equip), function (cid)
      return Fk:getCardById(cid).sub_type ~= card.sub_type
    end)
    room:useCard({
      from = player.id,
      tos = {{ player.id }},
      card = card,
    })
    if player:isAlive() then
      local x = #player:getCardIds(Player.Equip)
      if x > 0 then
        x = x + player:getMark("shiju-turn")
        room:setPlayerMark(player, "shiju-turn", x)
        room:setPlayerMark(player, "@shiju-turn", "+" .. tostring(x))
      end
    end
    if not no_draw and player:isAlive() then
      room:drawCards(player, 2, shiju.name)
      room:drawCards(player, 2, shiju.name)
    end
  end,
})

shiju:addEffect('atkrange', {
  correct_func = function (self, from, to)
    return from:getMark("shiju-turn")
  end,
})

return shiju
