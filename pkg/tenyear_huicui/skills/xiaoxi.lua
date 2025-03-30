local xiaoxi = fk.CreateSkill {
  name = "xiaoxix",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xiaoxix"] = "宵袭",
  [":xiaoxix"] = "锁定技，出牌阶段开始时，你需减少1或2点体力上限，然后选择一项：1.获得你攻击范围内一名其他角色等量的牌；"..
  "2.视为对你攻击范围内的一名其他角色使用等量张【杀】。",

  ["#xiaoxix1-choice"] = "宵袭：你需减少1或2点体力上限",
  ["#xiaoxix-choose"] = "宵袭：选择攻击范围内一名角色，获得其等量牌或视为对其使用等量【杀】",
  ["xiaoxix_prey"] = "获得其%arg张牌",
  ["xiaoxix_slash"] = "视为对其使用%arg张【杀】",
  ["#xiaoxix2-choice"] = "宵袭：选择对 %dest 执行的一项",

  ["$xiaoxix1"] = "夜深枭啼，亡命夺袭！",
  ["$xiaoxix2"] = "以夜为幕，纵兵逞凶！",
}

xiaoxi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiaoxi.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"1", "2"}
    if player.maxHp == 1 then
      choices = {"1"}
    end
    local n = tonumber(room:askToChoice(player, {
      choices = choices,
      skill_name = xiaoxi.name,
      prompt = "#xiaoxix1-choice",
    }))
    room:changeMaxHp(player, -n)
    if player.dead then return end
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return player:inMyAttackRange(p) and
        (not p:isNude() or player:canUseTo(Fk:cloneCard("slash"), p, {bypass_times = true}))
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xiaoxix-choose",
      skill_name = xiaoxi.name,
      cancelable = false,
    })[1]
    choices = {"xiaoxix_prey:::"..n, "xiaoxix_slash:::"..n}
    if #to:getCardIds("he") < n then
      choices = {"xiaoxix_slash:::"..n}
    elseif player:isProhibited(to, Fk:cloneCard("slash")) then
      choices = {"xiaoxix_prey:::"..n}
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xiaoxi.name,
      prompt = "#xiaoxix2-choice::"..to.id,
    })
    if choice:startsWith("xiaoxix_prey") then
      local cards = room:askToChooseCards(player, {
        skill_name = xiaoxi.name,
        target = to,
        min = n,
        max = n,
        flag = "he",
        reason = xiaoxi.name,
      })
      room:obtainCard(player, cards, false, fk.ReasonPrey, player, xiaoxi.name)
    else
      for _ = 1, n do
        if player.dead or to.dead then return end
        room:useVirtualCard("slash", nil, player, to, xiaoxi.name, true)
      end
    end
  end,
})

return xiaoxi
