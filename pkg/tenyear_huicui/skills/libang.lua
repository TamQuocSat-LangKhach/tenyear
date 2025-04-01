local libang = fk.CreateSkill {
  name = "libang",
}

Fk:loadTranslationTable{
  ["libang"] = "利傍",
  [":libang"] = "出牌阶段限一次，你可以弃置一张牌，获得两名其他角色各一张牌并展示，然后你判定，若结果与这两张牌的颜色：均不同，"..
  "你交给其中一名角色两张牌或失去1点体力；至少一张相同，你获得判定牌并视为对其中一名角色使用一张【杀】。",

  ["#libang"] = "利傍：弃置一张牌，获得两名其他角色各一张牌，然后判定",
  ["#libang-give"] = "利傍：交给其中一名角色两张牌，否则失去1点体力",
  ["#libang-slash"] = "利傍：视为对其中一名角色使用一张【杀】",

  ["$libang1"] = "天下熙攘，所为者利尔。",
  ["$libang2"] = "我有武力傍身，必可待价而沽。",
}

libang:addEffect("active", {
  anim_type = "control",
  prompt = "#libang",
  card_num = 1,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(libang.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < 2 and to_select ~= player and not to_select:isNude()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    room:throwCard(effect.cards, libang.name, player, player)
    local suits = {}
    local cards = {}
    for _, p in ipairs(effect.tos) do
      if player.dead then return end
      if not p.dead and not p:isNude() then
        local id = room:askToChooseCard(player, {
          target = p,
          flag = "he",
          skill_name = libang.name,
        })
        table.insertIfNeed(cards, id)
        if Fk:getCardById(id).color == Card.Red then
          table.insertIfNeed(suits, "heart")
          table.insertIfNeed(suits, "diamond")
        elseif Fk:getCardById(id).color == Card.Black then
          table.insertIfNeed(suits, "spade")
          table.insertIfNeed(suits, "club")
        end
        room:obtainCard(player, id, true, fk.ReasonPrey, player, libang.name)
      end
    end
    if player.dead then return end
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #cards > 0 then
      player:showCards(cards)
      if player.dead then return end
    end
    local pattern = "."
    if #suits > 0 then
      pattern = ".|.|" .. table.concat(suits, ",")
    end
    local judge = {
      who = player,
      reason = libang.name,
      pattern = pattern,
    }
    room:judge(judge)
    if player.dead or judge.card.color == Card.NoColor then return end
    if judge:matchPattern() then
      if room:getCardArea(judge.card) == Card.DiscardPile then
        room:obtainCard(player, judge.card, true, fk.ReasonJustMove, player, libang.name)
        if player.dead then return end
      end
      local targets = table.filter(effect.tos, function(p)
        return not p.dead and not player:isProhibited(p, Fk:cloneCard("slash"))
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#libang-slash",
        skill_name = libang.name,
        cancelable = false,
      })[1]
      room:useVirtualCard("slash", nil, player, to, libang.name, true)
    else
      local targets = table.filter(effect.tos, function(p)
        return not p.dead
      end)
      if #targets == 0 or #player:getCardIds("he") < 2 then
        room:loseHp(player, 1, libang.name)
      else
        local to, ids = room:askToChooseCardsAndPlayers(player, {
          min_card_num = 2,
          max_card_num = 2,
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = libang.name,
          prompt = "#libang-give",
          cancelable = true,
        })
        if #to > 0 and #ids > 0 then
          room:obtainCard(to[1], ids, false, fk.ReasonGive, player, libang.name)
        else
          room:loseHp(player, 1, libang.name)
        end
      end
    end
  end,
})

return libang
