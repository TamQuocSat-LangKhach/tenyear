local diting = fk.CreateSkill {
  name = "diting",
}

Fk:loadTranslationTable{
  ["diting"] = "谛听",
  [":diting"] = "其他角色出牌阶段开始时，若你在其攻击范围内，你可以观看其X张手牌（X为你的体力值），然后秘密选择其中一张。若如此做，"..
  "本阶段：当该角色使用此牌指定你为目标后，此牌对你无效；使用此牌时没有指定你为目标，你摸两张牌；本阶段结束时此牌仍在其手牌中，你获得之。",

  ["#diting-invoke"] = "谛听：你可以观看 %dest 的手牌并秘密选择一张产生效果",

  ["$diting1"] = "奉命查验，还请配合。",
  ["$diting2"] = "且容我查验一二。",
}

diting:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(diting.name) and target.phase == Player.Play and
      target:inMyAttackRange(player) and not target:isKongcheng() and player.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = diting.name,
      prompt = "#diting-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.random(target:getCardIds("h"), math.min(target:getHandcardNum(), player.hp))
    local id = room:askToChooseCards(player, {
      min = 1,
      max = 1,
      target = target,
      flag = {card_data = {{target.general, cards}}},
      skill_name = diting.name
    })[1]
    room:addTableMark(target, "diting-phase", {player.id, id})
  end,
})

diting:addEffect(fk.TargetSpecified, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return data.firstTarget and table.contains(data.use.tos, player) and
      table.find(target:getTableMark("diting-phase"), function (info)
        return info[1] == player.id and info[2] == data.card:getEffectiveId()
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)
  end,
})

diting:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.find(target:getTableMark("diting-phase"), function (info)
        return info[1] == player.id and info[2] == data.card:getEffectiveId()
      end) and
      not table.contains(data.tos, player) and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, diting.name)
  end,
})

diting:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.find(target:getTableMark("diting-phase"), function (info)
      return info[1] == player.id and
        table.find(target:getCardIds("h"), function (id)
          return info[2] == id
        end) ~= nil
      end) and
      not player.dead
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local ids = table.filter(target:getCardIds("h"), function (id)
      return table.find(target:getTableMark("diting-phase"), function (info)
        return info[1] == player.id and info[2] == id
        end)
    end)
    player.room:obtainCard(player, ids, false, fk.ReasonPrey, player, diting.name)
  end,
})

return diting
