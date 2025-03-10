local fudao = fk.CreateSkill {
  name = "fudao"
}

Fk:loadTranslationTable{
  ['fudao'] = '抚悼',
  ['@@juelie'] = '决裂',
  ['#fudao-choose'] = '抚悼：请选择要“抚悼”的角色',
  ['@@fudao'] = '抚悼',
  ['@@fudao-turn'] = '抚悼 不能出牌',
  ['#fudao_delay'] = '抚悼',
  [':fudao'] = '游戏开始时，你选择一名其他角色，你与其每回合首次使用牌指定对方为目标后，各摸两张牌。杀死你或该角色的其他角色获得“决裂”标记，你或该角色对有“决裂”的角色造成的伤害+1；“决裂”角色使用黑色牌指定你为目标后，其本回合不能再使用牌。',
  ['$fudao1'] = '弑子之仇，不共戴天！',
  ['$fudao2'] = '眼中泪绝，尽付仇怆。',
}

fudao:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(fudao)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:notifySkillInvoked(player, fudao.name)
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#fudao-choose",
      skill_name = fudao.name,
      cancelable = false,
      no_indicate = true
    })
    if #tos > 0 then
      room:setPlayerMark(player, fudao.name, tos[1].id)
      room:setPlayerMark(player, "@@fudao", 1)
      room:setPlayerMark(tos[1], "@@fudao", 1)
    end
  end,
})

fudao:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(fudao) then
      local to = player.room:getPlayerById(player:getMark(fudao.name))
      return ((player == target and player:getMark(fudao.name) == to.id) or (player == to and player:getMark(fudao.name) == target.id)) 
        and player:getMark("fudao_specified-turn") == 0
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:notifySkillInvoked(player, fudao.name)
    room:addPlayerMark(player, "fudao_specified-turn")
    local targets = {player.id, player:getMark(fudao.name)}
    room:sortPlayersByAction(targets)
    room:doIndicate(player.id, targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if p and not p.dead then
        room:drawCards(p, 2, fudao.name)
      end
    end
  end,
})

fudao:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(fudao, false, (player == target)) then
      local to = player.room:getPlayerById(player:getMark(fudao.name))
      return to ~= nil and ((player == target and not to.dead) or to == target) 
        and data.damage and data.damage.from and not data.damage.from.dead 
        and data.damage.from ~= player and data.damage.from ~= to
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:notifySkillInvoked(player, fudao.name, "offensive")
    player:broadcastSkillInvoke(fudao.name)
    room:setPlayerMark(data.damage.from, "@@juelie", 1)
  end,
})

fudao:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player)
    return target == player and data.from ~= player.id 
      and player.room:getPlayerById(data.from):getMark("@@juelie") > 0 
      and data.card.color == Card.Black
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:notifySkillInvoked(player, fudao.name, "control")
    player:broadcastSkillInvoke(fudao.name)
    room:setPlayerMark(room:getPlayerById(data.from), "@@fudao-turn", 1)
  end,
})

-- 添加延迟触发技和禁止技能效果
local fudao_delay = fk.CreateTriggerSkill{
  name = "#fudao_delay",
  mute = true,
}

fudao:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player)
    return player == target and player:getMark("@@fudao") > 0 
      and data.to:getMark("@@juelie") > 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:notifySkillInvoked(player, fudao.name, "offensive")
    if player:hasSkill(fudao, true) then
      player:broadcastSkillInvoke(fudao.name)
    end
    data.damage = data.damage + 1
  end,
})

local fudao_prohibit = fk.CreateProhibitSkill{
  name = "#fudao_prohibit",
}

fudao:addEffect('prohibit', {
  prohibit_use = function(self, player)
    return player:getMark("@@fudao-turn") > 0
  end,
})

return fudao
