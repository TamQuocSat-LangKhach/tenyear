local tianze = fk.CreateSkill {
  name = "tianze"
}

Fk:loadTranslationTable{
  ['tianze'] = '天则',
  ['#tianze-invoke'] = '是否发动 天则，弃置一张黑色牌来对%dest造成1点伤害',
  [':tianze'] = '当其他角色于其出牌阶段内使用第一张黑色牌结算结束后，你可以弃置一张黑色牌，对其造成1点伤害；当其他角色的黑色判定牌生效后，你摸一张牌。',
  ['$tianze1'] = '观天则，以断人事。',
  ['$tianze2'] = '乾元用九，乃见天则。',
}

tianze:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tianze) and target ~= player and data.card.color == Card.Black then
      if target.dead or target.phase ~= Player.Play or player:isNude() then return false end
      local room = player.room
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local x = target:getMark("tianze_record-turn")
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if use.from == target.id and use.card.color == Card.Black then
            x = e.id
            room:setPlayerMark(target, "tianze_record-turn", x)
            return true
          end
        end, Player.HistoryPhase)
      end
      return x == use_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      pattern = ".|.|spade,club|hand,equip",
      prompt = "#tianze-invoke::" .. target.id,
      cancelable = true
    })
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(tianze.name)
    room:notifySkillInvoked(player, tianze.name, "offensive")
    room:doIndicate(player.id, {target.id})
    room:throwCard(event:getCostData(self), tianze.name, player, player)
    room:damage{ from = player, to = target, damage = 1, skillName = tianze.name }
  end,
})

tianze:addEffect(fk.FinishJudge, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tianze) and target ~= player and data.card.color == Card.Black then
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(tianze.name)
    room:notifySkillInvoked(player, tianze.name, "drawcard")
    player:drawCards(1, tianze.name)
  end,
})

return tianze
