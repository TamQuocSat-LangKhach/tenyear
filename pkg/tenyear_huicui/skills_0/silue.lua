local silue = fk.CreateSkill {
  name = "silue"
}

Fk:loadTranslationTable{
  ['silue'] = '私掠',
  ['#silue-choose'] = '私掠：选择一名其他角色，作为“私掠”角色',
  ['#silue-prey'] = '私掠：是否获得 %dest 的一张牌？',
  ['@silue'] = '私掠',
  ['#silue-card'] = '私掠：获得 %dest 的一张牌',
  ['#silue-slash'] = '私掠：你需对 %dest 使用一张【杀】，否则弃置一张手牌',
  [':silue'] = '游戏开始时，你选择一名其他角色为“私掠”角色。<br>“私掠”角色造成伤害后，你可以获得受伤角色一张牌（每回合每名角色限一次）。<br>“私掠”角色受到伤害后，你需对伤害来源使用一张【杀】（无距离限制），否则你弃置一张手牌。',
  ['$silue1'] = '劫尔之富，济我之贫！',
  ['$silue2'] = '徇私而动，劫财掠货。',
}

silue:addEffect(fk.GameStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and true
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      prompt = "#silue-choose",
      skill_name = skill.name,
      targets = targets
    })
    if #to > 0 then
      event:setCostData(skill, to[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(skill.name)
    room:notifySkillInvoked(player, skill.name, "special")
    room:setPlayerMark(player, skill.name, event:getCostData(skill))
    room:setPlayerMark(player, "@"..skill.name, room:getPlayerById(event:getCostData(skill)).general)
  end,
})

silue:addEffect(fk.Damage, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and target and player:getMark(skill.name) == target.id and not player.dead and
      not data.to.dead and not data.to:isNude() and player:getMark("silue_preyed"..data.to.id.."-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = skill.name,
      prompt = "#silue-prey::"..data.to.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(skill.name)
    room:notifySkillInvoked(player, skill.name, "offensive")
    room:doIndicate(player.id, {data.to.id})
    room:setPlayerMark(player, "silue_preyed"..data.to.id.."-turn", 1)
    local id = room:askToChooseCard(player, {
      target = data.to,
      flag = "he",
      skill_name = skill.name,
      prompt = "#silue-card::"..data.to.id
    })
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
  end,
})

silue:addEffect(fk.Damaged, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and true
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(skill.name)
    if (not data.from or data.from.dead) and not player:isKongcheng() then
      room:notifySkillInvoked(player, skill.name, "negative")
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = skill.name,
        cancelable = false
      })
    else
      local use = room:askToUseCard(player, {
        pattern = "slash",
        prompt = "#silue-slash::"..data.from.id,
        extra_data = {must_targets = {data.from.id}, bypass_distances = true, bypass_times = true},
        skill_name = skill.name
      })
      if use then
        room:notifySkillInvoked(player, skill.name, "offensive")
        room:useCard(use)
      elseif not player:isKongcheng() then
        room:notifySkillInvoked(player, skill.name, "negative")
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = skill.name,
          cancelable = false
        })
      end
    end
  end,
})

return silue
