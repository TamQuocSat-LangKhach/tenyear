local shoucheng = fk.CreateSkill {
  name = "ty__shoucheng",
}

Fk:loadTranslationTable{
  ["ty__shoucheng"] = "守成",
  [":ty__shoucheng"] = "每回合限一次，当一名角色于其回合外失去最后的手牌后，你可以令其摸两张牌。",

  ["#ty__shoucheng-choose"] = "守成：你可以令一名角色摸两张牌",
  ["#ty__shoucheng-draw"] = "守成：你可以令 %dest 摸两张牌",

  ["$ty__shoucheng1"] = "待吾等助将军一臂之力！",
  ["$ty__shoucheng2"] = "国库盈余，可助军威。",
}

shoucheng:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shoucheng.name) and player:usedSkillTimes(shoucheng.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from and move.from:isKongcheng() and player.room.current ~= move.from and not move.from.dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      if move.from and move.from:isKongcheng() and player.room.current ~= move.from and not move.from.dead then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            table.insertIfNeed(targets, move.from)
            break
          end
        end
      end
    end
    if #targets > 1 then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ty__shoucheng-choose",
        skill_name = shoucheng.name,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    else
      if room:askToSkillInvoke(player, {
        skill_name = shoucheng.name,
        prompt = "#ty__shoucheng-draw::" .. targets[1].id,
      }) then
        event:setCostData(self, {tos = targets})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(2, shoucheng.name)
  end,
})

return shoucheng
