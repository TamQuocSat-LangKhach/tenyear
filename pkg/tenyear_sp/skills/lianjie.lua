local lianjie = fk.CreateSkill {
  name = "lianjie",
}

Fk:loadTranslationTable{
  ["lianjie"] = "连捷",
  [":lianjie"] = "当你使用手牌指定目标后，若你没有点数小于此牌的手牌（无点数视为0），你可以将一名角色手牌中随机一张点数最小的牌"..
  "置于牌堆底（每回合每名角色限一次），若如此做，你将手牌摸至体力上限，本回合使用以此法摸到的牌无距离次数限制。",

  ["#lianjie-choose"] = "连捷：将一名角色点数最小的手牌置于牌堆底，你摸牌至体力上限",
  ["@@lianjie-inhand-turn"] = "连捷",
}

lianjie:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianjie.name) and data.firstTarget and
      data.use:IsUsingHandcard(player) and
      not table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).number < data.card.number
      end) and
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng() and not table.contains(player:getTableMark("lianjie-turn"), p.id)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng() and not table.contains(player:getTableMark("lianjie-turn"), p.id)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = lianjie.name,
      prompt = "#lianjie-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMark(player, "lianjie-turn", to.id)
    local cards = table.filter(to:getCardIds("h"), function (id)
      return table.every(to:getCardIds("h"), function (id2)
        return Fk:getCardById(id).number <= Fk:getCardById(id2).number
      end)
    end)
    room:moveCards {
      ids = table.random(cards, 1),
      from = to,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = lianjie.name,
      proposer = player,
      moveVisible = true,
      drawPilePosition = -1
    }
    if player.dead then return end
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, lianjie.name, nil, "@@lianjie-inhand-turn")
    end
  end,
})

lianjie:addEffect("targetmod", {
  bypass_times = function(self, player, skill_name, scope, card, to)
    return card and card:getMark("@@lianjie-inhand-turn") > 0
  end,
  bypass_distances = function(self, player, skill_name, card)
    return card and card:getMark("@@lianjie-inhand-turn") > 0
  end,
})

return lianjie
