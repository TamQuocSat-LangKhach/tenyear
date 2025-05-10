local linjiez = fk.CreateSkill {
  name = "linjiez",
}

Fk:loadTranslationTable{
  ["linjiez"] = "凛界",
  [":linjiez"] = "每轮开始时，你可以对一名没有“凛”的角色造成1点伤害，然后令其获得一枚“凛”标记。有“凛”的其他角色受到伤害后，其随机弃置一张手牌，"..
  "若其因此弃置了最后一张手牌，你对其造成1点伤害并移去其“凛”。",

  ["@zhonghui_piercing"] = "凛",
  ["#linjiez-choose"] = "凛界：你可以对一名没有“凛”的角色造成伤害，并令其获得一枚“凛”",

  ["$linjiez1"] = "",
  ["$linjiez2"] = "",
}

linjiez:addEffect(fk.RoundStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(linjiez.name) and
      table.find(player.room.alive_players, function(p)
        return p:getMark("@zhonghui_piercing") == 0
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:getMark("@zhonghui_piercing") == 0
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = linjiez.name,
      prompt = "#linjiez-choose",
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
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = linjiez.name,
    }
    if not to.dead then
      room:addPlayerMark(to, "@zhonghui_piercing", 1)
    end
  end,
})

linjiez:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target ~= player and player:hasSkill(linjiez.name) and
      target:getMark("@zhonghui_piercing") > 0 and not target:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(target:getCardIds("h"), function (id)
      return not target:prohibitDiscard(id)
    end)
    if #cards > 0 then
      local yes = #cards == 1 and target:getHandcardNum() == 1
      room:throwCard(table.random(cards), linjiez.name, target, target)
      if yes and not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = linjiez.name,
        }
        room:setPlayerMark(target, "@zhonghui_piercing", 0)
      end
    end
  end,
})

return linjiez
