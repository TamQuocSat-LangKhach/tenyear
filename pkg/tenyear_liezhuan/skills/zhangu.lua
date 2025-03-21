local zhangu = fk.CreateSkill {
  name = "zhangu"
}

Fk:loadTranslationTable{
  ['zhangu'] = '战孤',
  [':zhangu'] = '锁定技，回合开始时，若你体力上限大于1且没有手牌或装备区没有牌，你减1点体力上限，然后从牌堆中随机获得三张不同类别的牌。',
  ['$zhangu1'] = '孤军奋战，独破众将。',
  ['$zhangu2'] = '雄狮搏兔，何须援乎？',
}

zhangu:addEffect(fk.TurnStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhangu.name) and player.maxHp > 1 and (player:isKongcheng() or #player:getCardIds("e") == 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    local types = {"basic", "trick", "equip"}
    local cards = {}
    while #types > 0 do
      local pattern = table.random(types)
      table.removeOne(types, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|"..pattern))
    end
    if #cards > 0 then
      room:obtainCard(player.id, cards, false, fk.ReasonJustMove)
    end
  end,
})

return zhangu
