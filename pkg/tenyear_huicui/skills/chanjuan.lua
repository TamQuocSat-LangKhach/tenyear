local chanjuan = fk.CreateSkill {
  name = "chanjuan"
}

Fk:loadTranslationTable{
  ['chanjuan'] = '婵娟',
  ['@$chanjuan'] = '婵娟',
  ['#chanjuan-use'] = '婵娟：你可以视为使用【%arg】，若目标为 %dest ，你摸一张牌',
  [':chanjuan'] = '每种牌名限两次，你使用指定唯一目标的基本牌或普通锦囊牌结算完毕后，你可以视为使用一张同名牌，若目标完全相同，你摸一张牌。',
  ['$chanjuan1'] = '姐妹一心，共侍玄德无忧。',
  ['$chanjuan2'] = '双姝从龙，姊妹宠荣与共。',
}

chanjuan:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chanjuan.name) and (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and U.IsUsingHandcard(player, data) and 
      #table.filter(player:getTableMark("@$chanjuan"), function(s) return s == data.card.trueName end) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local use = U.askForUseVirtualCard(player.room, player, data.card.trueName, nil, chanjuan.name, "#chanjuan-use::"..TargetGroup:getRealTargets(data.tos)[1]..":"..data.card.trueName, true, true, false, true, {}, true)
    if use then
      event:setCostData(self, use)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self)
    room:addTableMark(player, "@$chanjuan", data.card.trueName)
    room:useCard(use)
    if not player.dead and #TargetGroup:getRealTargets(use.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] == TargetGroup:getRealTargets(use.tos)[1] then
      player:drawCards(1, chanjuan.name)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@$chanjuan") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@$chanjuan", 0)
  end,
})

return chanjuan
