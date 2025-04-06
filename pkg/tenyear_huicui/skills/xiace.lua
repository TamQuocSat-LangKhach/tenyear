local xiace = fk.CreateSkill {
  name = "xiace",
}

Fk:loadTranslationTable{
  ["xiace"] = "黠策",
  [":xiace"] = "每回合各限一次，当你受到伤害后，你可令一名其他角色的所有非锁定技于本回合内失效；当你造成伤害后，你可以弃置一张牌并回复1点体力。",

  ["#xiace-recover"] = "黠策：你可以弃置一张牌，回复1点体力",
  ["#xiace-control"] = "黠策：选择一名其他角色，令其本回合非锁定技失效",
  ["@@xiace-turn"] = "黠策",

  ["$xiace1"] = "风之积非厚，其负大翼也无力。",
  ["$xiace2"] = "人情同于抔土，岂穷达而异心。",
}

xiace:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiace.name) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = xiace.name,
      cancelable = true,
      prompt = "#xiace-recover",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, xiace.name, player, player)
    if not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = xiace.name,
      }
    end
  end,
})

xiace:addEffect(fk.Damaged, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiace.name) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#xiace-control",
      skill_name = xiace.name,
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
    room:setPlayerMark(to, "@@xiace-turn", 1)
    room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
  end,
})

return xiace
