local fengliao = fk.CreateSkill {
  name = "fengliao",
  tags = { Skill.Compulsory, Skill.Switch },
}

Fk:loadTranslationTable{
  ["fengliao"] = "凤燎",
  [":fengliao"] = "锁定技，转换技，当你使用牌指定唯一目标后，阳：你令其摸一张牌；阴：你对其造成1点火焰伤害。",

  ["$fengliao1"] = "乘丹凤者，不堪其炙，何堪其远？",
  ["$fengliao2"] = "我以天地为炉，诸君敢入局否？"
}

fengliao:addEffect(fk.TargetSpecified, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fengliao.name) and
      data:isOnlyTarget(data.to) and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    event:setCostData(self, { tos = { data.to } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(fengliao.name, true) == fk.SwitchYang then
      data.to:drawCards(1, fengliao.name)
    else
      room:damage{
        from = player,
        to = data.to,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = fengliao.name,
      }
    end
  end,
})

return fengliao
