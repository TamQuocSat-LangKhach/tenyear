local yanhuo = fk.CreateSkill {
  name = "ty__yanhuo",
}

Fk:loadTranslationTable{
  ["ty__yanhuo"] = "延祸",
  [":ty__yanhuo"] = "当你死亡时，你可以令本局接下来所有【杀】的伤害基数值+1。",

  ["#yanhuo-invoke"] = "延祸：你可以令本局接下来所有【杀】的伤害基数值+1！",
  ["@@ty__yanhuo"] = "延祸无穷",

  ["$ty__yanhuo1"] = "你们，都要为我殉葬！",
  ["$ty__yanhuo2"] = "杀了我，你们也别想活！",
}

yanhuo:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yanhuo.name, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yanhuo.name,
      prompt = "#yanhuo-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local banner = room:getBanner("@@ty__yanhuo") or 0
    banner = banner + 1
    room:setBanner("@@ty__yanhuo", banner)
  end,
})

yanhuo:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room:getBanner("@@ty__yanhuo") and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player.room:getBanner("@@ty__yanhuo")
  end,
})

return yanhuo
