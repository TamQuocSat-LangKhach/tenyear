local yachai = fk.CreateSkill {
  name = "yachai"
}

Fk:loadTranslationTable{
  ['yachai'] = '崖柴',
  ['#yachai-invoke'] = '崖柴：是否对 %dest 发动“崖柴”？',
  ['yachai2'] = '你本回合不能使用手牌，其摸两张牌',
  ['yachai1'] = '弃置一半手牌',
  ['yachai3'] = '展示所有手牌并交给其一种花色的所有手牌',
  ['#yachai-choice'] = '崖柴：选择 %src 令你执行的一项',
  ['@@yachai-turn'] = '崖柴',
  ['#yachai-give'] = '崖柴：选择交给 %src 的花色',
  [':yachai'] = '当你受到伤害后，你可以令伤害来源选择一项：1.弃置一半手牌（向上取整）；2.其本回合不能再使用手牌，你摸两张牌；3.展示所有手牌，然后交给你一种花色的所有手牌。',
  ['$yachai1'] = '才秀知名，无所顾惮。',
  ['$yachai2'] = '讲论经义，为万世法。',
}

yachai:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yachai.name) and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = yachai.name, prompt = "#yachai-invoke::" .. data.from.id})
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.from.id})
    local choices = {"yachai2"}
    if not data.from:isKongcheng() then
      table.insert(choices, 1, "yachai1")
      table.insert(choices, 3, "yachai3")
    end
    local choice = room:askToChoice(data.from, {choices = choices, skill_name = yachai.name, prompt = "#yachai-choice:" .. player.id, all_choices = {"yachai1", "yachai2", "yachai3"}})
    if choice == "yachai1" then
      local n = (data.from:getHandcardNum() + 1) // 2
      room:askToDiscard(data.from, {min_num = n, max_num = n, skill_name = yachai.name})
    elseif choice == "yachai2" then
      room:setPlayerMark(data.from, "@@yachai-turn", 1)
      player:drawCards(2, yachai.name)
    elseif choice == "yachai3" then
      data.from:showCards(data.from:getCardIds("h"))
      if player.dead or data.from.dead then return end
      local ids = data.from:getCardIds("h")
      local suits = {}
      for _, id in ipairs(ids) do
        if Fk:getCardById(id).suit ~= Card.NoSuit then
          table.insertIfNeed(suits, Fk:getCardById(id):getSuitString(true))
        end
      end
      if #ids == 0 then return end
      choice = room:askToChoice(data.from, {choices = suits, skill_name = yachai.name, prompt = "#yachai-give:" .. player.id})
      local cards = table.filter(ids, function(id) return Fk:getCardById(id):getSuitString(true) == choice end)
      room:obtainCard(player.id, cards, true, fk.ReasonGive)
    end
  end,
})

local yachai_prohibit = fk.CreateSkill {
  name = "#yachai_prohibit"
}

yachai_prohibit:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    return player:getMark("@@yachai-turn") > 0 and card and table.contains(player:getCardIds("h"), card:getEffectiveId())
  end,
})

return yachai
