local fudao = fk.CreateSkill {
  name = "fudao",
}

Fk:loadTranslationTable{
  ["fudao"] = "抚悼",
  [":fudao"] = "游戏开始时，你选择一名其他角色：<br>你与其每回合首次使用牌指定对方为目标后，各摸两张牌；<br>杀死你或该角色的其他角色获得"..
  "“决裂”标记，你或该角色对有“决裂”的角色造成的伤害+1；<br>“决裂”角色使用黑色牌指定你为目标后，其本回合不能再使用牌。",

  ["@@fudao_juelie"] = "决裂",
  ["#fudao-choose"] = "抚悼：请选择要“抚悼”的角色",
  ["@@fudao"] = "抚悼",
  ["@@fudao-turn"] = "抚悼 不能出牌",

  ["$fudao1"] = "弑子之仇，不共戴天！",
  ["$fudao2"] = "眼中泪绝，尽付仇怆。",
}

fudao:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fudao.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#fudao-choose",
      skill_name = fudao.name,
      cancelable = false,
    })[1]
    room:addTableMark(player, "@@fudao", to.id)
    room:addTableMark(to, "@@fudao", player.id)
  end,
})

fudao:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fudao.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      if target == player and table.contains(player:getTableMark("@@fudao"), data.to.id) then
        return true
      end
      if data.to == player and table.contains(player:getTableMark("@@fudao"), target.id) then
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target, data.to}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = {target, data.to}
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards(2, fudao.name)
      end
    end
  end,
})

fudao:addEffect(fk.Death, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fudao.name, false, target == player) and data.killer and not data.killer.dead and
      data.killer ~= player then
      if target == player then
        return table.find(player.room.alive_players, function (p)
          return table.contains(p:getTableMark("@@fudao"), player.id)
        end)
      else
        return table.contains(player:getTableMark("@@fudao"), target.id)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if table.contains(p:getTableMark("@@fudao"), target.id) then
        room:addTableMark(data.killer, "@@fudao_juelie", p.id)
      end
    end
  end,

  late_refresh = true,
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:removeTableMark(p, "@@fudao_juelie", player.id)
      for _, _ in ipairs(p:getTableMark("@@fudao")) do
        room:removeTableMark(p, "@@fudao", player.id)
      end
    end
  end,
})

fudao:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if room:removeTableMark(player, "@@fudao", p.id) then
      room:removeTableMark(p, "@@fudao", player.id)
    end
  end
end)

fudao:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.color == Card.Black and
      player:hasSkill(fudao.name) and
      table.contains(data.from:getTableMark("@@fudao_juelie"), player.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(data.from, "@@fudao-turn", 1)
  end,
})

fudao:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.to:getTableMark("@@fudao_juelie"), player.id)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(#table.filter(data.to:getTableMark("@@fudao_juelie"), function (id)
      return id == player.id
    end))
  end,
})

fudao:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and player:getMark("@@fudao-turn") > 0
  end,
})

return fudao
