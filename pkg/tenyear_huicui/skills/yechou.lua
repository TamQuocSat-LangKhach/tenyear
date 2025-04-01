local yechou = fk.CreateSkill {
  name = "yechou",
}

Fk:loadTranslationTable{
  ["yechou"] = "业仇",
  [":yechou"] = "你死亡时，你可以选择一名已损失的体力值大于1的角色。若如此做，每名角色的结束阶段，其失去1点体力，直到其下回合开始。",

  ["#yechou-choose"] = "表召：选择一名角色，其每个结束阶段都会失去1点体力，直到其回合开始！",

  ["@@yechou"] = "业仇",
  ["$yechou1"] = "会有人替我报仇的！",
  ["$yechou2"] = "我的门客，是不会放过你的！",
}

yechou:addEffect(fk.Death, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yechou.name, false, true) and
      table.find(player.room.alive_players, function (p)
        return p:getLostHp() > 1
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getLostHp() > 1
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#yechou-choose",
      skill_name = yechou.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(event:getCostData(self).to[1], "@@yechou", 1)
  end,
})

yechou:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and player:getMark("@@yechou") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, player:getMark("@@yechou"), yechou.name)
  end,
})

yechou:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yechou") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yechou", 0)
  end,
})

return yechou
