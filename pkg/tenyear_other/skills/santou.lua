local santou = fk.CreateSkill {
  name = "santou"
}

Fk:loadTranslationTable{
  ['santou'] = '三头',
  [':santou'] = '锁定技，你的体力上限始终为3，防止你受到的所有伤害。<br>若你体力值不小于3且你本回合已因此技能防止过该伤害来源的伤害，你失去1体力；<br>若你体力值为2且防止的伤害为属性伤害，你失去1体力；<br>若你体力值为1且防止的伤害为红色牌造成的伤害，你失去1体力。',
  ['$santou1'] = '任尔计策奇略，我自随机应对。',
  ['$santou2'] = '三相显圣，何惧雷劫地火？',
}

santou:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if (player.hp >= 3 and data.from and player:getMark("santou_"..data.from.id.."-turn") > 0) or
      (player.hp == 2 and data.damageType ~= fk.NormalDamage) or
      (player.hp == 1 and data.card and data.card.color == Card.Red) then
      room:loseHp(player, 1, santou.name)
    end
    if not player.dead and data.from then
      room:setPlayerMark(player, "santou_"..data.from.id.."-turn", 1)
    end
    return true
  end,
})

return santou
