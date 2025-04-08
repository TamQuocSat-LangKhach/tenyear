local yaopei = fk.CreateSkill {
  name = "yaopei",
}

Fk:loadTranslationTable{
  ["yaopei"] = "摇佩",
  [":yaopei"] = "其他角色弃牌阶段结束时，若你本回合对其发动过〖护关〗，你可以弃置一张其此阶段没弃置过的花色的牌，"..
  "然后令你与其中一名角色回复1点体力，另一名角色摸两张牌。",

  ["#yaopei-invoke"] = "摇佩：弃置一张 %dest 此阶段未弃置过花色的牌，你与其一方回复1点体力，另一方摸两张牌",
  ["#yaopei-choose"] = "摇佩：选择回复体力的角色，另一方摸两张牌",

  ["$yaopei1"] = "环佩春风，步摇桃粉。",
  ["$yaopei2"] = "赠君摇佩，佑君安好。",
}

yaopei:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yaopei.name) and target.phase == Player.Discard and not target.dead and
      player:usedSkillTimes("huguan", Player.HistoryTurn) > 0 and
      target ~= player and not player:isNude() then
      local suits = {"spade", "heart", "club", "diamond"}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == target and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
            end
          end
        end
      end, Player.HistoryPhase)
      if #suits > 0 then
        event:setCostData(self, {choice = suits})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local pattern = ".|.|"..table.concat(event:getCostData(self).choice, ",")
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = yaopei.name,
      cancelable = true,
      pattern = pattern,
      prompt = "#yaopei-invoke::"..target.id,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, yaopei.name, player, player)
    if player.dead or target.dead then return end
    local to1 = room:askToChoosePlayers(player, {
      targets = {player, target},
      min_num = 1,
      max_num = 1,
      prompt = "#yaopei-choose",
      skill_name = yaopei.name,
      cancelable = false,
    })[1]
    local to2 = player
    if to1 == player then
      to2 = target
    end
    if to1:isWounded() then
      room:recover{
        who = to1,
        num = 1,
        recoverBy = player,
        skillName = yaopei.name,
      }
    end
    if not to2.dead then
      to2:drawCards(2, yaopei.name)
    end
  end,
})

return yaopei
