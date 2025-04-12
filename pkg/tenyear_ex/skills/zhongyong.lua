local zhongyong = fk.CreateSkill {
  name = "ty_ex__zhongyong",
}

Fk:loadTranslationTable{
  ["ty_ex__zhongyong"] = "忠勇",
  [":ty_ex__zhongyong"] = "当你使用【杀】结算结束后，你可以将此【杀】和响应此【杀】的【闪】交给另一名其他角色，然后若你交给的牌中包含："..
  "红色牌，其可以对你攻击范围内的一名角色使用一张【杀】；黑色牌，其摸一张牌。",

  ["#ty_ex__zhongyong-choose"] = "忠勇：你可以将此【杀】和响应的【闪】交给另一名角色",
  ["#ty_ex__zhongyong-slash"] = "忠勇：你可以对 %dest 攻击范围内一名角色使用一张【杀】",

  ["$ty_ex__zhongyong1"] = "赤兔北奔，马踏鼠胆之辈！",
  ["$ty_ex__zhongyong2"] = "青龙夜照，刀斩悖主之贼！"
}

zhongyong:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhongyong.name) and data.card.trueName == "slash" then
      local ids = player.room:getSubcardsByRule(data.card, { Card.Processing })
      if data.cardsResponded then
        for _, c in ipairs(data.cardsResponded) do
          table.insertTableIfNeed(ids, player.room:getSubcardsByRule(c, { Card.DiscardPile }))
        end
      end
      if #ids > 0 and
        table.find(player.room:getOtherPlayers(player, false), function (p)
          return not table.contains(data.tos, p)
        end) then
        event:setCostData(self, {cards = ids})
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not table.contains(data.tos, p)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__zhongyong-choose",
      skill_name = zhongyong.name
    })
    if #to > 0 then
      event:setCostData(self, {tos = to, cards = event:getCostData(self).cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local ids = event:getCostData(self).cards
    room:moveCardTo(ids, Card.PlayerHand, to, fk.ReasonGive, zhongyong.name, nil, true, player)
    if to.dead then return end
    if table.find(ids, function(id)
      return Fk:getCardById(id).color == Card.Black
    end) then
      to:drawCards(1, zhongyong.name)
    end
    if to.dead or player.dead then return end
    if table.find(ids, function(id)
      return Fk:getCardById(id).color == Card.Red
    end) then
      local targets = table.filter(room.alive_players, function(p)
        return player:inMyAttackRange(p) and to ~= p
      end)
      if #targets == 0 then return end
      local use = room:askToUseCard(to, {
        skill_name = zhongyong.name,
        pattern = "slash",
        prompt = "#ty_ex__zhongyong-slash::"..player.id,
        cancelable = true,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          exclusive_targets = table.map(targets, Util.IdMapper),
        }
      })
      if use then
        use.extraUse = true
        room:useCard(use)
      end
    end
  end,
})

return zhongyong
