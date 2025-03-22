local jiangxi = fk.CreateSkill {
  name = "jiangxi",
}

Fk:loadTranslationTable{
  ["jiangxi"] = "将息",
  [":jiangxi"] = "一名角色回合结束时，若一号位本回合进入过濒死状态或未受到过伤害，你重置〖识命〗并摸一张牌。若所有角色均未受到过伤害，"..
  "你可以与当前回合角色各摸一张牌。",

  ["#jiangxi-invoke"] = "将息：你可以与 %dest 各摸一张牌",

  ["$jiangxi1"] = "典午忽兮，月酉没兮。",
  ["$jiangxi2"] = "周慕孔子遗风，可与刘、扬同轨。",
}

jiangxi:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jiangxi.name) then
      local room = player.room
      local lord = room:getPlayerBySeat(1)
      if lord == nil then return false end
      local choices = {}
      if #room.logic:getEventsOfScope(GameEvent.Dying, 1, function(e)
        return e.data.who == lord
      end, Player.HistoryTurn) > 0 then
        table.insert(choices, 1)
      end
      if #room.logic:getActualDamageEvents(1, function(e)
        return e.data.to == lord
      end, Player.HistoryTurn) == 0 then
        table.insertIfNeed(choices, 1)
      end
      if #room.logic:getActualDamageEvents(1, Util.TrueFunc, Player.HistoryTurn) == 0 then
        table.insert(choices, 2)
      end
      if #choices > 0 then
        event:setCostData(self, {choice = choices})
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if table.contains(choice, 1) then
      player:setSkillUseHistory("shiming", 0, Player.HistoryRound)
      player:drawCards(1, jiangxi.name)
    end
    if player.dead or target.dead then return end
    if table.contains(choice, 2) and
      room:askToSkillInvoke(player, {
        skill_name = jiangxi.name,
        prompt = "#jiangxi-invoke::"..target.id,
      }) then
      player:drawCards(1, jiangxi.name)
      if not target.dead then
        target:drawCards(1, jiangxi.name)
      end
    end
  end,
})

return jiangxi
