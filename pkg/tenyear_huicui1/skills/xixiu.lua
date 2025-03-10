local xixiu = fk.CreateSkill {
  name = "xixiu"
}

Fk:loadTranslationTable{
  ['xixiu'] = '皙秀',
  [':xixiu'] = '锁定技，当你成为其他角色使用牌的目标后，若你装备区内有与此牌花色相同的牌，你摸一张牌；其他角色不能弃置你装备区内的最后一张牌。',
  ['$xixiu1'] = '君子如玉，德形皓白。',
  ['$xixiu2'] = '木秀于身，芬芳自如。',
}

-- Effect for TargetConfirmed
xixiu:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xixiu.name) then
      return target == player and data.from ~= player.id and
        table.find(player:getCardIds("e"), function(id) return Fk:getCardById(id).suit == data.card.suit end)
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      player:drawCards(1, xixiu.name)
    end
  end,
})

-- Effect for BeforeCardsMove
xixiu:addEffect(fk.BeforeCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if #player:getCardIds("e") ~= 1 then return false end
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard and (move.proposer ~= player.id and move.proposer ~= player.id) then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard and (move.proposer ~= player.id and move.proposer ~= player.id) then
        for i = #move.moveInfo, 1, -1 do
          local info = move.moveInfo[i]
          if info.fromArea == Card.PlayerEquip then
            table.removeOne(move.moveInfo, info)
            break
          end
        end
      end
    end
  end,
})

return xixiu
