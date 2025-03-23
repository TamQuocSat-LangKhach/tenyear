local ty__aichen = fk.CreateSkill {
  name = "ty__aichen"
}

Fk:loadTranslationTable{
  ['ty__aichen'] = '哀尘',
  ['ty__luochong'] = '落宠',
  [':ty__aichen'] = '锁定技，若剩余牌堆数大于80，当你发动〖落宠〗弃置自己区域内的牌后，你摸两张牌；若剩余牌堆数大于40，你跳过弃牌阶段；若剩余牌堆数小于40，当你成为♠牌的目标后，你不能响应此牌。',
  ['$ty__aichen1'] = '君可负妾，然妾不负君。',
  ['$ty__aichen2'] = '所思所想，皆系陛下。',
}

local dynamic_desc = function(self, player)
  local x = #Fk:currentRoom().draw_pile
  local texts = {"ty__aichen_inner", "", "", ""}
  if x > 80 then
    texts[2] = "<font color='#E0DB2F'>"
  end
  if x > 40 then
    texts[3] = "<font color='#E0DB2F'>"
  elseif x < 40 then
    texts[4] = "<font color='#E0DB2F'>"
  end
  return table.concat(texts, ":")
end

ty__aichen:addEffect(fk.AfterCardsMove, {
  mute = true,
  frequency = Skill.Compulsory,
  dynamic_desc = dynamic_desc,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty__aichen.name) then
      if #player.room.draw_pile > 80 and player:usedSkillTimes(ty__aichen.name, Player.HistoryRound) == 0 then
        for _, move in ipairs(data) do
          if move.skillName == "ty__luochong" and move.from == player.id then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty__aichen.name, 1)
    room:notifySkillInvoked(player, ty__aichen.name, "drawcard")
    player:drawCards(2, ty__aichen.name)
  end,
})

ty__aichen:addEffect(fk.EventPhaseChanging, {
  mute = true,
  frequency = Skill.Compulsory,
  dynamic_desc = dynamic_desc,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty__aichen.name) then
      if #player.room.draw_pile > 40 then
        return target == player and data.to == Player.Discard
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty__aichen.name, 1)
    room:notifySkillInvoked(player, ty__aichen.name, "defensive")
    return true
  end,
})

ty__aichen:addEffect(fk.TargetConfirmed, {
  mute = true,
  frequency = Skill.Compulsory,
  dynamic_desc = dynamic_desc,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty__aichen.name) then
      if #player.room.draw_pile < 40 then
        return target == player and data.card.type ~= Card.TypeEquip and data.card.suit == Card.Spade
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(ty__aichen.name, 2)
    room:notifySkillInvoked(player, ty__aichen.name, "negative")
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertIfNeed(data.disresponsiveList, player.id)
  end,
})

return ty__aichen
