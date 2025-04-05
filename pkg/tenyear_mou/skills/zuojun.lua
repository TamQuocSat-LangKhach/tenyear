local zuojun = fk.CreateSkill {
  name = "zuojun",
}

Fk:loadTranslationTable{
  ["zuojun"] = "佐军",
  [":zuojun"] = "出牌阶段限一次，你可以选择一名角色，其摸三张牌并选择：1.直到其下个回合结束，其不能使用这些牌且不计入其手牌上限；"..
  "2.失去1点体力再摸一张牌，然后使用其中任意张牌，弃置剩余的牌。",

  ["#zuojun"] = "佐军：令一名角色摸三张牌，然后其执行后续效果",
  ["zuojun1"] = "这些牌无法使用且不计入手牌上限直到你下回合结束",
  ["zuojun2"] = "失去1点体力再摸一张牌，然后使用其中任意张，弃置剩余牌",
  ["@@zuojun_prohibit-inhand"] = "佐军",
  ["@@zuojun-inhand"] = "佐军",
  ["#zuojun-use"] = "佐军：请使用这些牌，未使用的将被弃置",

  ["$zuojun1"] = "彼不得安，我取其逸，则大局可定。",
  ["$zuojun2"] = "义者无敌，骄者先败，今非用兵之时。",
}

zuojun:addEffect("active", {
  anim_type = "support",
  prompt = "#zuojun",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zuojun.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = effect.tos[1]
    target:drawCards(3, zuojun.name, "top", "zuojun-inhand")
    if target.dead then return end
    local choice = room:askToChoice(target, {
      choices = {"zuojun1", "zuojun2"},
      skill_name = zuojun.name,
    })
    if choice == "zuojun1" then
      local card
      local cards = table.filter(target:getCardIds("h"), function (id)
        card = Fk:getCardById(id)
        if card:getMark("zuojun-inhand") > 0 then
          room:setCardMark(card, "zuojun-inhand", 0)
          room:setCardMark(card, "@@zuojun_prohibit-inhand", 1)
          return true
        end
      end)
      if #cards > 0 then
        local mark = target:getTableMark("zuojun_prohibit")
        table.insertTableIfNeed(mark, cards)
        room:setPlayerMark(target, "zuojun_prohibit", mark)
        if room.current == target then
          mark = target:getTableMark("zuojun_noclean-turn")
          table.insertTableIfNeed(mark, cards)
          room:setPlayerMark(target, "zuojun_noclean-turn", mark)
        end
      end
    else
      room:loseHp(target, 1, zuojun.name)
      if target.dead then return end
      target:drawCards(1, zuojun.name, "top", "zuojun-inhand")
      if target.dead then return end
      local card
      local cards = table.filter(target:getCardIds(Player.Hand), function (id)
        card = Fk:getCardById(id)
        if card:getMark("zuojun-inhand") > 0 then
          room:setCardMark(card, "zuojun-inhand", 0)
          room:setCardMark(card, "@@zuojun-inhand", 1)
          return true
        end
      end)
      if #cards == 0 then return false end
      while room:askToUseRealCard(target, {
        pattern = cards,
        skill_name = zuojun.name,
        prompt = "#zuojun-use",
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
      }) do
        if target.dead then return end
        cards = table.filter(target:getCardIds(Player.Hand), function (id)
          return Fk:getCardById(id):getMark("@@zuojun-inhand") > 0
        end)
        if #cards == 0 then return end
      end
      cards = table.filter(cards, function (id)
        card = Fk:getCardById(id)
        room:setCardMark(card, "@@zuojun-inhand", 1)
        return not target:prohibitDiscard(card)
      end)
      if #cards > 0 then
        room:throwCard(cards, zuojun.name, target, target)
      end
    end
  end,
})

zuojun:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("zuojun_prohibit") ~= 0 then
      local cards = card:isVirtual() and card.subcards or {card.id}
      return table.find(cards, function(id)
        return table.contains(player:getTableMark("zuojun_prohibit"), id)
      end)
    end
  end,
})

zuojun:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return table.contains(player:getTableMark("zuojun_prohibit"), card.id)
  end,
})

zuojun:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("zuojun_prohibit") ~= player:getMark("zuojun_noclean-turn")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("zuojun_noclean-turn")
    local card
    for _, id in ipairs(player:getCardIds("h")) do
      card = Fk:getCardById(id)
      if card:getMark("@@zuojun_prohibit-inhand") > 0 and not table.contains(mark, id) then
        room:setCardMark(card, "@@zuojun_prohibit-inhand", 0)
      end
    end
    room:setPlayerMark(player, "zuojun_prohibit", player:getMark("zuojun_noclean-turn"))
  end,
})

return zuojun
