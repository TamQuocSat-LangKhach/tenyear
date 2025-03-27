local chuanshu = fk.CreateSkill {
  name = "chuanshu"
}

Fk:loadTranslationTable{
  ['chuanshu'] = '传术',
  ['#chuanshu-choose'] = '传术：你可令一名其他角色获得〖朝凤〗，你获得〖龙胆〗、〖从谏〗、〖穿云〗',
  ['chaofeng'] = '朝凤',
  [':chuanshu'] = '限定技，准备阶段若你已受伤，或当你死亡时，你可令一名其他角色获得〖朝凤〗，然后你获得〖龙胆〗、〖从谏〗、〖穿云〗。',
  ['$chuanshu1'] = '此术不传子，独传于贤。',
  ['$chuanshu2'] = '定倾之术，贤者可习之。',
}

chuanshu:addEffect(fk.Death, {
  anim_type = "support",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(chuanshu,false,true) and player:usedSkillTimes(chuanshu.name, Player.HistoryGame) == 0 then
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#chuanshu-choose",
      skill_name = chuanshu.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(skill, tos[1]:objectName())
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))
    room:handleAddLoseSkills(to, "chaofeng")
    room:handleAddLoseSkills(player, "longdan|congjian|chuanyun")
  end,
})

chuanshu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(chuanshu,false,true) and player:usedSkillTimes(chuanshu.name, Player.HistoryGame) == 0 then
      return player.phase == Player.Start and player:isWounded()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#chuanshu-choose",
      skill_name = chuanshu.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(skill, tos[1]:objectName())
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))
    room:handleAddLoseSkills(to, "chaofeng")
    room:handleAddLoseSkills(player, "longdan|congjian|chuanyun")
  end,
})

return chuanshu
