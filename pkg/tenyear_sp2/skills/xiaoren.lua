local xiaoren = fk.CreateSkill {
  name = "xiaoren"
}

Fk:loadTranslationTable{
  ['xiaoren'] = '绡刃',
  ['#xiaoren-recover'] = '绡刃：可令一名角色回复1点体力，然后若其满体力，其摸一张牌',
  ['#xiaoren-damage'] = '绡刃：对%dest的上家或下家造成1点伤害，未濒死可继续发动此技能',
  [':xiaoren'] = '每回合限一次，当你造成伤害后，你可以判定，若结果为：红色，你可以选择一名角色。其回复1点体力，若其未受伤，其摸一张牌；黑色，对受伤角色的上家或下家造成1点伤害，然后你可以再次判定并执行对应结果直到有角色进入濒死状态。',
  ['$xiaoren1'] = '红绡举腕重，明眸最溺人。',
  ['$xiaoren2'] = '飘然回雪轻，言然游龙惊。',
}

xiaoren:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(xiaoren) and player:getMark("xiaoren_break-turn") == 0 and
      (player:usedSkillTimes(xiaoren.name) == 0 or player.last_skill_name == xiaoren.name)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local judge = {
      who = player,
      reason = xiaoren.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if player.dead then return false end
    if judge.card.color == Card.Red then
      local targets = room:askToChoosePlayers(player, {
        targets = table.map(room.alive_players, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#xiaoren-recover",
        skill_name = xiaoren.name,
        cancelable = true
      })
      if #targets > 0 then
        local tar = room:getPlayerById(targets[1])
        if tar:isWounded() then
          room:recover({
            who = tar,
            num = 1,
            recoverBy = player,
            skillName = xiaoren.name,
          })
          if not (tar.dead or tar:isWounded()) then
            room:drawCards(tar, 1, xiaoren.name)
          end
        else
          room:drawCards(tar, 1, xiaoren.name)
        end
      end
    elseif judge.card.color == Card.Black then
      local tar = target -- data.to in old version
      if tar.dead then return false end
      local targets = table.map(table.filter(room.alive_players, function (p)
        return p:getNextAlive() == tar or tar:getNextAlive() == p
      end), Util.IdMapper)
      if #targets == 0 then return false end
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#xiaoren-damage::" .. tar.id,
        skill_name = xiaoren.name,
        cancelable = false
      })
      tar = room:getPlayerById(targets[1])
      room:damage{
        from = player,
        to = tar,
        damage = 1,
        skillName = xiaoren.name,
      }
    end
  end,

  can_refresh = function (self, event, target, player)
    return not player.dead and player:getMark("xiaoren_break-turn") == 0 and player:usedSkillTimes(xiaoren.name) > 0
  end,
  on_refresh = function (self, event, target, player)
    player.room:setPlayerMark(player, "xiaoren_break-turn", 1)
  end,
})

return xiaoren
