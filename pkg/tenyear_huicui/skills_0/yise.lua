local yise = fk.CreateSkill {
  name = "yise"
}

Fk:loadTranslationTable{
  ['yise'] = '异色',
  ['#yise-invoke'] = '异色：你可以令 %dest 回复1点体力',
  ['@yise'] = '异色',
  ['#yise_delay'] = '异色',
  [':yise'] = '当其他角色获得你的牌后，若此牌为：红色，你可以令其回复1点体力；黑色，其下次受到【杀】造成的伤害时，此伤害+1。',
  ['$yise1'] = '明丽端庄，双瞳剪水。',
  ['$yise2'] = '姿色天然，貌若桃李。',
}

-- 主技能
yise:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yise.name) then
      local room = player.room
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id
          and not room:getPlayerById(move.to).dead and move.toArea == Card.PlayerHand then
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
      if move.from == player.id and move.to and move.to ~= player.id and not room:getPlayerById(move.to).dead and
        move.toArea == Card.PlayerHand then
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
      if not p.dead and list[p.id] then
        skill:doCost(event, p, player, list[p.id])
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if table.contains(data, Card.Red) and (not target:isWounded() or
      not player.room:askToSkillInvoke(player, { skill_name = yise.name, prompt = "#yise-invoke::"..target.id })) then
      table.removeOne(data, Card.Red)
    end
    return #data > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.contains(data, Card.Red) then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = yise.name
      })
    end
    if table.contains(data, Card.Black) and not target.dead then
      event:setCostData(skill, 1)
    end
  end,
})

-- 延迟技能
yise:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@yise") > 0 and data.card and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local markValue = event:getCostData(skill) or 0
    data.damage = data.damage + markValue
    player.room:setPlayerMark(player, "@yise", 0)
  end,
})

return yise
