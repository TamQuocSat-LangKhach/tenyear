local shengdu = fk.CreateSkill {
  name = "shengdu",
}

Fk:loadTranslationTable{
  ["shengdu"] = "生妒",
  [":shengdu"] = "回合开始时，你可以选择一名没有“生妒”标记的其他角色，该角色获得“生妒”标记。有“生妒”标记的角色摸牌阶段摸牌后，"..
  "每有一个“生妒”你摸等量的牌，然后移去“生妒”标记。",

  ["#shengdu-choose"] = "生妒：选择一名角色，其下次摸牌阶段摸牌后，你摸等量的牌",
  ["@shengdu"] = "生妒",

  ["$shengdu1"] = "姐姐有的，妹妹也要有。",
  ["$shengdu2"] = "你我同为佳丽，凭甚汝得独宠？",
}

shengdu:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shengdu.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:getMark("@shengdu") == 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player.room:getOtherPlayers(player, false), function (p)
      return p:getMark("@shengdu") == 0
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#shengdu-choose",
      skill_name = shengdu.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(event:getCostData(self).tos[1], "@shengdu")
  end,
})

shengdu:addEffect(fk.AfterDrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shengdu.name) and target:getMark("@shengdu") > 0 and data.n > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(data.n * target:getMark("@shengdu"), shengdu.name)
    room:setPlayerMark(target, "@shengdu", 0)
  end,
})

shengdu:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if not table.find(room:getOtherPlayers(player, false), function (p)
    return p:hasSkill(shengdu.name, true)
  end) then
    for _, p in pairs(room.alive_players) do
      room:setPlayerMark(p, "@shengdu", 0)
    end
  end
end)

return shengdu
