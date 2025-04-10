local saima = fk.CreateSkill {
  name = "saima",
}

Fk:loadTranslationTable{
  ["saima"] = "赛马",
  [":saima"] = "当你使用坐骑牌后，你可以与一名其他角色进行连续三次拼点。若你赢的次数不小于2，对其造成1点伤害。",

  ["#saima-choose"] = "赛马：与一名角色连续三次拼点，若赢的次数不小于2，对其造成1点伤害",
}

saima:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(saima.name) and
      (data.card.sub_type == Card.SubtypeDefensiveRide or data.card.sub_type == Card.SubtypeOffensiveRide) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = saima.name,
      prompt = "#saima-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local count = 0
    for _ = 1, 3 do
      if player.dead or to.dead or not player:canPindian(to) then break end
      local pindian = player:pindian({to}, saima.name)
      if pindian.results[to].winner == player then
        count = count + 1
      end
    end
    if count >= 2 and not to.dead then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = saima.name,
      }
    end
  end,
})

return saima
