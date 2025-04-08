local qingman = fk.CreateSkill {
  name = "qingman",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qingman"] = "轻幔",
  [":qingman"] = "锁定技，每个回合结束时，你将手牌摸至X张（X为当前回合角色装备区内的空位数）。",

  ["$qingman1"] = "经纬分明，片片罗縠。",
  ["$qingman2"] = "罗帐轻幔，可消酷暑烦躁。",
}

qingman:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qingman.name) and
      player:getHandcardNum() < (#target:getAvailableEquipSlots() - #target:getCardIds("e"))
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#target:getAvailableEquipSlots() - #target:getCardIds("e") - player:getHandcardNum(), qingman.name)
  end,
})

return qingman
