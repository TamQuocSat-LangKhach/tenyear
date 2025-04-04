local ty__mingshi = fk.CreateSkill {
  name = "ty__mingshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['ty__mingshi'] = '名士',
  ['#ty__mingshi-invoke'] = '名士：请弃置一张手牌，否则你对 %src 造成的伤害-1',
  [':ty__mingshi'] = '锁定技，当你受到伤害时，若伤害来源的手牌数大于你，其需弃置一张手牌，否则此伤害-1。',
  ['$ty__mingshi1'] = '孔门之后，忠孝为先。',
  ['$ty__mingshi2'] = '名士之风，仁义高洁。',
}

ty__mingshi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__mingshi.name) and data.from and data.from:getHandcardNum() > player:getHandcardNum()
  end,
  on_use = function(self, event, target, player, data)
    if #player.room:askToDiscard(data.from, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = ty__mingshi.name,
      cancelable = true,
      prompt = "#ty__mingshi-invoke:"..player.id
    }) == 0 then
      data.damage = data.damage - 1
    end
  end,
})

return ty__mingshi
