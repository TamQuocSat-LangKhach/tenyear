local ty__xingzhao = fk.CreateSkill {
  name = "ty__xingzhao"
}

Fk:loadTranslationTable{
  ['ty__xingzhao'] = '兴棹',
  [':ty__xingzhao'] = '锁定技，场上受伤的角色为1个或以上，你获得〖恂恂〗；2个或以上，你装备区进入或离开牌时摸一张牌；3个或以上，你跳过判定和弃牌阶段；0个、4个或以上，你造成的伤害+1。',
  ['$ty__xingzhao1'] = '野棹出浅滩，借风当显威。',
  ['$ty__xingzhao2'] = '御棹水中行，前路皆助力。',
}

local function countWounded(room)
  return #table.filter(room.alive_players, function(p) return p:isWounded() end)
end

ty__xingzhao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    local n = countWounded(player.room)
    return target == player and player.phase == Player.Draw and not player:hasSkill("xunxun", true) and n > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "xunxun", skill.name, true, false)
  end,
})

ty__xingzhao:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    local n = countWounded(player.room)
    if n > 1 then
      local move_count = 0
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              move_count = move_count + 1
            end
          end
        elseif move.to == player.id and move.toArea == Card.PlayerEquip then
          move_count = move_count + #move.moveInfo
        end
      end
      if move_count > 0 then
        event:setCostData(skill, move_count)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty__xingzhao.name)
    room:notifySkillInvoked(player, ty__xingzhao.name, "drawcard")
    player:drawCards(event:getCostData(skill), ty__xingzhao.name)
  end,
})

ty__xingzhao:addEffect(fk.EventPhaseChanging, {
  can_trigger = function(self, event, target, player, data)
    local n = countWounded(player.room)
    return target == player and (data.to == Player.Judge or data.to == Player.Discard) and n > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty__xingzhao.name)
    room:notifySkillInvoked(player, ty__xingzhao.name, "defensive")
    return true
  end,
})

ty__xingzhao:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    local n = countWounded(player.room)
    return target == player and (n == 0 or n > 3)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty__xingzhao.name)
    room:notifySkillInvoked(player, ty__xingzhao.name, "offensive")
    data.damage = data.damage + 1
  end,
})

return ty__xingzhao
