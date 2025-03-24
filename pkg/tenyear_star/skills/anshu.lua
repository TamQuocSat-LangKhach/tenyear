local anshu = fk.CreateSkill {
  name = "anshu",
}

Fk:loadTranslationTable{
  ["anshu"] = "安庶",
  [":anshu"] = "每轮结束时，你可以将弃牌堆中牌名不同的基本牌各一张置于牌堆顶，然后视为使用一张【五谷丰登】，你选择从你或一名已受伤角色"..
  "开始结算此【五谷丰登】。直到下轮结束，若有角色失去了因此【五谷丰登】选择的牌，当前回合结束时你可以令其将手牌摸至体力上限（最多摸至五张）。",

  ["#anshu-use"] = "安庶：是否视为使用【五谷丰登】？",
  ["#anshu-draw"] = "安庶：你可以令这些角色将手牌摸至体力上限（最多摸至五张）",
  ["#anshu_put"] = "安庶：将每种牌名各一张牌置于牌堆顶（按选择的顺序从上到下放置）",
  ["#anshu-choose"] = "安庶：选择一名角色，从其开始结算此【五谷丰登】",

  ["$anshu1"] = "春种其粟，秋得其实。",
  ["$anshu2"] = "与民休养生息，则国可得安泰。",
}

Fk:addPoxiMethod{
  name = "anshu",
  card_filter = function (to_select, selected, data, extra_data)
    return not table.find(selected, function (id)
      return Fk:getCardById(id).trueName == Fk:getCardById(to_select).trueName
    end)
  end,
  feasible = function(selected, data)
    if data and #data == #selected then
      local areas = {}
      for _, id in ipairs(selected) do
        for _, v in ipairs(data) do
          if table.contains(v[2], id) then
            table.insertIfNeed(areas, v[2])
            break
          end
        end
      end
      return #areas == #selected
    end
  end,
  prompt = "#anshu_put",
  default_choice = function(data)
    if not data then return {} end
    local cids = table.map(data, function(v) return v[2][1] end)
    return cids
  end,
}

anshu:addEffect(fk.RoundEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(anshu.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = anshu.name,
      prompt = "#anshu-use",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, id in ipairs(room.discard_pile) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic then
        cards[card.trueName] = cards[card.trueName] or {}
        table.insert(cards[card.trueName], id)
      end
    end
    if next(cards) ~= nil then
      local card_data = {}
      for _, name in ipairs({"slash", "jink", "peach", "analeptic"}) do  --按杀闪桃酒顺序排列
        if cards[name] then
          table.insert(card_data, {name, cards[name]})
        end
      end
      for name, ids in pairs(cards) do
        if not table.contains({"slash", "jink", "peach", "analeptic"}, name) and #ids > 0 then  --其他基本牌按牌名排列
          table.insert(card_data, {name, ids})
        end
      end
      local ret = room:askToPoxi(player, {
        poxi_type = anshu.name,
        data = card_data,
        cancelable = false,
      })
      ret = table.reverse(ret)
      room:moveCards({
        ids = ret,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skill_name = anshu.name,
      })
    end
    local targets = table.filter(room.alive_players, function (p)
      return not player:isProhibited(p, Fk:cloneCard("amazing_grace"))
    end)
    if #targets == 0 then return end
    local tos = table.filter(targets, function (p)
      return p:isWounded()
    end)
    if table.contains(targets, player) then
      table.insertIfNeed(tos, player)
    end
    local card = Fk:cloneCard("amazing_grace")
    card.skillName = anshu.name
    local use = {
      from = player,
      card = card,
      tos = targets,
    }
    if #tos > 0 then
      use.extra_data = {}
      local to = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        prompt = "#anshu-choose",
        skill_name = anshu.name,
        cancelable = false,
      })[1]
      use.extra_data.anshu_start = to
    end
    room:useCard(use)
  end,

  can_refresh = function(self, event, target, player, data)
    return player:getTableMark("anshu_record") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "anshu_record", 0)
  end,
})

anshu:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(anshu.name) then
      return table.find(player:getTableMark("anshu-turn"), function (id)
        local p = player.room:getPlayerById(id)
        return not p.dead and p:getHandcardNum() < math.min(p.maxHp, 5)
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player:getTableMark("anshu-turn"), function (id)
      local p = room:getPlayerById(id)
      return not p.dead and p:getHandcardNum() < math.min(p.maxHp, 5)
    end)
    local tos = room:askToChoosePlayers(player, {
      skill_name = anshu.name,
      min_num = 1,
      max_num = 10,
      targets = table.map(targets, Util.Id2PlayerMapper),
      prompt = "#anshu-draw",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        local n = math.min(p.maxHp, 5) - p:getHandcardNum()
        if n > 0 then
          p:drawCards(n, anshu.name)
        end
      end
    end
  end,
})

anshu:addEffect(fk.BeforeCardUseEffect, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.extra_data and data.extra_data.anshu_start
  end,
  on_refresh = function(self, event, target, player, data)
    local new_tos = {}
    local n = 0
    for i, p in ipairs(data.tos) do
      if p == data.extra_data.anshu_start then
        table.insert(new_tos, p)
        n = i
      end
      if n > 0 and i > n then
        table.insert(new_tos, p)
      end
    end
    for i, p in ipairs(data.tos) do
      if i < n then
        table.insert(new_tos, p)
      end
    end
    data.tos = new_tos
  end,
})

anshu:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, anshu.name) and data.extra_data and data.extra_data.AGResult
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = {}
    for _, dat in ipairs(data.extra_data.AGResult) do
      local to = room:getPlayerById(dat[1])
      if not to.dead and table.contains(to:getCardIds("h"), dat[2]) then
        mark[string.format("%.0f", to.id)] = mark[string.format("%.0f", to.id)] or {}
        table.insert(mark[string.format("%.0f", to.id)], dat[2])
      end
    end
    room:setPlayerMark(player, "anshu_record", mark)
  end,
})

anshu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player:getTableMark("anshu_record") ~= 0 then
      local mark = player:getTableMark("anshu_record")
      for _, move in ipairs(data) do
        if move.from and mark[string.format("%.0f", move.from.id)] then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("anshu_record")
    for _, move in ipairs(data) do
      if move.from and mark[string.format("%.0f", move.from.id)] then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and table.removeOne(mark[string.format("%.0f", move.from.id)], info.cardId) then
            room:addTableMark(player, "anshu-turn", move.from.id)
          end
        end
      end
    end
    room:setPlayerMark(player, "anshu_record", mark)
  end,
})

return anshu
