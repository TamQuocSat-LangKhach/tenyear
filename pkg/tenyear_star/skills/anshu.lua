local anshu = fk.CreateSkill {
  name = "anshu",
}

Fk:loadTranslationTable{
  ['anshu'] = '安庶',
  ['#anshu-use'] = '安庶：是否视为使用【五谷丰登】？',
  ['#anshu-draw'] = '安庶：你可以令这些角色将手牌摸至体力上限（最多摸至五张）',
  ['#anshu-choose'] = '安庶：选择一名角色，从其开始结算此【五谷丰登】',
  [':anshu'] = '每轮结束时，你可以将弃牌堆中牌名不同的基本牌各一张置于牌堆顶，然后视为使用一张【五谷丰登】，你选择从你或一名已受伤角色开始结算此【五谷丰登】。直到下轮结束，若有角色失去了因此【五谷丰登】选择的牌，当前回合结束时你可以令其将手牌摸至体力上限（最多摸至五张）。',
  ['$anshu1'] = '春种其粟，秋得其实。',
  ['$anshu2'] = '与民休养生息，则国可得安泰。',
}

anshu:addEffect(fk.RoundEnd, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(skill.name) then
      return true
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    return room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#anshu-use",
    })
  end,
  on_use = function(self, event, target, player)
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
        poxi_type = skill.name,
        data = card_data,
        cancelable = false,
      })
      ret = table.reverse(ret)
      room:moveCards({
        ids = ret,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skill_name = skill.name,
      })
    end
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return not player:isProhibited(p, Fk:cloneCard("amazing_grace"))
    end)
    if #targets == 0 then return end
    local tos = table.map(table.filter(targets, function (p)
      return p:isWounded()
    end), Util.IdMapper)
    if table.contains(targets, player) then
      table.insertIfNeed(tos, player.id)
    end
    local card = Fk:cloneCard("amazing_grace")
    card.skillName = skill.name
    local use = {
      from = player.id,
      card = card,
    }
    if #tos > 0 then
      use.extra_data = {}
      use.extra_data.anshu_start = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        prompt = "#anshu-choose",
        skill_name = skill.name,
        cancelable = false,
      })[1]
    end
    room:useCard(use)
  end,
})

anshu:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(skill.name) then
      return table.find(player:getTableMark("anshu-turn"), function (id)
        local p = player.room:getPlayerById(id)
        return not p.dead and p:getHandcardNum() < math.min(p.maxHp, 5)
      end)
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(player:getTableMark("anshu-turn"), function (id)
      local p = room:getPlayerById(id)
      return not p.dead and p:getHandcardNum() < math.min(p.maxHp, 5)
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 10,
      prompt = "#anshu-draw",
      skill_name = skill.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(skill, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:sortPlayersByAction(event:getCostData(skill).tos)
    for _, id in ipairs(event:getCostData(skill).tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local n = math.min(p.maxHp, 5) - p:getHandcardNum()
        if n > 0 then
          p:drawCards(n, skill.name)
        end
      end
    end
  end,
})

anshu:addEffect(fk.BeforeCardUseEffect, {
  can_refresh = function(self, event, target, player)
    return target == player and data.extra_data and data.extra_data.anshu_start
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local new_tos = {}
    local n = 0
    for i, info in ipairs(data.tos) do
      if info[1] == data.extra_data.anshu_start then
        table.insert(new_tos, info)
        n = i
      end
      if n > 0 and i > n then
        table.insert(new_tos, info)
      end
    end
    for i, info in ipairs(data.tos) do
      if i < n then
        table.insert(new_tos, info)
      end
    end
    data.tos = new_tos
  end,
})

anshu:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player)
    return target == player and table.contains(data.card.skillNames, skill.name) and data.extra_data and data.extra_data.AGResult
  end,
  on_refresh = function(self, event, target, player)
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
  can_refresh = function(self, event, target, player)
    if player:getTableMark("anshu_record") ~= 0 then
      local mark = player:getTableMark("anshu_record")
      for _, move in ipairs(data) do
        if move.from and mark[string.format("%.0f", move.from)] then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local mark = player:getTableMark("anshu_record")
    for _, move in ipairs(data) do
      if move.from and mark[string.format("%.0f", move.from)] then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and table.removeOne(mark[string.format("%.0f", move.from)], info.cardId) then
            room:addTableMark(player, "anshu-turn", move.from)
          end
        end
      end
    end
    room:setPlayerMark(player, "anshu_record", mark)
  end,
})

anshu:addEffect(fk.RoundEnd, {
  can_refresh = function(self, event, target, player)
    return player:getTableMark("anshu_record") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "anshu_record", 0)
  end,
})

return anshu
