local zhixi = fk.CreateSkill {
  name = "ty__zhixi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__zhixi"] = "止息",
  [":ty__zhixi"] = "锁定技，出牌阶段，当你使用【杀】或锦囊牌时，需弃置一张手牌。",
}

zhixi:addEffect(fk.CardUsing, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhixi.name) and
      player.phase == Player.Play and not player:isKongcheng() and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick)
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = zhixi.name,
      cancelable = false,
    })
  end,
})

return zhixi
