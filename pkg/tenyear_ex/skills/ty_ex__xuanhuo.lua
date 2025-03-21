local ty_ex__xuanhuo = fk.CreateSkill {
  name = "ty_ex__xuanhuo"
}

Fk:loadTranslationTable{
  ['ty_ex__xuanhuo'] = '眩惑',
  ['ty_ex__xuanhuo_choose'] = '眩惑',
  ['#ty_ex__xuanhuo-invoke'] = '眩惑：交给第一名角色两张手牌，令其选择视为对第二名角色使用杀或决斗或交给你所有手牌',
  ['ty_ex__xuanhuo_use'] = '使用',
  ['#ty_ex__xuanhuo-choice'] = '眩惑：选择一种牌视为对 %dest 使用，否则交给 %src 所有手牌',
  ['ty_ex__xuanhuo_give'] = '交出所有手牌',
  [':ty_ex__xuanhuo'] = '摸牌阶段结束时，你可以将两张手牌交给一名其他角色A并选择另一名其他角色B，除非A视为对B使用任意一种【杀】或【决斗】，否则A将所有手牌交给你。',
  ['$ty_ex__xuanhuo1'] = '光以眩目，言以惑人。',
  ['$ty_ex__xuanhuo2'] = '我法孝直如何会害你？',
}

ty_ex__xuanhuo:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__xuanhuo) and player.phase == Player.Draw and player:getHandcardNum() > 1
      and #player.room.alive_players > 2
  end,
  on_cost = function(self, event, target, player, data)
    local _, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__xuanhuo_choose",
      prompt = "#ty_ex__xuanhuo-invoke",
      cancelable = true
    })
    if dat then
      event:setCostData(self, { cards = dat.cards, tos = dat.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, ty_ex__xuanhuo.name, nil, false, player.id)
    if to.dead then return end
    local victim = room:getPlayerById(event:getCostData(self).tos[2])
    local cards = {}
    if not victim.dead then
      for _, id in ipairs(U.prepareUniversalCards(room)) do
        local card = Fk:getCardById(id)
        if card.trueName == "slash" or card.trueName == "duel" then
          if to:canUseTo(card, victim, {bypass_times = true, bypass_distances = true}) then
            table.insertIfNeed(cards, id)
          end
        end
      end
    end
    local name
    if #cards > 0 then
      local choices,_ = U.askforChooseCardsAndChoice(to, cards, {"ty_ex__xuanhuo_use"}, ty_ex__xuanhuo.name,
        "#ty_ex__xuanhuo-choice:"..player.id..":"..victim.id, {"ty_ex__xuanhuo_give"}, 1, 1)
      if #choices > 0 then
        name = Fk:getCardById(choices[1]).name
      end
    end
    if name then
      room:useVirtualCard(name, nil, to, victim, ty_ex__xuanhuo.name, true)
    else
      cards = to:getCardIds(Player.Hand)
      if #cards > 0 and not player.dead then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, ty_ex__xuanhuo.name, nil, false, to.id)
      end
    end
  end,
})

return ty_ex__xuanhuo
