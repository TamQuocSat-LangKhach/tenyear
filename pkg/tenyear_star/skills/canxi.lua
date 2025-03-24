local canxi = fk.CreateSkill {
  name = "canxi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["canxi"] = "残玺",
  [":canxi"] = "锁定技，游戏开始时，你获得场上各势力的“玺角”标记，其中魏、蜀、吴、群每少一个势力你加1点体力上限。每轮开始时，"..
  "你选择一个“玺角”势力并选择一个效果生效直到下轮开始：<br>"..
  "「妄生」：该势力角色每回合首次造成伤害+1，计算与其他角色距离-1；<br>"..
  "「向死」：该势力其他角色每回合首次回复体力后失去1点体力，每回合对你使用的第一张牌无效。",

  ["@canxi1-round"] = "「妄生」",
  ["@canxi2-round"] = "「向死」",
  ["@canxi_exist_kingdoms"] = "",
  ["#canxi-choice1"] = "残玺：选择本轮生效的“玺角”势力",
  ["canxi1"] = "「妄生」",
  ["canxi2"] = "「向死」",
  ["#canxi-choice2"] = "残玺：选择本轮对 %arg 势力角色生效的效果",

  ["$canxi1"] = "大势散于天下，全宝玺者其谁？",
  ["$canxi2"] = "汉祚已僵待死，吾可取而代之。",
}

canxi:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(canxi.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    room:setPlayerMark(player, "@canxi_exist_kingdoms", kingdoms)
    local n = #table.filter({"wei", "shu", "wu", "qun"}, function(s)
      return not table.contains(kingdoms, s)
    end)
    if n > 0 then
      room:changeMaxHp(player, n)
    end
  end,
})

canxi:addEffect(fk.RoundStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(canxi.name) and #player:getTableMark("@canxi_exist_kingdoms") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice1 = room:askToChoice(player, {
      choices = player:getMark("@canxi_exist_kingdoms"),
      skill_name = canxi.name,
      prompt = "#canxi-choice1",
    })
    local choice2 = room:askToChoice(player, {
      choices = {"canxi1", "canxi2"},
      skill_name = canxi.name,
      prompt = "#canxi-choice2:::"..choice1,
      cancelable = true,
    })
    room:setPlayerMark(player, "@"..choice2.."-round", choice1)
  end,
})

canxi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(canxi.name) and
      target and player:getMark("@canxi1-round") == target.kingdom and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1)
  end,
})

canxi:addEffect(fk.HpRecover, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(canxi.name) and
      player:getMark("@canxi2-round") == target.kingdom and
      not target.dead and target ~= player and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(target, 1, canxi.name)
  end,
})

canxi:addEffect(fk.CardUsing, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(canxi.name) and
      target ~= player and player:getMark("@canxi2-round") == target.kingdom and
      table.contains(data.tos, player) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function (self, event, target, player, data)
    data:removeAllTargets()
  end,
})

canxi:addEffect("distance", {
  correct_func = function(self, from, to)
    return -#table.filter(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(canxi.name) and p:getMark("@canxi1-round") == from.kingdom
    end)
  end,
})

canxi:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@canxi_exist_kingdoms", 0)
  room:setPlayerMark(player, "@canxi1-round", 0)
  room:setPlayerMark(player, "@canxi2-round", 0)
end)

return canxi
