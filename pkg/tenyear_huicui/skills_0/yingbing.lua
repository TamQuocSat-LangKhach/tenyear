local yingbing = fk.CreateSkill {
  name = "ty__yingbing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['ty__yingbing'] = '影兵',
  ['ty__zhoufu_zhou'] = '咒',
  [':ty__yingbing'] = '锁定技，每回合每名角色限一次，当你使用牌指定有“咒”的角色为目标后，你摸两张牌。',
  ['$ty__yingbing1'] = '青龙白虎，队仗纷纭！',
  ['$ty__yingbing2'] = '我有影兵三万，何惧你们！'
}

yingbing:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yingbing.name) and target == player and #player.room:getPlayerById(data.to):getPile("ty__zhoufu_zhou") > 0
      and not table.contains(player:getTableMark("ty__yingbing-turn"), data.to)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, "ty__yingbing-turn", data.to)
    player:drawCards(2, yingbing.name)
  end,
})

return yingbing
