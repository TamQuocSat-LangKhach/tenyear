local shouzhiEX = fk.CreateSkill {
  name = "shouzhiEX"
}

Fk:loadTranslationTable{
  ['shouzhiEX'] = '守执',
  ['@shouzhi-turn'] = '守执',
  ['shouzhi'] = '守执',
  ['#shouzhi-draw'] = '是否发动 守执，摸两张牌',
  ['#shouzhi-discard'] = '是否发动 守执，弃置一张牌',
  [':shouzhiEX'] = '一名角色的回合结束时，若你的手牌数：大于此回合开始时的手牌数，你可以弃置一张手牌；小于此回合开始时的手牌数，你可以摸两张牌。',
}

shouzhiEX:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(shouzhiEX.name) then
      local x = player:getMark("@shouzhi-turn")
      if x == 0 then return false end
      if type(x) == "string" then x = 0 end
      return x ~= player:getHandcardNum()
    end
  end,
  on_cost = function(self, event, target, player)
    local x = player:getMark("@shouzhi-turn")
    if x == 0 then return false end
    if type(x) == "string" then x = 0 end
    x = x - player:getHandcardNum()
    if x > 0 then
      if player.room:askToSkillInvoke(player, {skill_name=shouzhiEX.name, prompt="#shouzhi-draw"}) then
        event:setCostData(skill, {})
        return true
      end
    else
      local cards = player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name=shouzhiEX.name,
        cancelable=true,
        prompt="#shouzhi-discard",
        skip_discard=true
      })
      if #cards > 0 then
        event:setCostData(skill, cards)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(shouzhiEX.name)
    local cost_data = event:getCostData(skill)
    if #cost_data > 0 then
      room:notifySkillInvoked(player, shouzhiEX.name, "negative")
      room:throwCard(cost_data, shouzhiEX.name, player, player)
    else
      room:notifySkillInvoked(player, shouzhiEX.name, "drawcard")
      player:drawCards(2, shouzhiEX.name)
    end
  end,
})

shouzhiEX:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player)
    return player:hasSkill(shouzhiEX.name, true)
  end,
  on_refresh = function (skill, event, target, player)
    local x = player:getHandcardNum()
    player.room:setPlayerMark(player, "@shouzhi-turn", x > 0 and x or "0")
  end,
})

return shouzhiEX
