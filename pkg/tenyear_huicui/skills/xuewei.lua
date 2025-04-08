local xuewei = fk.CreateSkill {
  name = "ty__xuewei",
}

Fk:loadTranslationTable{
  ["ty__xuewei"] = "血卫",
  [":ty__xuewei"] = "结束阶段，你可以选择一名体力值不大于你的角色。直到你的下回合开始前，该角色受到伤害时，防止此伤害，"..
  "然后你失去1点体力并与其各摸一张牌。",

  ["@@ty__xuewei"] = "血卫",
  ["#ty__xuewei-choose"] = "血卫：指定一名体力值不大于你的角色，当其受到伤害时防止伤害，你失去1点体力并与其各摸一张牌",

  ["$ty__xuewei1"] = "慷慨赴国难，青山侠骨香。",
  ["$ty__xuewei2"] = "舍身卫主之志，死犹未悔！",
}

xuewei:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuewei.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p.hp <= player.hp
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__xuewei-choose",
      skill_name = xuewei.name,
      cancelable = true,
    })

    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMark(to, "@@ty__xuewei", player.id)
    room:setPlayerMark(player, xuewei.name, to.id)
  end,
})

xuewei:addEffect(fk.DamageInflicted, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.contains(target:getTableMark("@@ty__xuewei"), player.id)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    room:loseHp(player, 1, xuewei.name)
    if not player.dead then
      player:drawCards(1, xuewei.name)
    end
    if not target.dead then
      target:drawCards(1, xuewei.name)
    end
  end,
})

local spec = {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(xuewei.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark(xuewei.name))
    room:setPlayerMark(player, xuewei.name, 0)
    room:removeTableMark(to, "@@ty__xuewei", player.id)
  end,
}

xuewei:addEffect(fk.TurnStart, spec)
xuewei:addEffect(fk.Death, spec)

return xuewei
