local kuanshi = fk.CreateSkill{
  name = "ty__kuanshi",
}

Fk:loadTranslationTable{
  ["ty__kuanshi"] = "宽释",
  [":ty__kuanshi"] = "结束阶段，你可以选择一名角色。直到你的下回合开始，该角色一回合内受到第2点伤害后回复1点体力（每回合限一次）。",

  ["#ty__kuanshi-choose"] = "宽释：你可以选择一名角色，直到你下回合开始，该角色一回合内受到第2点伤害后回复1点体力",
  ["@@ty__kuanshi"] = "宽释",

  ["$ty__kuanshi1"] = "量罪定刑，需依礼法。",
  ["$ty__kuanshi2"] = "圣明之事，不宜附有酷刑。",
}

kuanshi:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuanshi.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = kuanshi.name,
      prompt = "#ty__kuanshi-choose",
      cancelable = true,
      no_indicate = true,
    })
    if #to > 0 then
      event:setCostData(self, {extra_data = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMarkIfNeed(player, kuanshi.name, event:getCostData(self).extra_data[1].id)
  end,
})

kuanshi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(kuanshi.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, kuanshi.name, 0)
  end,
})

kuanshi:addEffect(fk.Damaged, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if table.contains(player:getTableMark(kuanshi.name), target.id) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 then
      local n = 0
      player.room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data
        if damage.to == target then
          n = n + damage.damage
          if n >= 2 then
            return true
          end
        end
      end, Player.HistoryTurn)
      return n >= 2
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    player.room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = kuanshi.name,
    }
  end,
})

return kuanshi
