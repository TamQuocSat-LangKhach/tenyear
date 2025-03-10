local shuliang = fk.CreateSkill {
  name = "ty__shuliang"
}

Fk:loadTranslationTable{
  ['ty__shuliang'] = '输粮',
  ['#ty__shuliang-choose'] = '输粮：你可选择一张牌和一名没有手牌的其他角色，交给其此牌',
  ['#ty__shuliang-use'] = '输粮：是否对自己使用%arg',
  [':ty__shuliang'] = '每个回合结束时，你可以交给至少一名没有手牌的其他角色各一张牌。若此牌可指定该角色自己为目标，则其可使用此牌。',
  ['$ty__shuliang1'] = '北伐鏖战正酣，此正需粮之时。',
  ['$ty__shuliang2'] = '粮草先于兵马而动，此军心之本。',
}

shuliang:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return
      player:hasSkill(shuliang.name) and
      not player:isNude() and
      table.find(player.room.alive_players, function(p) return p ~= player and p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local availableTargets = table.filter(room.alive_players, function(p) return p ~= player and p:isKongcheng() end)
    if #availableTargets > 0 then
      local tos, cid = room:askToChooseCardsAndPlayers(
        player,
        {
          min_card_num = 1,
          max_card_num = 1,
          targets = availableTargets,
          min_target_num = 1,
          max_target_num = 1,
          prompt = "#ty__shuliang-choose",
          skill_name = shuliang.name,
          cancelable = true
        }
      )

      if #tos > 0 and cid then
        event:setCostData(self, {tos[1], cid})
        return true
      end
    end

    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:moveCardTo(event:getCostData(self)[2], Player.Hand, room:getPlayerById(event:getCostData(self)[1]), fk.ReasonGive, shuliang.name, nil, false, player.id)

    local GivenMap = { [event:getCostData(self)[1]] = event:getCostData(self)[2] }
    local targetsGiven = { event:getCostData(self)[1] }
    local availableTargets = table.filter(
      room.alive_players,
      function(p) return p ~= player and p:isKongcheng() and not GivenMap[p.id] end
    )

    while #availableTargets > 0 and not player:isNude() do
      local tos, cid = room:askToChooseCardsAndPlayers(
        player,
        {
          min_card_num = 1,
          max_card_num = 1,
          targets = availableTargets,
          min_target_num = 1,
          max_target_num = 1,
          prompt = "#ty__shuliang-choose",
          skill_name = shuliang.name,
          cancelable = true
        }
      )

      if #tos > 0 and cid then
        GivenMap[tos[1]] = cid
        table.insert(targetsGiven, tos[1])
        room:moveCardTo(cid, Player.Hand, room:getPlayerById(tos[1]), fk.ReasonGive, shuliang.name, nil, false, player.id)
      else
        break
      end

      availableTargets = table.filter(
        room.alive_players,
        function(p) return p ~= player and p:isKongcheng() and not GivenMap[p.id] end
      )
    end

    room:sortPlayersByAction(targetsGiven)
    for _, pid in ipairs(targetsGiven) do
      local p = room:getPlayerById(pid)
      local cardToUse = Fk:getCardById(GivenMap[pid])
      if p:isAlive() and room:getCardArea(cardToUse.id) == Card.PlayerHand and
        p:canUseTo(cardToUse, p, { bypass_times = true }) and
        room:askToSkillInvoke(p, {
          skill_name = shuliang.name,
          prompt = "#ty__shuliang-use:::" .. cardToUse:toLogString()
        }) then
        local use = {
          from = p.id,
          card = cardToUse,
          extra_use = true,
        }
        --FIXME: 目前没有对自己使用且必须指定两个以上目标的卡牌，暂不作处理
        if cardToUse.skill:getMinTargetNum() == 1 then
          use.tos = {{p.id}}
        end
        room:useCard(use)
      end
    end
  end,
})

return shuliang
