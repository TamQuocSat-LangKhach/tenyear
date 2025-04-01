local dunxi = fk.CreateSkill {
  name = "dunxi",
}

Fk:loadTranslationTable{
  ["dunxi"] = "钝袭",
  [":dunxi"] = "当你使用伤害牌时，你可以令其中一个目标获得1个“钝”标记。有“钝”标记的角色使用指定唯一目标的基本牌或锦囊牌时，"..
  "若没有角色处于濒死状态，其移去一个“钝”，然后目标改为随机一名角色。若随机的目标与原本目标相同，则其于此牌结算结束后失去1点体力并结束出牌阶段。",

  ["#dunxi-choose"] = "钝袭：令一名目标获得“钝”标记，其使用下一张牌目标改为随机角色",
  ["@bianxi_dun"] = "钝",

  ["$dunxi1"] = "看锤！",
  ["$dunxi2"] = "且吃我一锤！",
}

dunxi:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dunxi.name) and data.card.is_damage_card and
      table.find(data.tos, function (p)
        return not p.dead
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = data.tos,
      min_num = 1,
      max_num = 1,
      prompt = "#dunxi-choose",
      skill_name = dunxi.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(event:getCostData(self).tos[1], "@bianxi_dun", 1)
  end,
})

dunxi:addEffect(fk.CardUsing, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@bianxi_dun") > 0 and
      data.card.type ~= Card.TypeEquip and data:isOnlyTarget(data.tos[1]) and
      not table.find(player.room.alive_players, function (p)
        return p.dying
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@bianxi_dun")
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if not player:isProhibited(p, data.card) and
        (data.card.sub_type == Card.SubtypeDelayedTrick or
        data.card.skill:modTargetFilter(player, p, {}, data.card, data.extra_data)) then
        table.insert(targets, p)
      end
    end
    if #targets > 0 then
      local random_target = table.random(targets)
      if #targets > 1 then
        for _ = 1, 2 do
          for _, p in ipairs(room:getAllPlayers()) do
            if table.contains(targets, p) then
              room:setEmotion(p, "./image/anim/selectable")
              room:notifyMoveFocus(p, dunxi.name)
              room:delay(300)
            end
          end
        end
        for _, p in ipairs(room:getAllPlayers()) do
          if table.contains(targets, p) then
            room:setEmotion(p, "./image/anim/selectable")
            room:delay(600)
            if p.id == random_target then
              room:doIndicate(data.from, {random_target})
              break
            end
          end
        end
      end

      if random_target == data.tos[1] then
        data.extra_data = data.extra_data or {}
        data.extra_data.dunxi_record = data.extra_data.dunxi_record or {}
        table.insert(data.extra_data.dunxi_record, player.id)
        data.extra_data.dunxi_record = data.extra_data.dunxi_record
      else
        data:removeTarget(data.tos[1])
        data:addTarget(random_target)
      end
    else
      data:removeAllTargets()
    end
  end,
})

dunxi:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.dunxi_record and
      table.contains(data.extra_data.dunxi_record, player.id)
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 1, dunxi.name)
    if player.phase == Player.Play then
      player:endPlayPhase()
    end
  end,
})

return dunxi
