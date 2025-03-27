local yaopei = fk.CreateSkill {
  name = "yaopei"
}

Fk:loadTranslationTable{
  ['yaopei'] = '摇佩',
  ['huguan'] = '护关',
  ['#yaopei-invoke'] = '摇佩：你可以弃置一张 %dest 此阶段未弃置过花色的牌，你与其一方回复1点体力，另一方摸两张牌',
  ['#yaopei-choose'] = '摇佩：选择回复体力的角色，另一方摸两张牌',
  [':yaopei'] = '其他角色弃牌阶段结束时，若你本回合对其发动过〖护关〗，你可以弃置一张其此阶段没弃置过的花色的牌，然后令你与其中一名角色回复1点体力，另一名角色摸两张牌。',
  ['$yaopei1'] = '环佩春风，步摇桃粉。',
  ['$yaopei2'] = '赠君摇佩，佑君安好。',
}

yaopei:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yaopei.name) and target.phase == Player.Discard and player:usedSkillTimes("huguan", Player.HistoryTurn) > 0 and
      target ~= player and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local pattern = "."
    if target:getMark("yaopei-phase") ~= 0 then
      local suits = {"spade", "heart", "club", "diamond"}
      pattern = ".|.|"
      for _, s in ipairs(suits) do
        if not table.contains(target:getMark("yaopei-phase"), s) then
          pattern = pattern..s..","
        end
      end
    end
    if pattern[#pattern] == "," then
      pattern = string.sub(pattern, 1, #pattern - 1)
    end
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = yaopei.name,
      cancelable = true,
      pattern = pattern,
      prompt = "#yaopei-invoke::"..target.id,
      skip = false,
    })
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self), yaopei.name, player, player)
    if player.dead or target.dead then return end
    local to1 = room:askToChoosePlayers(player, {
      targets = {player.id, target.id},
      min_num = 1,
      max_num = 1,
      prompt = "#yaopei-choose",
      skill_name = yaopei.name,
      cancelable = false,
    })
    if #to1 > 0 then
      to1 = room:getPlayerById(to1[1])
    else
      to1 = room:getPlayerById(player.id)
    end
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

yaopei:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("yaopei-phase")
    if mark == 0 then mark = {} end
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(mark, Fk:getCardById(info.cardId):getSuitString())
        end
      end
    end
    if #mark == 0 then mark = 0 end
    player.room:setPlayerMark(player, "yaopei-phase", mark)
  end,
})

return yaopei
