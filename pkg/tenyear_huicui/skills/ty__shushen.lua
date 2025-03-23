local ty__shushen = fk.CreateSkill {
  name = "ty__shushen"
}

Fk:loadTranslationTable{
  ['ty__shushen'] = '淑慎',
  ['#ty__shushen-choose'] = '淑慎：你可以令一名其他角色回复1点体力或与其各摸一张牌',
  ['ty__shushen_draw'] = '各摸一张牌',
  ['#ty__shushen-choice'] = '淑慎：选择令 %dest 执行的一项',
  [':ty__shushen'] = '当你回复1点体力后，你可以选择一名其他角色，令其回复1点体力或与其各摸一张牌。',
  ['$ty__shushen1'] = '妾身无恙，相公请安心征战。',
  ['$ty__shushen2'] = '船到桥头自然直。',
}

ty__shushen:addEffect(fk.HpRecover, {
  anim_type = "support",
  on_trigger = function(self, event, target, player, data)
    skill.cancel_cost = false
    for i = 1, data.num do
      if skill.cancel_cost then break end
      skill:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__shushen-choose",
      skill_name = skill.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(skill, {tos = to})
      return true
    end
    skill.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill).tos[1])
    local choices = {"ty__shushen_draw"}
    if to:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = skill.name,
      prompt = "#ty__shushen-choice::" .. to.id
    })
    if choice == "ty__shushen_draw" then
      player:drawCards(1, ty__shushen.name)
      to:drawCards(1, ty__shushen.name)
    else
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = ty__shushen.name
      })
    end
  end,
})

return ty__shushen
