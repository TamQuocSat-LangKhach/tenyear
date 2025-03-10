local ty__xuewei = fk.CreateSkill {
  name = "ty__xuewei"
}

Fk:loadTranslationTable{
  ['ty__xuewei'] = '血卫',
  ['@@ty__xuewei'] = '血卫',
  ['#ty__xuewei-choose'] = '血卫：你可以指定一名体力值不大于你的角色<br>直到你下回合开始前防止其受到的伤害，你失去1点体力并与其各摸一张牌',
  [':ty__xuewei'] = '结束阶段，你可以选择一名体力值不大于你的角色。直到你的下回合开始前，该角色受到伤害时，防止此伤害，然后你失去1点体力并与其各摸一张牌。',
  ['$ty__xuewei1'] = '慷慨赴国难，青山侠骨香。',
  ['$ty__xuewei2'] = '舍身卫主之志，死犹未悔！',
}

ty__xuewei:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(table.filter(player.room:getAlivePlayers(), function(p)
        return p.hp <= player.hp
      end), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__xuewei-choose",
      skill_name = ty__xuewei.name,
      cancelable = true
    })

    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:addPlayerMark(room:getPlayerById(event:getCostData(self)), "@@ty__xuewei", 1)
    player.tag[ty__xuewei.name] = {event:getCostData(self)}
  end,
})

ty__xuewei:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player)
    return target:getMark("@@ty__xuewei") > 0 and player.tag[ty__xuewei.name][1] == target.id
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:loseHp(player, 1, ty__xuewei.name)
    if not player.dead then
      player:drawCards(1, ty__xuewei.name)
    end
    if not target.dead then
      target:drawCards(1, ty__xuewei.name)
    end
    return true
  end,
})

ty__xuewei:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player)
    return target == player and player:hasSkill(ty__xuewei) and
      player.tag[ty__xuewei.name] and #player.tag[ty__xuewei.name] > 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(player.tag[ty__xuewei.name][1])
    room:setPlayerMark(to, "@@ty__xuewei", 0)
    player.tag[ty__xuewei.name] = {}
  end,
})

return ty__xuewei
