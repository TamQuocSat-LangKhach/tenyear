local chanjuan = fk.CreateSkill {
  name = "chanjuan",
}

Fk:loadTranslationTable{
  ["chanjuan"] = "婵娟",
  [":chanjuan"] = "每种牌名限两次，你使用指定唯一目标的基本牌或普通锦囊牌结算完毕后，你可以视为使用一张同名牌，若目标完全相同，你摸一张牌。",

  ["#chanjuan-use"] = "婵娟：你可以视为使用【%arg】，若目标为 %dest 则摸一张牌",

  ["$chanjuan1"] = "姐妹一心，共侍玄德无忧。",
  ["$chanjuan2"] = "双姝从龙，姊妹宠荣与共。",
}

chanjuan:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chanjuan.name) and
      (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and
      #data.tos == 1 and data:IsUsingHandcard(player) and
      #table.filter(player:getTableMark(chanjuan.name), function(s)
        return s == data.card.trueName
      end) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = data.card.name,
      skill_name = chanjuan.name,
      prompt = "#chanjuan-use::"..data.tos[1].id..":"..data.card.name,
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self).extra_data
    room:addTableMark(player, chanjuan.name, data.card.trueName)
    room:useCard(use)
    if not player.dead and #use.tos == 1 and data.tos[1] == use.tos[1] then
      player:drawCards(1, chanjuan.name)
    end
  end,
})

chanjuan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, chanjuan.name, 0)
end)

return chanjuan
