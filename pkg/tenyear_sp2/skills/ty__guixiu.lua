local ty__guixiu = fk.CreateSkill {
  name = "ty__guixiu"
}

Fk:loadTranslationTable{
  ['ty__guixiu'] = '闺秀',
  ['ty__cunsi'] = '存嗣',
  [':ty__guixiu'] = '锁定技，你获得此技能后的第一个回合开始时，你摸两张牌；当你发动〖存嗣〗后，你回复1点体力。',
  ['$ty__guixiu1'] = '闺楼独看花月，倚窗顾影自怜。',
  ['$ty__guixiu2'] = '闺中女子，亦可秀气英拔。',
}

ty__guixiu:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty__guixiu.name) and player:getMark(ty__guixiu.name) == 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:drawCards(2, ty__guixiu.name)
    room:setPlayerMark(player, ty__guixiu.name, 1)
  end,
})

ty__guixiu:addEffect(fk.AfterSkillEffect, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__guixiu.name) and data.name == "ty__cunsi" and player:isWounded()
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = ty__guixiu.name
    })
  end,
})

return ty__guixiu
