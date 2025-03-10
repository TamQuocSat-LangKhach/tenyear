local cuijian = fk.CreateSkill {
  name = "cuijian"
}

Fk:loadTranslationTable{
  ['cuijian'] = '摧坚',
  ['cuijian_give'] = '，然后你交给其等量的牌',
  ['tongyuan1'] = '没闪摸牌',
  ['cuijian_draw'] = '；若其没有【闪】，你摸两张牌',
  ['tongyuan2'] = '不用给牌',
  ['#cuijian-active'] = '发动 摧坚，选择一名有手牌的其他角色',
  ['#cuijian-card'] = '摧坚：交给 %dest %arg张牌',
  [':cuijian'] = '出牌阶段限一次，你可以选择一名有手牌的其他角色，若其手牌中有【闪】，其将所有【闪】和防具牌交给你，然后你交给其等量的牌。',
  ['$cuijian1'] = '所当皆披靡，破坚若无人！',
  ['$cuijian2'] = '一枪定顽敌，一骑破坚城！'
}

cuijian:addEffect("active", {
  anim_type = "control",
  dynamic_desc = function(self, player)
    local texts = {"cuijian_inner", "cuijian_give", ""}
    if player:getMark("tongyuan1") > 0 then
      texts[3] = "cuijian_draw"
    end
    if player:getMark("tongyuan2") > 0 then
      texts[2] = ""
    end
    return table.concat(texts, ":")
  end,
  prompt = "#cuijian-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(cuijian.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = table.filter(target:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == "jink" end)
    if #cards == 0 then
      if player:getMark("tongyuan1") ~= 0 then
        room:drawCards(player, 2, cuijian.name)
      end
    else
      table.insertTable(cards, table.filter(target:getCardIds("he"), function(id)
        return Fk:getCardById(id).sub_type == Card.SubtypeArmor
      end))
      local x = #cards
      room:obtainCard(player, cards, true, fk.ReasonGive, target.id, cuijian.name)
      if player.dead or player:isNude() or player:getMark("tongyuan2") ~= 0 or target.dead then return end
      cards = player:getCardIds({Player.Hand, Player.Equip})
      if #cards > x then
        cards = room:askToDiscard(player, {
          min_num = x,
          max_num = x,
          include_equip = true,
          skill_name = cuijian.name,
          cancelable = false,
          pattern = ".",
          prompt = "#cuijian-card::" .. target.id .. ":" .. tostring(x),
        })
      end
      room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, cuijian.name, nil, false, player.id)
    end
  end,
})

return cuijian
