local haoshou = fk.CreateSkill {
  name = "haoshou$"
}

Fk:loadTranslationTable{
  ['#haoshou-invoke'] = '豪首：是否令 %src 回复1点体力？',
}

haoshou:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(haoshou.name) and data.card.trueName == "analeptic" and target ~= player and target.kingdom == "qun" and player:isWounded()
  end,
  on_cost = function (skill, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = haoshou.name,
      prompt = "#haoshou-invoke:"..player.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(target.id, {player.id})
    room:recover({
      who = player,
      num = 1,
      recoverBy = target,
      skillName = haoshou.name
    })
  end,
})

return haoshou
