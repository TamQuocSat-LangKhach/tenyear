local chijie = fk.CreateSkill {
  name = "chijie",
}

Fk:loadTranslationTable{
  ["chijie"] = "持节",
  [":chijie"] = "每回合每项各限一次，当其他角色使用牌对你生效时，你可以令此牌在接下来的结算中对其他角色无效；当其他角色使用牌结算结束后，"..
  "若你是目标之一且此牌没有造成过伤害，你可以获得之。",

  ["#chijie-invoke"] = "持节：你可以令 %arg 在接下来的结算中对其他角色无效",
  ["#chijie-prey"] = "持节：你可以获得此 %arg",

  ["$chijie1"] = "持节阻战，奉帝赐诏。",
  ["$chijie2"] = "此战不在急，请仲达明了。",
}

chijie:addEffect(fk.CardEffecting, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chijie.name) and
      data.from ~= player and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and #data.tos > 1 and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chijie.name,
      prompt = "#chijie-invoke:::" .. data.card.name,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data
      use.nullifiedTargets = table.simpleClone(room:getOtherPlayers(player, false))
    end
  end,
})

chijie:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(chijie.name) and
      not data.damageDealt and table.contains(data.tos, player) and
      player.room:getCardArea(data.card) == Card.Processing and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chijie.name,
      prompt = "#chijie-prey:::"..data.card.name,
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, chijie.name)
  end,
})

return chijie
