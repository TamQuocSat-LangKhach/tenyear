local jieshu = fk.CreateSkill {
  name = "jieshu"
}

Fk:loadTranslationTable{
  ['jieshu'] = '解术',
  ['@[geyuan]'] = '割圆',
  [':jieshu'] = '锁定技，非圆环内点数的牌不计入你的手牌上限。你使用或打出牌时，若满足圆环进度点数，你摸一张牌。',
  ['$jieshu1'] = '累乘除以成九数者，可以加减解之。',
  ['$jieshu2'] = '数有其理，见筹一可知沙数。',
}

jieshu:addEffect(fk.CardUsing, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) and player:getMark("@[geyuan]") ~= 0 then
      local proceed = getCircleProceed(player:getMark("@[geyuan]"))
      return table.contains(proceed, data.card.number)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jieshu.name)
  end,
})

jieshu:addEffect(fk.CardResponding, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) and player:getMark("@[geyuan]") ~= 0 then
      local proceed = getCircleProceed(player:getMark("@[geyuan]"))
      return table.contains(proceed, data.card.number)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jieshu.name)
  end,
})

jieshu:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    if player:hasSkill(jieshu) then
      local mark = player:getMark("@[geyuan]")
      local all = Util.DummyTable
      if type(mark) == "table" and mark.all then all = mark.all end
      return not table.contains(all, card.number)
    end
  end,
})

return jieshu
