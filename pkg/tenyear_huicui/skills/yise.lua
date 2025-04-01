local yise = fk.CreateSkill {
  name = "yise",
}

Fk:loadTranslationTable{
  ["yise"] = "异色",
  [":yise"] = "当其他角色获得你的牌后，若此牌为：红色，你可以令其回复1点体力；黑色，其下次受到【杀】造成的伤害时，此伤害+1。",

  ["#yise-invoke"] = "异色：你可以令 %dest 回复1点体力",
  ["@yise"] = "异色",

  ["$yise1"] = "明丽端庄，双瞳剪水。",
  ["$yise2"] = "姿色天然，貌若桃李。",
}

yise:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yise.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.to and move.to ~= player and not move.to.dead and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color ~= Card.NoColor then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local list = {}
    for _, move in ipairs(data) do
      if move.from == player and move.to and move.to ~= player and not move.to.dead and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).color ~= Card.NoColor then
            list[move.to] = list[move.to] or {}
            table.insertIfNeed(list[move.to], Fk:getCardById(info.cardId).color)
          end
        end
      end
    end
    for _, p in ipairs(room:getAlivePlayers()) do
      if not player:hasSkill(yise.name) then break end
      if not p.dead and list[p] then
        event:setCostData(self, {extra_data = {p, list[p]}})
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self).extra_data
    local to = dat[1]
    if table.contains(dat[2], Card.Red) then
      if not to:isWounded() or
      not room:askToSkillInvoke(player, {
        skill_name = yise.name,
        prompt = "#yise-invoke::"..to.id,
      }) then
        table.removeOne(dat[2], Card.Red)
      end
    end
    if #dat[2] > 0 then
      event:setCostData(self, {tos = {to}, choice = dat[2]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if table.contains(choice, Card.Red) then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = yise.name,
      }
    end
    if table.contains(choice, Card.Black) and not to.dead then
      room:addPlayerMark(to, "@yise", 1)
    end
  end,
})

yise:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@yise") > 0 and data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(player:getMark("@yise"))
    player.room:setPlayerMark(player, "@yise", 0)
  end,
})

return yise
