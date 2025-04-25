local dianlun = fk.CreateSkill{
  name = "dianlun",
}

Fk:loadTranslationTable{
  ["dianlun"] = "典论",
  [":dianlun"] = "出牌阶段限一次，你可以弃置任意张点数之差相同的手牌，然后摸等量的牌，这些牌本回合不受〖肃纲〗限制。",

  ["#dianlun"] = "典论：弃置任意张点数之差相同的手牌，摸等量的牌",
  ["#dianlun_update"] = "典论：弃置任意张点数之差相同的手牌，摸两倍的牌",

  ["$dianlun1"] = "",
  ["$dianlun2"] = "",
}

dianlun:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player, selected_cards, selected_targets)
    if player:getMark("dianlun_update-turn") > 0 then
      return "#dianlun_update"
    else
      return "#dianlun"
    end
  end,
  min_card_num = 1,
  target_num = 0,
  can_use = function (self, player)
    return player:usedSkillTimes(dianlun.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if table.contains(player:getCardIds("h"), to_select) and not player:prohibitDiscard(to_select) and
      Fk:getCardById(to_select).number > 0 then
      if #selected < 2 then
        return true
      else
        if self.jiweic and #selected == 3 then return end
        local nums = table.map(selected, function(id)
          return Fk:getCardById(id).number
        end)
        table.insert(nums, Fk:getCardById(to_select).number)
        table.sort(nums)
        for i = 2, #nums - 1 do
          if nums[i + 1] - nums[i] ~= nums[i] - nums[i - 1] then
            return false
          end
        end
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, dianlun.name, player, player)
    if player.dead then return end
    player:drawCards(#effect.cards * (player:getMark("dianlun_update-turn") > 0 and 2 or 1), dianlun.name, nil, "dianlun-inhand-turn")
  end,
})

return dianlun
