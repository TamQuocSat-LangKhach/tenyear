local jinhui = fk.CreateSkill {
  name = "jinhui"
}

Fk:loadTranslationTable{
  ['jinhui'] = '锦绘',
  ['#jinhui-active'] = '发动 锦绘，亮出牌堆顶三张牌，令其他角色使用其中一张，你使用其余两张',
  ['#jinhui-choose'] = '锦绘：令一名其他角色使用其中一张牌，然后你可以使用其余两张',
  ['#jinhui2-use'] = '锦绘：使用其中一张牌（必须指定你或 %dest 为目标）',
  ['#jinhui-use'] = '锦绘：使用其中一张牌（必须指定你或 %src 为目标），然后其可以使用其余两张',
  [':jinhui'] = '出牌阶段限一次，你可以亮出牌堆里随机三张牌名各不相同且目标数为一的非伤害牌，然后选择一名其他角色，该角色使用其中一张，然后你可以依次使用其余两张（必须选择你或其为目标，无距离限制）。',
  ['$jinhui1'] = '大则盈尺，小则方寸。',
  ['$jinhui2'] = '十指纤纤，万分机巧。',
}

jinhui:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(jinhui.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local names = {}
    --FIXME：选牌逻辑需要重做 @(=ﾟωﾟ)ﾉ
    local quick_cards = {"jink", "nullification"}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if not (card.is_damage_card or table.contains(quick_cards, card.trueName) or card.trueName:startsWith("wd_")) then
        local x = card.skill:getMinTargetNum()
        if (x == 0 and not card.multiple_targets) or x == 1 then
          table.insertIfNeed(names, card.trueName)
        end
      end
    end
    if #names < 3 then return end
    names = table.random(names, 3)
    local card_ids = {}
    for _, name in ipairs(names) do
      table.insertTable(card_ids, room:getCardsFromPileByRule(name))
    end
    if #card_ids == 0 then return end
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = jinhui.name,
      proposer = player.id
    })
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#jinhui-choose",
      skill_name = jinhui.name
    })
    local target = room:getPlayerById(tos[1])

    local JinHuiUse = function(playerA, playerB, cancelable)
      if playerA.dead or playerB.dead then return false end
      local to_use = table.filter(card_ids, function (id)
        if room:getCardArea(id) ~= Card.Processing then return false end
        local card = Fk:getCardById(id)
        if not playerA:canUse(card) or playerA:prohibitUse(card) then return false end
        local to = card.skill:getMinTargetNum() == 0 and playerA or playerB
        return not playerA:isProhibited(to, card) and card.skill:modTargetFilter(to.id, {}, playerA, card, false)
      end)
      if #to_use == 0 then return false end
      local ids = room:askToChooseCards(playerA, {
        target = playerB,
        min_card_num = cancelable and 0 or 1,
        max_card_num = 1,
        card_data = {{ jinhui.name, to_use }},
        skill_name = jinhui.name,
        prompt = cancelable and "#jinhui2-use::" .. playerB.id or "#jinhui-use:" .. playerB.id
      })
      if #ids == 0 then return false end
      local card = Fk:getCardById(ids[1])
      room:useCard({
        from = playerA.id,
        tos = {{card.skill:getMinTargetNum() == 0 and playerA.id or playerB.id}},
        card = card,
        extraUse = true,
      })
      return true
    end
    JinHuiUse(target, player, false)
    while JinHuiUse(player, target, true) do

    end
    card_ids = table.filter(card_ids, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #card_ids > 0 then
      room:moveCards({
        ids = card_ids,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = jinhui.name,
      })
    end
  end
})

return jinhui
