local lieyi = fk.CreateSkill {
  name = "lieyi"
}

Fk:loadTranslationTable{
  ['lieyi'] = '烈医',
  ['#lieyi'] = '烈医：你可以对一名角色使用所有“疠”！',
  ['jiping_li'] = '疠',
  ['#lieyi-use'] = '烈医：选择一张“疠”对 %dest 使用（若无法使用则置入弃牌堆）',
  ['#lieyi-second'] = '烈医：选择你对其使用 %arg 的副目标',
  [':lieyi'] = '出牌阶段限一次，你可以展示所有“疠”并选择一名其他角色，并依次对其使用可使用的“疠”（无距离与次数限制且不计入次数），不可使用的置入弃牌堆。然后若该角色未因此进入濒死状态，你失去1点体力。',
  ['$lieyi1'] = '君有疾在身，不治将恐深。',
  ['$lieyi2'] = '汝身患重疾，当以虎狼之药去之。',
}

lieyi:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#lieyi",
  can_use = function(self, player)
    return player:usedSkillTimes(lieyi.name, Player.HistoryPhase) == 0 and #player:getPile("jiping_li") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select.id ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, "lieyi_using-phase", 1)
    player:showCards(player:getPile("jiping_li"))
    local yes = true
    while #player:getPile("jiping_li") > 0 and not player.dead and not target.dead do
      if target.dead then break end
      local id = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|.|jiping_li",
        prompt = "#lieyi-use::" .. target.id,
        skill_name = "jiping_li"
      })
      if #id > 0 then
        id = id[1]
      else
        id = table.random(player:getPile("jiping_li"))
      end
      local card = Fk:getCardById(id)
      local canUse = player:canUseTo(card, target, {bypass_distances = true, bypass_times = true}) and not
      (card.skill:getMinTargetNum() == 0 and not card.multiple_targets)
      local tos = {{target.id}}
      if canUse and card.skill:getMinTargetNum() == 2 then
        local seconds = {}
        for _, second in ipairs(room:getOtherPlayers(target)) do
          if card.skill:modTargetFilter(player, second.id, {target.id}, player, card) then
            table.insert(seconds, second)
          end
        end
        if #seconds > 0 then
          local second = room:askToChoosePlayers(player, {
            targets = seconds,
            min_num = 1,
            max_num = 1,
            prompt = "#lieyi-second:::" .. card:toLogString(),
            skill_name = lieyi.name
          })
          table.insert(tos, {second.id})
        else
          canUse = false
        end
      end
      if canUse then
        local use = {
          from = player.id,
          tos = tos,
          card = card,
          extraUse = true,
        }
        use.extra_data = use.extra_data or {}
        use.extra_data.lieyi_use = player.id
        room:useCard(use)
        if use.extra_data.lieyi_dying then
          yes = false
        end
      else
        room:moveCardTo(card, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, lieyi.name, nil, true, player.id)
      end
    end
    if #player:getPile("jiping_li") > 0 then
      room:moveCardTo(player:getPile("jiping_li"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, lieyi.name, nil, true, player.id)
    end
    room:setPlayerMark(player, "lieyi_using-phase", 0)
    if yes and not player.dead then
      room:loseHp(player, 1, lieyi.name)
    end
  end,
})

lieyi:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    if data.damage and data.damage.card then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return use.extra_data and use.extra_data.lieyi_use and use.extra_data.lieyi_use == player.id
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data[1]
      use.extra_data = use.extra_data or {}
      use.extra_data.lieyi_dying = true
    end
  end,
})

return lieyi
