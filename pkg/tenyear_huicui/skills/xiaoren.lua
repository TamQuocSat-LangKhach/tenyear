local xiaoren = fk.CreateSkill {
  name = "xiaoren",
}

Fk:loadTranslationTable{
  ["xiaoren"] = "绡刃",
  [":xiaoren"] = "每回合限一次，当你造成伤害后，你可以判定，若结果为：红色，你可以选择一名角色，其回复1点体力，然后若其未受伤，其摸一张牌；"..
  "黑色，对受伤角色的上家或下家造成1点伤害，然后你可以再次判定并执行对应结果直到有角色进入濒死状态。",

  ["#xiaoren-recover"] = "绡刃：你可以令一名角色回复1点体力，然后若其满体力，其摸一张牌",
  ["#xiaoren-damage"] = "绡刃：对 %dest 的上家或下家造成1点伤害，若未濒死可继续发动此技能",

  ["$xiaoren1"] = "红绡举腕重，明眸最溺人。",
  ["$xiaoren2"] = "飘然回雪轻，言然游龙惊。",
}

xiaoren:addEffect(fk.Damage, {
  anim_type = "offensive",
  trigger_times = function(self, event, target, player, data)
    if player:getMark("xiaoren_break-turn") > 0 then
      player.room:setPlayerMark(player, "xiaoren_break-turn", 0)
      return 0
    end
    return 1
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiaoren.name) and
      (player:usedSkillTimes(xiaoren.name, Player.HistoryTurn) == 0 or data.skillName == self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = xiaoren.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if player.dead then return end
    if judge.card.color == Card.Red then
      local to = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#xiaoren-recover",
        skill_name = xiaoren.name,
        cancelable = true
      })
      if #to > 0 then
        to = to[1]
        if to:isWounded() then
          room:recover{
            who = to,
            num = 1,
            recoverBy = player,
            skillName = xiaoren.name,
          }
          if not (to.dead or to:isWounded()) then
            to:drawCards(1, xiaoren.name)
          end
        else
          to:drawCards(1, xiaoren.name)
        end
      end
    elseif judge.card.color == Card.Black then
      if data.to.dead then return end
      local targets = table.filter(room.alive_players, function (p)
        return p:getNextAlive() == data.to or data.to:getNextAlive() == p
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#xiaoren-damage::" .. data.to.id,
        skill_name = xiaoren.name,
        cancelable = false,
      })[1]
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = xiaoren.name,
      }
    end
  end,
})

xiaoren:addEffect(fk.EnterDying, {
  can_refresh = function (self, event, target, player, data)
    return not player.dead and player:getMark("xiaoren_break-turn") == 0 and
      player:usedSkillTimes(xiaoren.name, Player.HistoryTurn) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "xiaoren_break-turn", 1)
  end,
})

return xiaoren
