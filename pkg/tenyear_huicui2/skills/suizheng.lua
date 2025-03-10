local suizheng = fk.CreateSkill {
  name = "suizheng"
}

Fk:loadTranslationTable{
  ['suizheng'] = '随征',
  ['@@suizheng-turn'] = '随征',
  ['#suizheng-choose'] = '随征：令一名角色下回合出牌阶段使用【杀】无距离限制且次数+1',
  ['#suizheng-slash'] = '随征：你可以视为对其中一名角色使用【杀】',
  ['@@suizheng'] = '随征',
  [':suizheng'] = '结束阶段，你可以选择一名角色，该角色下个回合的出牌阶段使用【杀】无距离限制且可以多使用一张【杀】。然后其出牌阶段结束时，你可以视为对其本阶段造成过伤害的一名其他角色使用一张【杀】。',
  ['$suizheng1'] = '屡屡随征，战皆告捷。',
  ['$suizheng2'] = '将勇兵强，大举出征！',
}

suizheng:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(suizheng.name) then
      return target == player and player.phase == Player.Finish
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(room:getAlivePlayers(), Util.IdMapper)
    local prompt = "#suizheng-choose"
    local to = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = suizheng.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(skill, to[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))
    room:setPlayerMark(to, "@@suizheng", 1)
  end,
})

suizheng:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(suizheng.name) then
      return target:getMark("@@suizheng-turn") > 0 and target.phase == Player.Play
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets, prompt = {}, ""
    room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data[1]
      if damage.from == target and damage.to ~= player then
        table.insertIfNeed(targets, damage.to.id)
      end
    end, Player.HistoryPhase)
    if #targets == 0 then return end
    prompt = "#suizheng-slash"
    local to = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = suizheng.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(skill, to[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))
    room:useVirtualCard("slash", nil, player, to, suizheng.name, true)
  end,
})

suizheng:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player)
    return player:getMark("@@suizheng") > 0 and target == player
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "@@suizheng", 0)
    room:setPlayerMark(player, "@@suizheng-turn", 1)
  end,
})

local suizheng_targetmod = fk.CreateSkill {
  name = "#suizheng_targetmod"
}

suizheng_targetmod:addEffect('targetmod', {
  residue_func = function(self, player, skill_name, scope)
    if skill_name == "slash_skill" and player:getMark("@@suizheng-turn") > 0 and scope == Player.HistoryPhase and
      player.phase == Player.Play then
      return 1
    end
  end,
  bypass_distances = function(self, player, skill_name)
    return skill_name == "slash_skill" and player:getMark("@@suizheng-turn") > 0 and player.phase == Player.Play
  end,
})

return suizheng
