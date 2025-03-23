local zhengyue = fk.CreateSkill {
  name = "zhengyue"
}

Fk:loadTranslationTable{
  ['zhengyue'] = '征越',
  ['#zhengyue'] = '征越',
  ['#zhengyue-invoke'] = '征越：将牌堆顶至多五张牌置为“征越”牌',
  ['@[private]$zhengyue'] = '征越',
  [':zhengyue'] = '回合开始时，若你的武将牌上没有“征越”牌，你可以将牌堆顶至多五张牌以任意顺序置于武将牌上。当你使用牌结算后，若与武将牌上第一张“征越”牌点数或花色或牌名相同，移去第一张“征越”牌并摸两张牌；若皆不同，将此牌置于武将牌上并任意调整顺序（至多5张“征越”牌），当你一回合内以此法将两张牌置为“征越”牌后，你不能使用手牌直到回合结束。',
  ['$zhengyue1'] = '本将军出手，必教尔等蛮夷俯首系颈！',
  ['$zhengyue2'] = '什么山越宗帅，还不是一群土鸡瓦狗！',
}

zhengyue:addEffect(fk.TurnStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) then
      return #player:getPile("#" .. skill.name) == 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    local choice = player.room:askToChoice(player, {choices = {"1", "2", "3", "4", "5"}, skill_name = skill.name})
    if choice ~= "Cancel" then
      event:setCostData(skill, {choice = tonumber(choice)})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local result = room:askToGuanxing(player, {
      cards = room:getNCards(event:getCostData(skill).choice),
      top_limit = {0, 0},
      skill_name = skill.name,
      skip = true,
      area_names = {"#" .. skill.name, ""},
    })
    player:addToPile("#" .. skill.name, result.top, false, skill.name, player.id)
    U.setPrivateMark(player, "$" .. skill.name, result.top)
  end,
})

zhengyue:addEffect(fk.CardUseFinished, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) then
      if #player:getPile("#" .. skill.name) > 0 then
        local c = Fk:getCardById(U.getPrivateMark(player, "$" .. skill.name)[1])
        if c.number == data.card.number or c:compareSuitWith(data.card) or c.trueName == data.card.trueName then
          return true
        else
          return player.room:getCardArea(data.card) == Card.Processing and #player:getPile("#" .. skill.name) < 5
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local c = Fk:getCardById(U.getPrivateMark(player, "$" .. skill.name)[1])
    if c.number == data.card.number or c:compareSuitWith(data.card) or c.trueName == data.card.trueName then
      room:moveCardTo(c, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skill.name, nil, true, player.id)
      if not player.dead then
        player:drawCards(2, skill.name)
      end
      if #player:getPile("#" .. skill.name) == 0 then
        room:setPlayerMark(player, "@[private]$" .. skill.name, 0)
      else
        U.setPrivateMark(player, "$" .. skill.name, player:getPile("#" .. skill.name))
      end
    else
      room:addPlayerMark(player, "zhengyue-turn", 1)
      local cards = table.simpleClone(player:getPile("#" .. skill.name))
      for i = 1, 5 - #cards, 1 do
        table.insert(cards, Card:getIdList(data.card)[i])
      end
      local result = room:askToGuanxing(player, {
        cards = cards,
        top_limit = {0, 0},
        skill_name = skill.name,
        skip = true,
        area_names = {"#" .. skill.name, ""},
      })
      cards = table.filter(result.top, function (id)
        return not table.contains(player:getPile("#" .. skill.name), id)
      end)
      player:addToPile("#" .. skill.name, cards, false, skill.name, player.id)
      --player.special_cards["#" .. skill.name] = result.top  --FIXME: 危险！！！
      U.setPrivateMark(player, "$" .. skill.name, result.top)
    end
  end,
})

zhengyue:addEffect("on_lose", {
  on_lose = function (skill, player, is_death)
    local room = player.room
    room:setPlayerMark(player, "@[private]$" .. skill.name, 0)
    room:moveCardTo(player:getPile("#" .. skill.name), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, "", nil, true)
  end,
})

local zhengyue_prohibit = fk.CreateSkill {
  name = "#" .. zhengyue.name .. "_prohibit"
}

zhengyue_prohibit:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("zhengyue-turn") > 1 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})

return zhengyue
