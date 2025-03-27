local ty__chouhai = fk.CreateSkill {
  name = "ty__chouhai"
}

Fk:loadTranslationTable{
  ['ty__chouhai'] = '仇海',
  [':ty__chouhai'] = '锁定技，当你受到【杀】造成的伤害时，若你没有手牌，此伤害+1。',
  ['$ty__chouhai1'] = '大好头颅，谁当斫之？哈哈哈！',
  ['$ty__chouhai2'] = '来来来！且试吾颈硬否！',
}

ty__chouhai:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__chouhai.name) and player:isKongcheng() and data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

return ty__chouhai
