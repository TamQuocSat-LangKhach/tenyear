local diting = fk.CreateSkill {
  name = "diting"
}

Fk:loadTranslationTable{
  ['diting'] = '谛听',
  ['#diting-invoke'] = '谛听：你可以观看 %dest 的手牌并秘密选择一张产生效果',
  [':diting'] = '其他角色出牌阶段开始时，若你在其攻击范围内，你可以观看其X张手牌（X为你的体力值），然后秘密选择其中一张。若如此做，本阶段该角色使用此牌指定你为目标后，此牌对你无效；若没有指定你为目标，你摸两张牌；若本阶段结束时此牌仍在其手牌中，你获得之。',
  ['$diting1'] = '奉命查验，还请配合。',
  ['$diting2'] = '且容我查验一二。',
}

diting:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(diting.name) and target ~= player and target.phase == Player.Play and not target:isKongcheng() and
      target:inMyAttackRange(player) and player.hp > 0
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = diting.name,
      prompt = "#diting-invoke::"..target.id
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local cards = table.random(target:getCardIds("h"), math.min(target:getHandcardNum(), player.hp))
    local id = room:askToChooseCards(player, {
      min = 1,
      max = 1,
      target = target,
      flag = {card_data = {{target.general, cards}}},
      skill_name = diting.name
    })[1]
    room:setPlayerMark(target, "diting_"..player.id.."-phase", id)
  end,
})

diting:addEffect({fk.TargetSpecified, fk.CardUsing, fk.EventPhaseEnd}, {
  mute = true,
  can_trigger = function(self, event, target, player)
    if player:usedSkillTimes(diting.name, Player.HistoryPhase) > 0 and target:getMark("diting_"..player.id.."-phase") ~= 0 and not player.dead then
      if event == fk.TargetSpecified then
        return data.card:getEffectiveId() == target:getMark("diting_"..player.id.."-phase") and
          table.contains(AimGroup:getAllTargets(data.tos), player.id)
      elseif event == fk.CardUsing then
        return data.card:getEffectiveId() == target:getMark("diting_"..player.id.."-phase") and
          (not data.tos or not table.contains(TargetGroup:getRealTargets(data.tos), player.id))
      elseif event == fk.EventPhaseEnd then
        return target.phase == Player.Play and table.contains(target:getCardIds("h"), target:getMark("diting_"..player.id.."-phase"))
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(diting.name)
    if event == fk.TargetSpecified then
      room:notifySkillInvoked(player, diting.name, "defensive")
      table.insertIfNeed(data.nullifiedTargets, player.id)
    elseif event == fk.CardUsing then
      room:notifySkillInvoked(player, diting.name, "drawcard")
      player:drawCards(2, diting.name)
    elseif event == fk.EventPhaseEnd then
      room:notifySkillInvoked(player, diting.name, "control")
      local id = target:getMark("diting_"..player.id.."-phase")
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
})

return diting
