local chuanshu = fk.CreateSkill {
  name = "chuanshu",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["chuanshu"] = "传术",
  [":chuanshu"] = "限定技，准备阶段若你已受伤，或当你死亡时，你可令一名其他角色获得〖朝凤〗，然后你获得〖龙胆〗〖从谏〗〖穿云〗。",

  ["#chuanshu-choose"] = "传术：你可以令一名其他角色获得“朝凤”，你获得“龙胆”“从谏”“穿云”",

  ["$chuanshu1"] = "此术不传子，独传于贤。",
  ["$chuanshu2"] = "定倾之术，贤者可习之。",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#chuanshu-choose",
      skill_name = chuanshu.name,
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
    room:handleAddLoseSkills(to, "chaofeng")
    room:handleAddLoseSkills(player, "longdan|congjian|chuanyun")
  end,
}

chuanshu:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chuanshu.name, false, true) and
      player:usedSkillTimes(chuanshu.name, Player.HistoryGame) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

chuanshu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(chuanshu.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(chuanshu.name, Player.HistoryGame) == 0 and
      player:isWounded() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return chuanshu
