local haoshou = fk.CreateSkill {
  name = "haoshou",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["haoshou"] = "豪首",
  [":haoshou"] = "主公技，其他群雄势力角色使用【酒】时，可以令你回复1点体力。",

  ["#haoshou-invoke"] = "豪首：是否令 %src 回复1点体力？",

  ["$haoshou1"] = "满朝主公，试吾剑不利否？",
  ["$haoshou2"] = "顺我者生，逆我者十死无生！",
}

haoshou:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(haoshou.name) and player:isWounded() and
      data.card.trueName == "analeptic" and target ~= player and target.kingdom == "qun"
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(target, {
      skill_name = haoshou.name,
      prompt = "#haoshou-invoke:"..player.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(target, {player})
    room:recover{
      who = player,
      num = 1,
      recoverBy = target,
      skillName = haoshou.name,
    }
  end,
})

return haoshou
