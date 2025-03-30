local shushen = fk.CreateSkill{
  name = "ty__shushen",
}

Fk:loadTranslationTable{
  ["ty__shushen"] = "淑慎",
  [":ty__shushen"] = "当你回复1点体力后，你可以选择一名其他角色，令其回复1点体力或与其各摸一张牌。",

  ["#ty__shushen-choose"] = "淑慎：你可以令一名其他角色回复1点体力或与其各摸一张牌",
  ["#ty__shushen-choice"] = "淑慎：选择令 %dest 执行的一项",
  ["ty__shushen_draw"] = "各摸一张牌",

  ["$ty__shushen1"] = "妾身无恙，相公请安心征战。",
  ["$ty__shushen2"] = "船到桥头自然直。",
}

shushen:addEffect(fk.HpRecover, {
  anim_type = "support",
  trigger_times = function (self, event, target, player, data)
    return data.num
  end,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shushen.name) and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      skill_name = shushen.name,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      prompt = "#ty__shushen-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choices = { "ty__shushen_draw" }
    if to:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = shushen.name,
      prompt = "#ty__shushen-choice::"..to.id,
    })
    if choice == "ty__shushen_draw" then
      player:drawCards(1, shushen.name)
      if not to.dead then
        to:drawCards(1, shushen.name)
      end
    else
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = shushen.name,
      }
    end
  end,
})

return shushen
