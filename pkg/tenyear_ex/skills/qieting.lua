local qieting = fk.CreateSkill {
  name = "ty_ex__qieting",
}

Fk:loadTranslationTable{
  ["ty_ex__qieting"] = "窃听",
  [":ty_ex__qieting"] = "其他角色的回合结束时，若其本回合：没有造成过伤害，你可以将其装备区一张牌移至你的装备区；"..
  "没有对其他角色使用过牌，你摸一张牌。",

  ["#ty_ex__qieting-move"] = "窃听：你可以将 %dest 一张装备移至你的装备区",

  ["$ty_ex__qieting1"] = "谋略未定，窃听以察先机。",
  ["$ty_ex__qieting2"] = "所见相同，何必畏我？"
}

qieting:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qieting.name) and target ~= player then
      local room = player.room
      if #room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == target
      end, Player.HistoryTurn) == 0 and
        target:canMoveCardsInBoardTo(player, "e") then
        return true
      end
      if #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        if use.from == target and table.find(use.tos, function(p)
          return p ~= target
        end) then
          return true
        end
      end, Player.HistoryTurn) == 0 then
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    if #room.logic:getActualDamageEvents(1, function (e)
      return e.data.from == target
    end, Player.HistoryTurn) == 0 and
      target:canMoveCardsInBoardTo(player, "e") and
      room:askToSkillInvoke(player, {
        skill_name = qieting.name,
        prompt = "#ty_ex__qieting-move::"..target.id,
      }) then
      table.insert(choices, "move")
    end
    if #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == target and table.find(use.tos, function(p)
        return p ~= target
      end) then
        return true
      end
    end, Player.HistoryTurn) == 0 then
      table.insert(choices, "draw")
    end
    if #choices > 0 then
      event:setCostData(self, {tos = {target}, choice = choices})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.contains(event:getCostData(self).choice, "move") then
      room:askToMoveCardInBoard(player, {
        target_one = target,
        target_two = player,
        skill_name = qieting.name,
        flag = "e",
        move_from = target,
      })
    end
    if not player.dead and table.contains(event:getCostData(self).choice, "draw") then
      player:drawCards(1, qieting.name)
    end
  end,
})

return qieting
