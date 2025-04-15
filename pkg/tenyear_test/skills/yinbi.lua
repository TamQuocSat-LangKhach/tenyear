local yinbi = fk.CreateSkill {
  name = "yinbi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yinbi"] = "隐避",
  [":yinbi"] = "锁定技，你的手牌上限等于场上手牌上限最大角色的手牌上限。若没有角色手牌数与你相同，你使用牌无距离次数限制。",

  ["$yinbi1"] = "",
  ["$yinbi2"] = "",
}

yinbi:addEffect("maxcards", {
  correct_func = function (self, player)
    if player:hasSkill(yinbi.name) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p ~= player and p:getMaxCards() > n then
          n = p:getMaxCards()
        end
      end
      local baseValue = math.max(player.hp, 0)
      local status_skills = Fk:currentRoom().status_skills[MaxCardsSkill] or Util.DummyTable
      local max_fixed = nil
      for _, skill in ipairs(status_skills) do
        if skill ~= self then
          local f = skill:getFixed(player)
          if f ~= nil then
            max_fixed = max_fixed and math.max(max_fixed, f) or f
          end
        end
      end
      if max_fixed then baseValue = math.max(max_fixed, 0) end
      for _, skill in ipairs(status_skills) do
        if skill ~= self then
          local c = skill:getCorrect(player)
          baseValue = baseValue + (c or 0)
        end
      end
      if n > baseValue then
        return n - baseValue
      end
    end
  end,
})

yinbi:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(yinbi.name) and
      table.every(player.room.alive_players, function (p)
        return p == player or p:getHandcardNum() ~= player:getHandcardNum()
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

yinbi:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(yinbi.name) and
      table.every(Fk:currentRoom().alive_players, function (p)
        return p == player or p:getHandcardNum() ~= player:getHandcardNum()
      end)
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card and player:hasSkill(yinbi.name) and
      table.every(Fk:currentRoom().alive_players, function (p)
        return p == player or p:getHandcardNum() ~= player:getHandcardNum()
      end)
  end,
})

return yinbi
