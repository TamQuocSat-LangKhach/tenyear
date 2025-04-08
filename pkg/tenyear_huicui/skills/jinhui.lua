local jinhui = fk.CreateSkill {
  name = "jinhui",
}

Fk:loadTranslationTable{
  ["jinhui"] = "锦绘",
  [":jinhui"] = "出牌阶段限一次，你可以亮出牌堆里随机三张牌名各不相同且目标数为一的非伤害牌，然后选择一名其他角色，该角色使用其中一张，"..
  "然后你可以依次使用其余两张（必须选择你或其为目标，无距离限制）。",

  ["#jinhui"] = "锦绘：亮出牌堆顶三张牌，令一名角色使用其中一张，你使用其余两张",
  ["#jinhui-choose"] = "锦绘：令一名其他角色使用其中一张牌，然后你可以使用其余两张",
  ["#jinhui-use"] = "锦绘：使用其中一张牌（必须指定你或 %src 为目标），然后其可以使用其余两张",
  ["#jinhui2-use"] = "锦绘：你可以使用其中的牌（必须指定你或 %dest 为目标）",

  ["$jinhui1"] = "大则盈尺，小则方寸。",
  ["$jinhui2"] = "十指纤纤，万分机巧。",
}

jinhui:addEffect("active", {
  anim_type = "support",
  prompt = "#jinhui",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(jinhui.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local names = {}
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if not card.is_damage_card and not card.is_passive and not card.multiple_targets and
        card.skill:getMinTargetNum(player) < 1 then
        table.insertIfNeed(names, card.trueName)
      end
    end
    if #names < 3 then return end
    names = table.random(names, 3)
    local cards = {}
    for _, name in ipairs(names) do
      table.insertTable(cards, room:getCardsFromPileByRule(name))
    end
    room:turnOverCardsFromDrawPile(player, cards, jinhui.name)
    if #room:getOtherPlayers(player, false) == 0 then
      room:cleanProcessingArea(cards)
      return
    end
    local target = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#jinhui-choose",
      skill_name = jinhui.name,
      cancelable = false,
    })[1]
    local ids = table.filter(cards, function (id)
      return table.contains(Fk:getCardById(id):getAvailableTargets(target, {bypass_distances = true, bypass_times = true}), player) or
        table.contains(Fk:getCardById(id):getAvailableTargets(target, {bypass_distances = true, bypass_times = true}), target)
    end)
    if #ids > 0 then
      local card = room:askToCards(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = jinhui.name,
        pattern = tostring(Exppattern{ id = ids }),
        prompt = "#jinhui-use:"..player.id,
        cancelable = false,
        expand_pile = ids,
      })[1]
      card = Fk:getCardById(card)
      local to = player
      if table.contains(card:getAvailableTargets(target, {bypass_distances = true, bypass_times = true}), target) then
        to = target
      end
      room:useCard({
        from = target,
        tos = {to},
        card = card,
      })
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.Processing
      end)
    end
    while not player.dead do
      ids = table.filter(cards, function (id)
        return table.contains(Fk:getCardById(id):getAvailableTargets(player, {bypass_distances = true, bypass_times = true}), player) or
          table.contains(Fk:getCardById(id):getAvailableTargets(player, {bypass_distances = true, bypass_times = true}), target)
      end)
      if #ids == 0 then
        break
      end
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = jinhui.name,
        pattern = tostring(Exppattern{ id = ids }),
        prompt = "#jinhui2-use::"..target.id,
        expand_pile = ids,
      })
      if #card > 0 then
        card = Fk:getCardById(card[1])
        local to = player
        if table.contains(card:getAvailableTargets(player, {bypass_distances = true, bypass_times = true}), target) then
          to = target
        end
        room:useCard({
          from = player,
          tos = {to},
          card = card,
        })
        cards = table.filter(cards, function (id)
          return room:getCardArea(id) == Card.Processing
        end)
      else
        break
      end
    end
    room:cleanProcessingArea(cards)
  end
})

return jinhui
