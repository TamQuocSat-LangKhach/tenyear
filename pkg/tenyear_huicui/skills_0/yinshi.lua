local yinshi = fk.CreateSkill {
  name = "yinshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['yinshi'] = '隐士',
  ['@@dragon_mark'] = '龙印',
  ['@@phoenix_mark'] = '凤印',
  [':yinshi'] = '锁定技，当你受到属性伤害或锦囊牌造成的伤害时，若你没有“龙印”、“凤印”且装备区内没有防具牌，防止此伤害。',
  ['$yinshi1'] = '山野闲散之人，不堪世用。',
  ['$yinshi2'] = '我老啦，会有胜我十倍的人来帮助你。',
}

yinshi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yinshi.name) and target == player and (data.damageType ~= fk.NormalDamage or (data.card and data.card.type == Card.TypeTrick)) and player:getMark("@@dragon_mark") == 0 and player:getMark("@@phoenix_mark") == 0 and #player:getEquipments(Card.SubtypeArmor) == 0
  end,
  on_use = Util.TrueFunc,
})

return yinshi
