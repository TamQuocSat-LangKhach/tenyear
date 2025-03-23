local shawu_select = fk.CreateSkill {
  name = "shawu_select"
}

Fk:loadTranslationTable{
  ['shawu_select'] = '沙舞',
  ['@xiaowowu_sand'] = '沙',
}

shawu_select:addEffect('active', {
  can_use = Util.FalseFunc,
  target_num = 0,
  max_card_num = 2,
  min_card_num = function (player)
    if player:getMark("@xiaowu_sand") > 0 then
      return 0
    end
    return 2
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and not player:prohibitDiscard(Fk:getCardById(to_select))
      and table.contains(player:getCardIds("h"), to_select)
  end,
  feasible = function (skill, player, selected, selected_cards)
    if #selected_cards == 0 then
      return player:getMark("@xiaowu_sand") > 0
    else
      return #selected_cards == 2
    end
  end,
  askto_skill_invoke = function(player, data)
    local min_num = Util:getValue(skill.min_card_num, {player})
    local max_num = skill.max_card_num

    return player.room:askToCards(player, {
      min_num = min_num,
      max_num = max_num,
      pattern = ".|.|.",
      prompt = "@xiaowowu_sand",
      cancelable = true,
      extra_data = data
    })
  end,
})

return shawu_select
