local xianju = fk.CreateSkill {
  name = "xianju",
}

Fk:loadTranslationTable{
  ["xianju"] = "险拒",
  [":xianju"] = "出牌阶段限一次，你可以获得攻击范围内每名角色各一张牌，若如此做，此阶段结束时，你弃置X张牌（X为你攻击范围外的其他角色数）。",

  ["#xianju"] = "险拒：获得攻击范围内每名角色各一张牌",
  ["#xianju-prey"] = "险拒：获得 %dest 一张牌",

  ["$xianju1"] = "",
  ["$xianju2"] = "",
}

xianju:addEffect("active", {
  anim_type = "control",
  prompt = "#xianju",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(xianju.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function (p)
        return player:inMyAttackRange(p) and not p:isNude()
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.filter(room:getOtherPlayers(player), function (p)
      return player:inMyAttackRange(p)
    end)
    room:doIndicate(player, targets)
    for _, p in ipairs(targets) do
      if player.dead then return end
      if not p.dead and not p:isNude() then
        local card = room:askToChooseCard(player, {
          target = p,
          flag = "he",
          skill_name = xianju.name,
          prompt = "#xianju-prey::"..p.id,
        })
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, xianju.name, nil, false, player)
      end
    end
  end,
})

xianju:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:usedSkillTimes(xianju.name, Player.HistoryPhase) > 0 and not player.dead
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.alive_players, function (p)
      return not player:inMyAttackRange(p) and p ~= player
    end)
    room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = xianju.name,
      cancelable = false,
    })

  end,
})

return xianju
