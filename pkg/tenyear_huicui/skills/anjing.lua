local anjing = fk.CreateSkill {
  name = "anjing",
}

Fk:loadTranslationTable{
  ["anjing"] = "安境",
  [":anjing"] = "每回合限一次，当你造成伤害后，你可以令至多X名已受伤角色各摸一张牌，然后其中体力值最少的随机一名角色回复1点体力。"..
  "（X为此技能发动次数）",

  ["#anjing-choose"] = "安境：你可以令至多%arg名已受伤角色摸牌，体力值最少的角色回复体力",

  ["$anjing1"] = "既束甲掌戈，当以仁为己任。",
  ["$anjing2"] = "士者，保境为任，安民为仁。",
}

anjing:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(anjing.name) and
      player:usedSkillTimes(anjing.name, Player.HistoryTurn) == 0 and
      table.find(player.room.alive_players, function (p)
        return p:isWounded()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:isWounded()
    end)
    local n = player:usedSkillTimes(anjing.name, Player.HistoryGame) + 1
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = n,
      targets = targets,
      skill_name = anjing.name,
      prompt = "#anjing-choose:::"..n,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = event:getCostData(self).tos
    for _, p in ipairs(tos) do
      if not p.dead then
        p:drawCards(1, anjing.name)
      end
    end
    tos = table.filter(tos, function (p)
      return table.every(tos, function (q)
        return p.hp <= q.hp
      end) and p:isWounded() and not p.dead
    end)
    if #tos > 0 then
      room:recover{
        who = table.random(tos),
        num = 1,
        recoverBy = player,
        skillName = anjing.name,
      }
    end
  end,
})

return anjing
