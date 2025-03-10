local jidi = fk.CreateSkill {
  name = "jidi"
}

Fk:loadTranslationTable{
  ['jidi'] = '觊嫡',
  [':jidi'] = '锁定技，体力值大于你的角色对你造成伤害时，其失去1点体力；手牌数大于你的角色对你造成伤害时，其随机弃置两张牌。',
  ['$jidi1'] = '这太子之位，他孙和坐得，我亦坐得！',
  ['$jidi2'] = '自古唯贤愚之分，无庶嫡之别！',
}

jidi:addEffect(fk.DamageInflicted, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jidi.name) and data.from and
      (data.from.hp > player.hp or data.from:getHandcardNum() > player:getHandcardNum())
  end,
  on_use = function (skill, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.from.id})
    local choices = {}
    if data.from.hp > player.hp then
      table.insert(choices, 1)
    end
    if data.from:getHandcardNum() > player:getHandcardNum() then
      table.insert(choices, 2)
    end
    if table.contains(choices, 1) then
      room:loseHp(data.from, 1, jidi.name)
    end
    if table.contains(choices, 2) and not data.from.dead then
      local cards = table.filter(data.from:getCardIds("he"), function (id)
        return not data.from:prohibitDiscard(id)
      end)
      if #cards > 0 then
        room:throwCard(table.random(cards, 2), jidi.name, data.from, data.from)
      end
    end
  end,
})

return jidi
