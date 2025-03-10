local shouzhi = fk.CreateSkill {
  name = "shouzhi"
}

Fk:loadTranslationTable{
  ['shouzhi'] = '守执',
  ['@shouzhi-turn'] = '守执',
  [':shouzhi'] = '锁定技，一名角色的回合结束时，若你的手牌数：大于此回合开始时的手牌数，你弃置一张手牌；小于此回合开始时的手牌数，你摸两张牌。',
  ['$shouzhi1'] = '日暮且眠岗上松，散尽千金买东风。',
  ['$shouzhi2'] = '这沽来的酒，哪有赊的有味道。',
}

shouzhi:addEffect(fk.TurnEnd, {
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player)
    if player:hasSkill(shouzhi) then
      local x = player:getMark("@shouzhi-turn")
      if x == 0 then return false end
      if type(x) == "string" then x = 0 end
      return x ~= player:getHandcardNum()
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local x = player:getMark("@shouzhi-turn")
    if x == 0 then return false end
    if type(x) == "string" then x = 0 end
    x = x - player:getHandcardNum()
    player:broadcastSkillInvoke(shouzhi.name)
    if x > 0 then
      room:notifySkillInvoked(player, shouzhi.name, "drawcard")
      player:drawCards(2, shouzhi.name)
    elseif x < 0 then
      room:notifySkillInvoked(player, shouzhi.name, "negative")
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = shouzhi.name,
        cancelable = false
      })
    end
  end,
})

shouzhi:addEffect(fk.TurnStart, {
  can_refresh = function (skill, event, target, player)
    return player:hasSkill(shouzhi, true)
  end,
  on_refresh = function (skill, event, target, player)
    local x = player:getHandcardNum()
    player.room:setPlayerMark(player, "@shouzhi-turn", x > 0 and x or "0")
  end,
})

return shouzhi
