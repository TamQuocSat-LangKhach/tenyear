local yuyan = fk.CreateSkill {
  name = "yuyan",
}

Fk:loadTranslationTable{
  ["yuyan"] = "预言",
  [":yuyan"] = "每轮开始时，你选择一名角色，若其是本轮第一个进入濒死状态的角色，则你获得技能〖奋音〗直到你的回合结束；"..
  "若其是本轮第一个造成伤害的角色，则你摸两张牌。",

  ["#yuyan-choose"] = "预言：选择一名角色，若其是本轮第一个进入濒死状态或造成伤害的角色，你获得效果",
  ["@@yuyan-round"] = "预言",

  ["$yuyan1"] = "差若毫厘，谬以千里，需慎之。",
  ["$yuyan2"] = "六爻之动，三极之道也。",
}

yuyan:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuyan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#yuyan-choose",
      skill_name = yuyan.name,
      cancelable = false,
      no_indicate = true,
    })[1]
    room:setPlayerMark(player, "yuyan-round", to.id)
  end,
})

yuyan:addEffect(fk.EnterDying, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark("yuyan-round") ~= 0 and player:getMark("yuyan_dying-round") == 0 then
      player.room:setPlayerMark(player, "yuyan_dying-round", 1)
      if player:getMark("yuyan-round") == target.id and not player:hasSkill("ty__fenyin", true) then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room.logic:getCurrentEvent():findParent(GameEvent.Dying, true):addCleaner(function()
      room:setPlayerMark(player, "yuyan-tmp", 1)
      room:handleAddLoseSkills(player, "ty__fenyin")
    end)
  end,
})

yuyan:addEffect(fk.Damage, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark("yuyan-round") ~= 0 and player:getMark("yuyan_damage-round") == 0 and target then
      player.room:setPlayerMark(player, "yuyan_damage-round", 1)
      if player:getMark("yuyan-round") == target.id then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, yuyan.name)
  end,
})

yuyan:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("yuyan-tmp") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "yuyan-tmp", 0)
    room:handleAddLoseSkills(player, "-ty__fenyin")
  end,
})

return yuyan
