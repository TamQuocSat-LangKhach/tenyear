local fengliao = fk.CreateSkill {
  name = "fengliao"
}

Fk:loadTranslationTable{
  ['fengliao'] = '凤燎',
  [':fengliao'] = '锁定技，转换技，当你使用牌指定唯一目标后，阳：你令其摸一张牌；阴：你对其造成1点火焰伤害。',
  ['$fengliao1'] = '乘丹凤者，不堪其炙，何堪其远？',
  ['$fengliao2'] = '我以天地为炉，诸君敢入局否？'
}

fengliao:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fengliao.name) then
      local to = player.room:getPlayerById(data.to)
      return not to.dead and U.isOnlyTarget(to, data, event)
    end
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    if player:getSwitchSkillState(fengliao.name, true) == fk.SwitchYang then
      to:drawCards(1, fengliao.name)
    else
      room:damage{
        from = player,
        to = to,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = fengliao.name,
      }
    end
  end,
})

return fengliao
