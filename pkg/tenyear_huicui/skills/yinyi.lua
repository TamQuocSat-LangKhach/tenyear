local yinyi = fk.CreateSkill {
  name = "yinyi"
}

Fk:loadTranslationTable{
  ['yinyi'] = '隐逸',
  [':yinyi'] = '锁定技，每回合限一次，当你受到非属性伤害时，若伤害来源的手牌数与体力值均与你不同，防止此伤害。',
  ['$yinyi1'] = '采山饮河，所以养性。',
  ['$yinyi2'] = '隐于鱼梁，率尔休畅。',
}

yinyi:addEffect(fk.DamageInflicted, {
  global = false,
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(yinyi.name) and data.damageType == fk.NormalDamage and
      data.from and data.from:getHandcardNum() ~= player:getHandcardNum() and data.from.hp ~= player.hp and
      player:usedSkillTimes(yinyi.name, Player.HistoryTurn) == 0
  end,
  on_use = Util.TrueFunc,
})

return yinyi
