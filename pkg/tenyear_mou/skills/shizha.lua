local shizha = fk.CreateSkill {
  name = "shizha",
}

Fk:loadTranslationTable{
  ["shizha"] = "识诈",
  [":shizha"] = "每回合限一次，其他角色使用牌时，若此牌是其本回合体力变化后使用的第一张牌，你可以令此牌无效并获得之。",

  ["#shizha-invoke"] = "识诈：是否令 %dest 使用的%arg无效并获得之？",

  ["$shizha1"] = "不好，江东鼠辈欲趁东风来袭！",
  ["$shizha2"] = "江上起东风，恐战局生变。",
}

shizha:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shizha.name) and target ~= player and player:usedSkillTimes(shizha.name, Player.HistoryTurn) == 0 then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event == nil then return false end
      local changehp_event_id = 1
      room.logic:getEventsByRule(GameEvent.ChangeHp, 1, function (e)
        if e.data.who == target and e.data.num ~= 0 then
          changehp_event_id = e.end_id
          return true
        end
      end, turn_event.id)
      if changehp_event_id == 1 then return false end
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local use_event_id = 1
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.data.from == target.id then
          use_event_id = e.id
        end
      end, changehp_event_id)
      return use_event_id == use_event.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shizha.name,
      prompt = "#shizha-invoke::"..target.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.toCard = nil
    data:removeAllTargets()
    if room:getCardArea(data.card) == Card.Processing then
      room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, shizha.name, nil, true, player)
    end
  end,
})

return shizha
