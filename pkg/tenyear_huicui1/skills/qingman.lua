local qingman = fk.CreateSkill {
  name = "qingman"
}

Fk:loadTranslationTable{
  ['qingman'] = '轻幔',
  [':qingman'] = '锁定技，每个回合结束时，你将手牌摸至X张（X为当前回合角色装备区内的空位数）。',
  ['$qingman1'] = '经纬分明，片片罗縠。',
  ['$qingman2'] = '罗帐轻幔，可消酷暑烦躁。',
}

qingman:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name) and player:getHandcardNum() < 5 - #target:getCardIds("e")
  end,
  on_use = function(self, event, target, player)
    local num_to_draw = 5 - #target:getCardIds("e") - player:getHandcardNum()
    if num_to_draw > 0 then
      player:drawCards(num_to_draw, { skill_name = skill.name })
    end
  end,
})

return qingman
