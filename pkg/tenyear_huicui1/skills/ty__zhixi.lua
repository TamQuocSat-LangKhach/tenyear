local ty__zhixi = fk.CreateSkill {
  name = "ty__zhixi"
}

Fk:loadTranslationTable{
  ['ty__zhixi'] = '止息',
  [':ty__zhixi'] = '锁定技，出牌阶段，当你使用【杀】或锦囊牌时，需弃置一张手牌。',
}

ty__zhixi:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play and not player:isKongcheng() and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick)
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = skill.name,
      cancelable = false,
    })
  end,
})

return ty__zhixi
