local lulue = fk.CreateSkill {
  name = "lulue",
}

Fk:loadTranslationTable{
  ["lulue"] = "掳掠",
  [":lulue"] = "出牌阶段开始时，你可以令一名有手牌且手牌数小于你的其他角色选择：1.将所有手牌交给你，你翻面；2.翻面，视为对你使用【杀】。",

  ["#lulue-choose"] = "掳掠：你可以令一名有手牌且手牌数小于你的角色选择一项",
  ["lulue_give"] = "将所有手牌交给%src，其翻面",
  ["lulue_slash"] = "你翻面，视为对%src使用【杀】",

  ["$lulue1"] = "趁火打劫，乘危掳掠。",
  ["$lulue2"] = "天下大乱，掳掠以自保。",
}

lulue:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lulue.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng() and p:getHandcardNum() < player:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isKongcheng() and p:getHandcardNum() < player:getHandcardNum()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#lulue-choose",
      skill_name = lulue.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = room:askToChoice(to, {
      choices = {"lulue_give:"..player.id, "lulue_slash:"..player.id},
      skill_name = lulue.name,
    })
    if choice:startsWith("lulue_give") then
      room:obtainCard(player, to:getCardIds("h"), false, fk.ReasonGive, to, lulue.name)
      if not player.dead then
        player:turnOver()
      end
    else
      to:turnOver()
      if not to.dead and not player.dead then
        room:useVirtualCard("slash", nil, to, player, lulue.name, true)
      end
    end
  end,
})

return lulue
