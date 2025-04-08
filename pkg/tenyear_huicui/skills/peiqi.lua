local peiqi = fk.CreateSkill {
  name = "peiqi",
}

Fk:loadTranslationTable{
  ["peiqi"] = "配器",
  [":peiqi"] = "当你受到伤害后，你可以移动场上一张牌。然后若所有角色均在相互的攻击范围内，你可以再移动场上一张牌。",

  ["#peiqi-choose"] = "配器：你可以移动场上的一张牌",

  ["$peiqi1"] = "声依永，律和声。",
  ["$peiqi2"] = "音律不协，不可用也。",
}

peiqi:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(peiqi.name) and #player.room:canMoveCardInBoard() > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askToChooseToMoveCardInBoard(player, {
      prompt = "#peiqi-choose",
      skill_name = peiqi.name,
      cancelable = false,
    })
    room:askToMoveCardInBoard(player, {
      target_one = targets[1],
      target_two = targets[2],
      skill_name = peiqi.name,
    })
    if player.dead or #player.room:canMoveCardInBoard() == 0 then return end
    if table.every(room.alive_players, function (p1)
      return table.every(room.alive_players, function (p2)
        return p1 == p2 or p1:inMyAttackRange(p2)
      end)
    end) then
      targets = room:askToChooseToMoveCardInBoard(player, {
        prompt = "#peiqi-choose",
        skill_name = peiqi.name,
        cancelable = true,
      })
      if #targets == 2 then
        room:askToMoveCardInBoard(player, {
          target_one = targets[1],
          target_two = targets[2],
          skill_name = peiqi.name,
        })
      end
    end
  end,
})

return peiqi
