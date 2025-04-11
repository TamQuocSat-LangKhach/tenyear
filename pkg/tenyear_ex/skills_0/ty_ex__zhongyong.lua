local ty_ex__zhongyong = fk.CreateSkill {
  name = "ty_ex__zhongyong"
}

Fk:loadTranslationTable{
  ['ty_ex__zhongyong'] = '忠勇',
  ['#ty_ex__zhongyong-choose'] = '忠勇：你可以将【杀】和响应之的【闪】交给另一名其他角色',
  ['#ty_ex__zhongyong-slash'] = '忠勇：你可以对 %dest 攻击范围内一名角色使用一张【杀】',
  [':ty_ex__zhongyong'] = '当你使用的【杀】结算结束后，你可以将此【杀】和响应此【杀】的【闪】交给另一名其他角色，然后若你交给其获得的牌中包含：红色牌，其可以对你攻击范围内的一名角色使用一张【杀】；黑色牌，其摸一张牌。',
  ['$ty_ex__zhongyong1'] = '赤兔北奔，马踏鼠胆之辈！',
  ['$ty_ex__zhongyong2'] = '青龙夜照，刀斩悖主之贼！'
}

ty_ex__zhongyong:addEffect(fk.CardUseFinished, {
  anim_type = "drawCard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty_ex__zhongyong) and target == player and data.card.trueName == "slash" and data.tos then
      local ids = player.room:getSubcardsByRule(data.card, { Card.Processing })
      if data.cardsResponded then
        for _, c in ipairs(data.cardsResponded) do
          table.insertTableIfNeed(ids, player.room:getSubcardsByRule(c, { Card.DiscardPile }))
        end
      end
      return #ids > 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function (p) return not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and p ~= player end)
    if #targets == 0 then return false end
    local tos = player.room:askToChoosePlayers(player, {
      targets = table.map(targets, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__zhongyong-choose",
      skill_name = ty_ex__zhongyong.name
    })
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local ids = player.room:getSubcardsByRule(data.card, { Card.Processing })
    for _, c in ipairs(data.cardsResponded or {}) do
      table.insertTableIfNeed(ids, player.room:getSubcardsByRule(c, { Card.DiscardPile }))
    end

    if #ids < 1 then
      return false
    end

    room:moveCardTo(ids, Card.PlayerHand, to, fk.ReasonGive, ty_ex__zhongyong.name, nil, true, player.id)
    if to.dead then return end
    if table.find(ids, function(id) return Fk:getCardById(id).color == Card.Black end) then
      to:drawCards(1, ty_ex__zhongyong.name)
    end
    if to.dead or player.dead then return end
    if table.find(ids, function(id) return Fk:getCardById(id).color == Card.Red end) then
      local victims = table.filter(room.alive_players, function(p) return player:inMyAttackRange(p) and to ~= p end)
      if #victims == 0 then return end
      local use = room:askToUseCard(to, {
        pattern = "slash",
        prompt = "#ty_ex__zhongyong-slash::"..player.id,
        cancelable = true,
        extra_data = { exclusive_targets = table.map(victims, Util.IdMapper), bypass_distances = true }
      })
      if use then
        use.extraUse = true
        room:useCard(use)
      end
    end
  end,
})

return ty_ex__zhongyong
