local porui = fk.CreateSkill {
  name = "porui",
  dynamic_desc = function(self, player)
    local str = "porui_inner:"..(player:getMark("gonghu1") + 1)..":"
    if player:getMark("gonghu2") == 0 then
      str = str.."porui_give"
    end
    return str
  end,
}

Fk:loadTranslationTable{
  ["porui"] = "破锐",
  [":porui"] = "每轮限一次，其他角色的结束阶段，你可以弃置一张牌并选择本回合失去过牌的另一名其他角色，视为对该角色依次使用X+1张【杀】，"..
  "然后你交给其X张手牌。（X为其本回合失去的牌数且最多为5）",

  [":porui_inner"] = "每轮限{1}次，其他角色的结束阶段，你可以弃置一张牌并选择本回合失去过牌的另一名其他角色，"..
  "视为对该角色依次使用X+1张【杀】{2}。（X为其本回合失去的牌数且最多为5）",
  ["porui_give"] = "，然后你交给其X张手牌",

  ["#porui-choose"] = "破锐：弃置一张牌，视为对一名角色使用其失去牌数+1张【杀】",
  ["#porui_tip"] = "失去牌数 %arg",
  ["#porui-give"] = "破锐：交给 %dest %arg张手牌",

  ["$porui1"] = "承父勇烈，问此间谁堪敌手。",
  ["$porui2"] = "敌锋虽锐，吾亦击之如破卵。",
}

porui:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  times = function(self, player)
    return 1 + player:getMark("gonghu1") - player:usedSkillTimes(porui.name, Player.HistoryRound)
  end,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(porui.name) and target.phase == Player.Finish and target ~= player and
      not player:isNude() and player:usedSkillTimes(porui.name, Player.HistoryRound) < (player:getMark("gonghu1") == 0 and 1 or 2) then
      local room = player.room
      return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from and move.from ~= player and move.from ~= target and not move.from.dead and
            (move.to ~= move.from or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local num_map = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from and move.from ~= player and move.from ~= target and not move.from.dead and
          (move.to ~= move.from or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              num_map[tostring(move.from.id)] = num_map[tostring(move.from.id)] or 0
              num_map[tostring(move.from.id)] = math.min(5, num_map[tostring(move.from.id)] + 1)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    local targets = table.filter(room.alive_players, function (p)
      return num_map[tostring(p.id)]
    end)
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = porui.name,
      prompt = "#porui-choose",
      cancelable = true,
      will_throw = true,
      target_tip_name = porui.name,
      extra_data = num_map,
    })
    if #to > 0 and #card > 0 then
      event:setCostData(self, {tos = to, cards = card, choice = num_map[tostring(to[1].id)]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local give = player:getMark("gonghu2") == 0
    local to = event:getCostData(self).tos[1]
    local x = event:getCostData(self).choice
    room:throwCard(event:getCostData(self).cards, porui.name, player, player)
    for _ = 1, x + 1, 1 do
      if player.dead or to.dead or not room:useVirtualCard("slash", nil, player, to, porui.name, true) then break end
    end
    if give and not (player.dead or player:isKongcheng() or to.dead) then
      local cards = player:getCardIds("h")
      if #cards > x then
        cards = room:askToCards(player, {
          min_num = x,
          max_num = x,
          include_equip = false,
          skill_name = porui.name,
          cancelable = false,
          prompt = "#porui-give::"..to.id..":"..x,
        })
      end
      room:moveCardTo(cards, Player.Hand, to, fk.ReasonGive, porui.name, nil, false, player)
    end
  end,
})

Fk:addTargetTip{
  name = "porui",
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    local porui_num = extra_data.extra_data[tostring(to_select.id)]
    if porui_num then
      return "#porui_tip:::"..porui_num
    end
  end,
}

return porui
