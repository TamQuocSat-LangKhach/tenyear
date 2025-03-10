local weilu = fk.CreateSkill {
  name = "weilu"
}

Fk:loadTranslationTable{
  ['weilu'] = '威虏',
  ['@@weilu'] = '威虏',
  [':weilu'] = '锁定技，当你受到其他角色造成的伤害后，伤害来源在你的下回合出牌阶段开始时失去体力至1，回合结束时其回复以此法失去的体力值。',
  ['$weilu1'] = '贼人势大，需从长计议。',
  ['$weilu2'] = '时机未到，先行撤退。',
}

weilu:addEffect(fk.Damaged, {
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(weilu.name) and data.from and not data.from.dead and data.from ~= player
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(data.from, "@@weilu", 1)
  end,

  can_refresh = function(self, event, target, player, data)
    local room = player.room
    if target == player and player:hasSkill(weilu.name) then
      local players = table.filter(room:getOtherPlayers(player), function(p)
        return p:getMark("@@weilu") > 0 or p:getMark("weilu".."-turn") > 0
      end)
      return #players > 0 and (player.phase == Player.Play or player.phase == Player.Finish)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local players = table.filter(room:getOtherPlayers(player), function(p)
      return p:getMark("@@weilu") > 0 or p:getMark("weilu".."-turn") > 0
    end)
    if player.phase == Player.Play then
      for _, p in ipairs(players) do
        room:setPlayerMark(p, weilu.name.."-turn", p:getMark("@@weilu"))
        room:setPlayerMark(p, weilu.name, p.hp - 1)
        room:loseHp(p, p:getMark(weilu.name), weilu.name)
      end
    elseif player.phase == Player.Finish then
      for _, p in ipairs(players) do
        local n = p:getMark(weilu.name)
        if n > 0 then
          room:recover({
            who = p,
            num = n,
            skillName = weilu.name,
          })
        end
        if p:getMark("@@weilu") == p:getMark("weilu".."-turn") then
          room:setPlayerMark(p, "@@weilu", 0)
        end
        room:setPlayerMark(p, weilu.name, 0)
      end
    end
  end,
})

return weilu
