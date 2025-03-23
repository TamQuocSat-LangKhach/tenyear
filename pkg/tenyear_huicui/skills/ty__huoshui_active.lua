local ty__huoshui = fk.CreateSkill {
  name = "ty__huoshui_active"
}

Fk:loadTranslationTable{
  ['ty__huoshui_active'] = '祸水',
  ['ty__huoshui'] = '祸水',
  ['#ty__huoshui-give'] = '祸水：你须交给%src一张手牌',
}

ty__huoshui:addEffect('active', {
  mute = true,
  card_num = 0,
  min_target_num = 1,
  max_target_num = function(player)
    local n = math.max(player:getLostHp(), 1)
    return math.min(n, 3)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, cards)
    if to_select ~= player.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return not target:isKongcheng()
      elseif #selected == 2 then
        return #target.player_cards[Player.Equip] > 0
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for i = 1, #effect.tos, 1 do
      local target = room:getPlayerById(effect.tos[i])
      if i == 1 then
        room:setPlayerMark(target, MarkEnum.UncompulsoryInvalidity.."-turn", 1)
      elseif i == 2 then
        local card = room:askToCards(target, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          pattern = ".",
          prompt = "#ty__huoshui-give:"..player.id,
          cancelable = false,
          skill_name = ty__huoshui.name
        })
        room:obtainCard(player.id, card[1], false, fk.ReasonGive)
      elseif i == 3 then
        target:throwAllCards("e")
      end
    end
  end,
})

return ty__huoshui
