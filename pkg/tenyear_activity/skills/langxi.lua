local langxi = fk.CreateSkill {
  name = "langxi"
}

Fk:loadTranslationTable{
  ['langxi'] = '狼袭',
  ['#langxi-choose'] = '狼袭：请选择一名体力值不大于你的其他角色，对其随机造成0~2点伤害',
  [':langxi'] = '准备阶段开始时，你可以对一名体力值不大于你的其他角色随机造成0~2点伤害。',
  ['$langxi1'] = '袭夺之势，如狼噬骨。',
  ['$langxi2'] = '引吾至此，怎能不袭掠之？'
}

langxi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(langxi) and
      player.phase == Player.Start and
      not table.every(player.room:getOtherPlayers(player), function(p)
        return p.hp > player.hp
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return p.hp <= player.hp
      end), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#langxi-choose",
      skill_name = langxi.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage({
      from = player,
      to = room:getPlayerById(event:getCostData(self).tos[1]),
      damage = math.random(0, 2),
      skillName = langxi.name,
    })
  end,
})

return langxi
