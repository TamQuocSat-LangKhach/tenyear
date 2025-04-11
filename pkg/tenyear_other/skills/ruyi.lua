local ruyi = fk.CreateSkill {
  name = "ruyi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ruyi"] = "如意",
  [":ruyi"] = "锁定技，你手牌中的武器牌均视为【杀】，你废除武器栏。你的攻击范围基数为3，出牌阶段限一次，你可以调整攻击范围（1~4）。"..
  "若你的攻击范围基数为：1，使用【杀】无次数限制；2，使用【杀】伤害+1；3，使用【杀】无法响应；4，使用【杀】可额外选择一个目标。",

  ["#ruyi"] = "如意：选择你的攻击范围",
  ["@ruyi"] = "如意",
  ["#ruyi-choose"] = "如意：你可以为%arg额外选择一个目标",

  ["$ruyi1"] = "俺老孙来也！",
  ["$ruyi2"] = "吃俺老孙一棒！"
}

ruyi:addEffect("active", {
  name = "ruyi",
  prompt = "#ruyi",
  card_num = 0,
  target_num = 0,
  interaction = UI.Spin { from = 1, to = 4 },
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:setPlayerMark(player, "@ruyi", self.interaction.data)
  end,
})

ruyi:addEffect("atkrange", {
  fixed_func = function (skill, player)
    if player:hasSkill(ruyi.name) and player:getMark("@ruyi") ~= 0 then
      return player:getMark("@ruyi")
    end
  end,
})

ruyi:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return player:hasSkill(ruyi.name) and card.sub_type == Card.SubtypeWeapon and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, plain, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = ruyi.name
    return c
  end,
})

ruyi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope)
    return player:hasSkill(ruyi.name) and player:getMark("@ruyi") <= 1 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase
  end,
})

ruyi:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ruyi.name) and data.card.trueName == "slash" and
      (player:getMark("@ruyi") == 2 or player:getMark("@ruyi") == 3)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@ruyi") == 2 then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    elseif player:getMark("@ruyi") == 3 then
      data.disresponsiveList = table.simpleClone(room.players)
    end
  end,
})

ruyi:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ruyi.name) and
      player:getMark("@ruyi") == 4 and #data:getExtraTargets() > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = data:getExtraTargets(),
      min_num = 1,
      max_num = 1,
      prompt = "#ruyi-choose:::"..data.card:toLogString(),
      skill_name = ruyi.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})

ruyi:addEffect(fk.GameStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ruyi.name, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@ruyi", 3)
    if table.contains(player:getAvailableEquipSlots(), Player.WeaponSlot) then
      room:abortPlayerArea(player, Player.WeaponSlot)
    end
  end,
})

ruyi:addAcquireEffect(function (self, player, is_start)
  if is_start then
    local room = player.room
    room:setPlayerMark(player, "@ruyi", 3)
    if table.contains(player:getAvailableEquipSlots(), Player.WeaponSlot) then
      room:abortPlayerArea(player, Player.WeaponSlot)
    end
  end
end)

return ruyi
