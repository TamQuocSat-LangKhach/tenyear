local yechou = fk.CreateSkill {
  name = "yechou"
}

Fk:loadTranslationTable{
  ['yechou'] = '业仇',
  ['#yechou-choose'] = '你可以发动表召，选择一名角色，令其于下个回合开始之前的每名角色的结束阶段都会失去1点体力',
  ['@@yechou'] = '业仇',
  ['#yechou_delay'] = '业仇',
  [':yechou'] = '你死亡时，你可以选择一名已损失的体力值大于1的角色。若如此做，每名角色的结束阶段，其失去1点体力，直到其下回合开始。',
  ['$yechou1'] = '会有人替我报仇的！',
  ['$yechou2'] = '我的门客，是不会放过你的！',
}

yechou:addEffect(fk.Death, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yechou.name, false, true) and table.find(player.room.alive_players, function (p)
      return p:getLostHp() > 1
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getLostHp() > 1
    end)
    local p = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#yechou-choose",
      skill_name = yechou.name,
      cancelable = true,
    })
    if #p > 0 then
      event:setCostData(self, p[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    room:addPlayerMark(to, "@@yechou", 1)
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yechou") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yechou", 0)
  end,
})

yechou:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and not player.dead and player:getMark("@@yechou") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, yechou.name)
  end,
})

return yechou
