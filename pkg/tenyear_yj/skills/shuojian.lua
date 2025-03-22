local shuojian = fk.CreateSkill {
  name = "shuojian",
}

Fk:loadTranslationTable{
  ["shuojian"] = "数荐",
  [":shuojian"] = "出牌阶段限三次，你可以交给一名其他角色一张牌，然后其选择一项：1.令你摸3张牌并弃2张牌；2.视为使用3张【过河拆桥】，"..
  "本回合此技能失效。此阶段下次发动该技能，选项中所有数字-1。",

  ["#shuojian"] = "数荐：交给一名角色一张牌，其选择令你摸牌或其视为使用【过河拆桥】",
  ["shuojian1"] = "令 %src 摸%arg张牌并弃%arg2张牌",
  ["shuojian2"] = "你视为使用%arg张【过河拆桥】，本回合此技能失效",
  ["#shuojian-use"] = "数荐：视为使用【过河拆桥】（第%arg张，共%arg2张）",

  ["$shuojian1"] = "我数荐卿而祖不用，其之失也。",
  ["$shuojian2"] = "兴霸乃当世豪杰，何患无爵。",
}

shuojian:addEffect("active", {
  anim_type = "support",
  prompt = "#shuojian",
  card_num = 1,
  target_num = 1,
  times = function(self, player)
    return player.phase == Player.Play and 3 - player:usedSkillTimes(shuojian.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(shuojian.name, Player.HistoryPhase) < 3
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, shuojian.name, nil, false, player)
    if target.dead then return end
    local n = 4 - player:usedSkillTimes(shuojian.name, Player.HistoryPhase)
    local choices = {}
    if not player.dead then
      table.insert(choices, "shuojian1:"..player.id.."::"..n..":"..(n - 1))
    end
    if target:canUse(Fk:cloneCard("dismantlement")) then
      table.insert(choices, "shuojian2:::"..n)
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = shuojian.name
    })
    if choice:startsWith("shuojian1") then
      player:drawCards(n, shuojian.name)
      if not player.dead and n > 1 then
        room:askToDiscard(player, {
          min_num = n - 1,
          max_num = n - 1,
          include_equip = true,
          skill_name = shuojian.name,
          cancelable = false,
        })
      end
    else
      room:invalidateSkill(player, shuojian.name, "-turn")
      for i = 1, n, 1 do
        if target.dead then return end
        room:askToUseVirtualCard(target, {
          name = "dismantlement",
          skill_name = shuojian.name,
          prompt = "#shuojian-use:::"..i..":"..n,
          cancelable = true,
        })
      end
    end
  end,
})

return shuojian
