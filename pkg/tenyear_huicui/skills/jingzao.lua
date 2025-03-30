local jingzao = fk.CreateSkill {
  name = "jingzao",
}

Fk:loadTranslationTable{
  ["jingzao"] = "经造",
  [":jingzao"] = "出牌阶段每名角色限一次，你可以选择一名其他角色并亮出牌堆顶三张牌，然后该角色选择一项：1.弃置一张与亮出牌同名的牌，"..
  "然后此技能本回合亮出的牌数+1；2.令你随机获得这些牌中牌名不同的牌各一张，每获得一张，此技能本回合亮出的牌数-1。",

  ["#jingzao"] = "经造：选择一名角色，亮出牌堆顶的%arg张牌，其需弃牌或令你获得其中的牌",
  ["#jingzao-discard"] = "经造：弃置一张同名牌使本回合“经造”亮出牌+1，或点“取消”令 %src 获得其中不同牌名各一张",

  ["$jingzao1"] = "闭门绝韦编，造经教世人。",
  ["$jingzao2"] = "著文成经，可教万世之人。",
}

jingzao:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player)
    return "#jingzao:::" + (3 + player:getMark("jingzao-turn"))
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("jingzao-turn") > -3
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not table.contains(player:getTableMark("jingzao-phase"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "jingzao-phase", target.id)
    local n = 3 + player:getMark("jingzao-turn")
    local cards = room:getNCards(n)
    room:turnOverCardsFromDrawPile(player, cards, jingzao.name)
    local pattern = table.concat(table.map(cards, function(id)
      return Fk:getCardById(id).trueName
    end), ",")
    if #room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = jingzao.name,
      cancelable = true,
      pattern = pattern,
      prompt = "#jingzao-discard:"..player.id,
    }) > 0 then
      if not player.dead then
        room:addPlayerMark(player, "jingzao-turn", 1)
      end
    else
      local to_get = {}
      while #cards > 0 do
        local id = table.random(cards)
        table.insert(to_get, id)
        cards = table.filter(cards, function (id2)
          return Fk:getCardById(id2).trueName ~= Fk:getCardById(id).trueName
        end)
      end
      room:setPlayerMark(player, "jingzao-turn", player:getMark("jingzao-turn") - #to_get)
      room:moveCardTo(to_get, Player.Hand, player, fk.ReasonJustMove, jingzao.name, nil, true, player)
    end
    room:cleanProcessingArea(cards, jingzao.name)
  end,
})

return jingzao
