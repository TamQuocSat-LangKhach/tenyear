local biejun = fk.CreateSkill {
  name = "biejun"
}

Fk:loadTranslationTable{
  ['biejun'] = '别君',
  ['@@biejun-inhand-turn'] = '别君',
  ['#biejun-invoke'] = '别君：你可以翻面，防止你受到的伤害',
  ['biejun&'] = '别君',
  [':biejun'] = '其他角色出牌阶段限一次，其可以交给你一张手牌。当你受到伤害时，若你手牌中没有本回合以此法获得的牌，你可以翻面并防止此伤害。',
  ['$biejun1'] = '彼岸荼蘼远，落寞北风凉。',
  ['$biejun2'] = '此去经年，不知何时能归？',
}

biejun:addEffect(fk.DamageInflicted, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(biejun.name) and target == player and
      table.every(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@biejun-inhand-turn") == 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = biejun.name, prompt = "#biejun-invoke"})
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    return true
  end,
})

biejun.on_acquire = function(self, player)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    if p ~= player and not p:hasSkill("biejun&", true, true) then
      room:handleAddLoseSkills(p, "biejun&", nil, false, true)
    end
  end
end

biejun.on_lose = function(self, player)
  local room = player.room
  local skill_owners = table.filter(room.alive_players, function (p)
    return p:hasSkill(biejun.name, true)
  end)
  if #skill_owners == 0 then
    for _, p in ipairs(room.alive_players) do
      if p:hasSkill("biejun&", true, true) then
        room:handleAddLoseSkills(p, "-biejun&", nil, false, true)
      end
    end
  elseif #skill_owners == 1 then
    local p = skill_owners[1]
    if p:hasSkill("biejun&", true, true) then
      room:handleAddLoseSkills(p, "-biejun&", nil, false, true)
    end
  end
end

return biejun
