local shouzhi = fk.CreateSkill {
  name = "shouzhi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shouzhi"] = "守执",
  [":shouzhi"] = "锁定技，一名角色的回合结束时，若你的手牌数比回合开始时多，你弃置一张手牌；比回合开始时少，你摸两张牌。",

  ["@shouzhi-turn"] = "守执",

  ["$shouzhi1"] = "日暮且眠岗上松，散尽千金买东风。",
  ["$shouzhi2"] = "这沽来的酒，哪有赊的有味道。",
}

shouzhi:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shouzhi.name) and
      player:getHandcardNum() ~= tonumber(player:getMark("@shouzhi-turn"))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = tonumber(player:getMark("@shouzhi-turn"))
    n = n - player:getHandcardNum()
    player:broadcastSkillInvoke(shouzhi.name)
    if n > 0 then
      room:notifySkillInvoked(player, shouzhi.name, "drawcard")
      player:drawCards(2, shouzhi.name)
    elseif n < 0 then
      room:notifySkillInvoked(player, shouzhi.name, "negative")
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = shouzhi.name,
        cancelable = false,
      })
    end
  end,
})

shouzhi:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(shouzhi.name, true) or player:hasSkill("shouzhiEX", true)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@shouzhi-turn", tostring(player:getHandcardNum()))
  end,
})

return shouzhi
