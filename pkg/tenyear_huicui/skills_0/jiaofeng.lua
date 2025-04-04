local jiaofeng = fk.CreateSkill {
  name = "jiaofeng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['jiaofeng'] = '交锋',
  [':jiaofeng'] = '锁定技，当你每回合首次造成伤害时，若你已损失体力值：大于0，你摸一张牌；大于1，此伤害+1；大于2，你回复1点体力。',
  ['$jiaofeng1'] = '此击透骨，亦解骨肉之痛。',
  ['$jiaofeng2'] = '关羽？哼，不过如此！',
}

jiaofeng:addEffect(fk.DamageCaused, {
  anim_type = "support",
  
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiaofeng.name) and player:usedSkillTimes(jiaofeng.name, Player.HistoryTurn) == 0 and
      #player.room.logic:getActualDamageEvents(1, function(e)
        return e.data[1].from == player
      end) == 0
  end,
  on_use = function(self, event, target, player, data)
    if player:getLostHp() > 0 then
      player:drawCards(1, jiaofeng.name)
    end
    if player:getLostHp() > 1 then
      data.damage = data.damage + 1
    end
    if player:getLostHp() > 2 then
      player.room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = jiaofeng.name
      }
    end
  end,
})

return jiaofeng
