local porui = fk.CreateSkill {
  name = "porui",
  dynamic_desc = function(self, player)
    local text = "porui_inner:".. tostring(player:getMark("gonghu1") + 1) .. ":"
    if player:getMark("gonghu2") == 0 then
      text = text .. "porui_give"
    end
    return text
  end,
}

Fk:loadTranslationTable{
  ['porui'] = '破锐',
  ['gonghu1'] = '限两次',
  ['gonghu2'] = '不用给牌',
  ['porui_give'] = '，然后你交给其X张手牌',
  ['#porui-choose'] = '发动 破锐，弃置一张牌并选择本回合失去过牌的角色',
  ['#porui-give'] = '破锐：选择%arg张手牌，交给%dest',
  [':porui'] = '每轮限一次，其他角色的结束阶段，你可以弃置一张牌并选择本回合内失去过牌的另一名其他角色，你视为对该角色依次使用X+1张【杀】，然后你交给其X张手牌。（X为其本回合失去的牌数且最多为5）',
  ['$porui1'] = '承父勇烈，问此间谁堪敌手。',
  ['$porui2'] = '敌锋虽锐，吾亦击之如破卵。',
}

porui:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  times = function(self, player)
    return 1 + player:getMark("gonghu1") - player:usedSkillTimes(porui.name, Player.HistoryRound)
  end,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(porui) and not player:isNude() and target ~= player and target.phase == Player.Finish
      and player:usedSkillTimes(porui.name, Player.HistoryRound) < (player:getMark("gonghu1") == 0 and 1 or 2) then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      local end_id = turn_event.id
      return #room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from ~= nil and move.from ~= player.id and move.from ~= target.id and not room:getPlayerById(move.from).dead
            and (move.to ~= move.from or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
        return false
      end, end_id) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
    local end_id = turn_event.id
    local num_map = {}
    room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from ~= nil and move.from ~= player.id and move.from ~= target.id
          and (move.to ~= move.from or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          local p = room:getPlayerById(move.from)
          if not p.dead then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                num_map[tostring(move.from)] = num_map[tostring(move.from)] or 0
                num_map[tostring(move.from)] = math.min(5, num_map[tostring(move.from)] + 1)
              end
            end
          end
        end
      end
      return false
    end, end_id)
    local targets = table.filter(room.alive_players, function (p)
      return num_map[tostring(p.id)]
    end)
    if #targets == 0 then return false end
    local tar, card = player.room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = table.map(targets, Util.IdMapper),
      pattern = ".",
      prompt = "#porui-choose",
      skill_name = porui.name,
      cancelable = true,
      no_indicate = false,
      target_tip_name = "porui_tip",
      extra_data = num_map
    })
    if #tar > 0 and card then
      event:setCostData(skill, {tos = tar, cards = {card}, num = num_map[tostring(tar[1])]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local need_give_card = (player:getMark("gonghu2") == 0)
    local to = room:getPlayerById(event:getCostData(skill).tos[1])
    local x = event:getCostData(skill).num
    room:throwCard(event:getCostData(skill).cards, porui.name, player, player)
    for _ = 1, x + 1, 1 do
      if player.dead or to.dead or not room:useVirtualCard("slash", nil, player, to, porui.name, true) then break end
    end
    if need_give_card and not (player.dead or player:isKongcheng() or to.dead) then
      local cards = player:getCardIds(Player.Hand)
      if #cards > x then
        cards = room:askToCards(player, {
          min_num = x,
          max_num = x,
          include_equip = false,
          skill_name = porui.name,
          cancelable = false,
          pattern = ".",
          prompt = "#porui-give::" .. to.id .. ":" .. tostring(x)
        })
      end
      room:moveCardTo(cards, Player.Hand, to, fk.ReasonGive, porui.name, nil, false, player.id)
    end
  end,
})

return porui
