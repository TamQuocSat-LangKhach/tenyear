local qiangzhiz = fk.CreateSkill {
  name = "qiangzhiz",
}

Fk:loadTranslationTable{
  ["qiangzhiz"] = "强峙",
  [":qiangzhiz"] = "出牌阶段限一次，你可以弃置你和一名其他角色共计三张牌。若有角色因此弃置三张牌，其对另一名角色造成1点伤害。",

  ["#qiangzhiz"] = "强峙：弃置你和一名角色共计三张牌，被弃置三张牌的角色对对方造成1点伤害",
  ["#qiangzhiz-discard"] = "强峙：弃置双方共计三张牌，被弃置三张牌的角色对对方造成1点伤害",

  ["$qiangzhiz1"] = "吾民在后，岂惧尔等魍魉。",
  ["$qiangzhiz2"] = "凶兵来袭，当长戈相迎。",
}

Fk:addPoxiMethod{
  name = "qiangzhiz",
  prompt = "#qiangzhiz-discard",
  card_filter = function(to_select, selected, data, extra_data)
    return #selected < 3 and not table.contains(extra_data.prohibit, to_select)
  end,
  feasible = function(selected, data)
    return #selected == 3
  end,
  default_choice = function (data, extra_data)
    local all_cards = {}
    for _, v in ipairs(data) do
      for _, id in ipairs(v[2]) do
        if not table.contains(extra_data.prohibit, id) then
          table.insert(all_cards, id)
        end
      end
    end
    return table.random(all_cards, 3)
  end,
}

qiangzhiz:addEffect("active", {
  anim_type = "offensive",
  prompt = "#qiangzhiz",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(qiangzhiz.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and
      #to_select:getCardIds("he") + #table.filter(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end) > 2
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local card_data, extra_data, visible_data = {}, { prohibit = {} }, {}
    if not target:isKongcheng() then
      table.insert(card_data, { target.general, target:getCardIds("h") })
      for _, id in ipairs(target:getCardIds("h")) do
        if not player:cardVisible(id) then
          visible_data[tostring(id)] = false
        end
      end
      if next(visible_data) == nil then visible_data = nil end
      extra_data.visible_data = visible_data
    end
    if #target:getCardIds("e") > 0 then
      table.insert(card_data, { Fk:translate(target.general).." ", target:getCardIds("e") })
    end
    if not player:isKongcheng() then
      table.insert(card_data, { player.general, player:getCardIds("h") })
      local cards = table.filter(player:getCardIds("h"), function(id)
        return player:prohibitDiscard(id)
      end)
      extra_data.prohibit = cards
    end
    if #player:getCardIds("e") > 0 then
      table.insert(card_data, { Fk:translate(player.general).." ", player:getCardIds("e") })
    end
    local result = room:askToPoxi(player, {
      poxi_type = qiangzhiz.name,
      data = card_data,
      cancelable = false,
      extra_data = extra_data,
    })
    local cards1 = table.filter(result, function(id)
      return table.contains(player:getCardIds("he"), id)
    end)
    local cards2 = table.filter(result, function(id)
      return table.contains(target:getCardIds("he"), id)
    end)
    local moves = {}
    if #cards1 > 0 then
      table.insert(moves, {
        from = player,
        ids = cards1,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = player,
        skillName = qiangzhiz.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moves, {
        from = target,
        ids = cards2,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = player,
        skillName = qiangzhiz.name,
      })
    end
    room:moveCards(table.unpack(moves))
    if not player.dead and not target.dead then
      if #cards1 == 3 then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = qiangzhiz.name,
        }
      elseif #cards2 == 3 then
        room:damage{
          from = target,
          to = player,
          damage = 1,
          skillName = qiangzhiz.name,
        }
      end
    end
  end,
})

return qiangzhiz
