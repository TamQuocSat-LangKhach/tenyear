local manzhi = fk.CreateSkill {
  name = "manzhi",
}

Fk:loadTranslationTable{
  ["manzhi"] = "蛮智",
  [":manzhi"] = "准备阶段，你可以选择一名其他角色，然后选择一项：1.令其交给你两张牌，然后其视为使用一张无距离限制的【杀】；"..
  "2.获得其区域内的至多两张牌，然后交给其等量牌并摸一张牌。结束阶段，若你的体力值与此回合准备阶段开始时相等，你可以执行此回合未选择过的一项。",

  ["@manzhi-turn"] = "蛮智",
  ["manzhi_give"] = "令其交给你两张牌，其视为使用【杀】",
  ["manzhi_active"] = "蛮智",
  ["#manzhi-ask"] = "蛮智：你可以对一名角色发动“蛮智”，执行选项",
  ["#manzhi-slash"] = "蛮智：你可以视为使用一张无距离限制的【杀】",
  ["#manzhi-give"] = "蛮智：请交给 %dest %arg张牌",

  ["$manzhi1"] = "吾有蛮勇可攻，亦有蛮智可御。",
  ["$manzhi2"] = "远交近攻之法，怎可不为我所用。",
}

manzhi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(manzhi.name) then
      if player.phase == Player.Finish then
        if player:getMark("@manzhi-turn") == 0 or player.hp ~= tonumber(player:getMark("@manzhi-turn")) then return end
        local record = player:getTableMark("_manzhi-turn")
        if #record >= 2 then return end
        return table.find(player.room:getOtherPlayers(player, false), function(p)
          return (not table.contains(record, "manzhi_give") and #p:getCardIds("he") > 1) or
            (not table.contains(record, "manzhi_get") and #p:getCardIds("hej") > 0)
        end)
      elseif player.phase == Player.Start then
        return table.find(player.room:getOtherPlayers(player, false), function(p)
          return not p:isAllNude()
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "manzhi_active",
      prompt = "#manzhi-ask",
      cancelable = true,
      no_indicate = false,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    room:addTableMark(player, "_manzhi-turn", choice)
    if choice == "manzhi_give" then
      local cards = room:askToCards(to, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = manzhi.name,
        cancelable = false,
        pattern = nil,
        prompt = "#manzhi-give::"..player.id..":2",
      })
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, manzhi.name, nil, false, player)
      if not to.dead then
        room:askToUseVirtualCard(to, {
          name = "slash",
          skill_name = manzhi.name,
          prompt = "#manzhi-slash",
          cancelable = true,
          extra_data = {
            bypass_distances = true,
            bypass_times = true,
            extraUse = true,
          },
        })
      end
    else
      local cards = room:askToChooseCards(player, {
        skill_name = manzhi.name,
        min = 1,
        max = 2,
        target = to,
        flag = "hej",
      })
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, manzhi.name, nil, false, player)
      local num = #cards
      if player.dead or player:isNude() then return end
      local give = player:getCardIds("he")
      if #give > num then
        give = room:askToCards(player, {
          min_num = num,
          max_num = num,
          include_equip = true,
          skill_name = manzhi.name,
          cancelable = false,
          pattern = nil,
          prompt = "#manzhi-give::"..to.id..":"..num,
        })
      end
      room:moveCardTo(give, Player.Hand, to, fk.ReasonGive, manzhi.name, nil, false, player.id)
      if not player.dead then
        player:drawCards(1, manzhi.name)
      end
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and target:hasSkill(manzhi.name, true) and player.phase == Player.Start
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@manzhi-turn", tostring(player.hp))
  end
})

return manzhi
