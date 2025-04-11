local ty_ex__zhiyan = fk.CreateSkill {
  name = "ty_ex__zhiyan"
}

Fk:loadTranslationTable{
  ['ty_ex__zhiyan'] = '直言',
  ['#ty_ex__zhiyan-choose'] = '直言：你可以令一名角色摸一张牌并展示之，若为装备牌其使用之并回复1点体力',
  [':ty_ex__zhiyan'] = '结束阶段，你可以令一名角色摸一张牌并展示之，若此牌为：基本牌，你摸一张牌；装备牌，其使用此牌并回复1点体力。',
  ['$ty_ex__zhiyan1'] = '此事，臣有一言要讲。',
  ['$ty_ex__zhiyan2'] = '还望将军听我一言。',
}

ty_ex__zhiyan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__zhiyan.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getAlivePlayers(), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__zhiyan-choose",
      skill_name = ty_ex__zhiyan.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local id = to:drawCards(1, ty_ex__zhiyan.name)[1]
    local card = Fk:getCardById(id)
    to:showCards(card)
    room:delay(1000)
    if card.type == Card.TypeBasic and not player.dead then
      player:drawCards(1, ty_ex__zhiyan.name)
    end
    if card.type == Card.TypeEquip and not to.dead and to:canUseTo(card, to, { bypass_times = true, bypass_distances = true }) then
      room:useCard({
        from = to.id,
        tos = { {to.id} },
        card = card,
      })
      if to:isWounded() and not to.dead then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = ty_ex__zhiyan.name
        })
      end
    end
  end,
})

return ty_ex__zhiyan
