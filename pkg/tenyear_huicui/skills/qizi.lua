local qizi = fk.CreateSkill {
  name = "qizi"
}

Fk:loadTranslationTable{
  ['qizi'] = '弃子',
  [':qizi'] = '锁定技，其他角色处于濒死状态时，若你与其距离大于2，你不能对其使用【桃】。',
}

qizi:addEffect(fk.EnterDying, {
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and player:distanceTo(target) > 2
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(qizi.name)
    player.room:notifySkillInvoked(player, qizi.name)
  end,
})

qizi:addEffect('prohibit', {
  name = "#qizi_prohibit",
  frequency = Skill.Compulsory,
  prohibit_use = function(self, player, card)
    if player:hasSkill(qizi) and card.name == "peach" then
      return table.find(Fk:currentRoom().alive_players, function(p) return p.dying and player:distanceTo(p) > 2 end)
    end
  end,
})

return qizi
