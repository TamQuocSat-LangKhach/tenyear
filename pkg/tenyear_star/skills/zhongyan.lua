local zhongyan = fk.CreateSkill {
  name = "zhongyanz",
}

Fk:loadTranslationTable{
  ["zhongyanz"] = "忠言",
  [":zhongyanz"] = "出牌阶段限一次，你可展示牌堆顶三张牌，令一名角色将一张手牌交换其中一张牌。然后若这些牌颜色相同，其选择回复1点体力或"..
  "获得场上一张牌；若该角色不为你，你执行另一项。",

  ["#zhongyanz"] = "忠言：亮出牌堆顶三张牌，令一名角色用一张手牌交换其中一张牌",
  ["#zhongyanz-exchange"] = "忠言：请用一张手牌交换其中一张牌",
  ["zhongyanz_prey"] = "获得场上一张牌",
  ["#zhongyanz-choose"] = "忠言：选择一名角色，获得其场上一张牌",

  ["$zhongyanz1"] = "腹有珠玑，可坠在殿之玉盘。",
  ["$zhongyanz2"] = "胸纳百川，当汇凌日之沧海。",
}

Fk:addPoxiMethod{
  name = "zhongyanz",
  prompt = "#zhongyanz-exchange",
  card_filter = function(to_select, selected, data)
    if #selected < 2 then
      if #selected == 0 then
        return true
      else
        if table.contains(data[1][2], selected[1]) then
          return table.contains(data[2][2], to_select)
        else
          return table.contains(data[1][2], to_select)
        end
      end
    end
  end,
  feasible = function(selected)
    return #selected == 2
  end,
  default_choice = function (data, extra_data)
    return {data[1][2][1], data[2][2][1]}
  end,
}

local function DoZhongyanz(player, source, choice)
  local room = player.room
  if choice == "recover" then
    if not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = source,
        skillName = zhongyan.name,
      }
    end
  else
    local targets = table.filter(room.alive_players, function(p)
      return #p:getCardIds("ej") > 0
    end)
    if not player.dead and #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = zhongyan.name,
        prompt = "#zhongyanz-choose",
        cancelable = false,
      })[1]
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "ej",
        skill_name = zhongyan.name,
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, zhongyan.name, nil, true, player)
    end
  end
end

zhongyan:addEffect("active", {
  anim_type = "support",
  prompt = "#zhongyanz",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhongyan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (skill, player, to_select, selected)
    return #selected == 0 and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local to = effect.tos[1]
    local cards = room:getNCards(3)
    room:turnOverCardsFromDrawPile(player, cards, zhongyan.name)
    if to.dead or to:isKongcheng() then
      room:cleanProcessingArea(cards)
      return
    end
    local results = room:askToPoxi(to, {
      poxi_type = zhongyan.name,
      data = {
        { "Top", cards },
        { "$Hand", to:getCardIds("h") },
      },
      cancelable = false,
    })
    local to_hand = {}
    if #results > 0 then
      to_hand = table.filter(results, function(id)
        return table.contains(cards, id)
      end)
      table.removeOne(results, to_hand[1])
      for i = #cards, 1, -1 do
        if cards[i] == to_hand[1] then
          cards[i] = results[1]
          break
        end
      end
    else
      to_hand, cards[1] = {cards[1]}, to:getCardIds("h")[1]
    end
    room:swapCardsWithPile(to, cards, to_hand, zhongyan.name, "Top", false, to)
    if to.dead then return end
    if table.every(cards, function(id)
      return Fk:getCardById(id).color == Fk:getCardById(cards[1]).color
    end) then
      local choices = {"recover", "zhongyanz_prey"}
      local choice = room:askToChoice(to, {
        choices = choices,
        skill_name = zhongyan.name,
      })
      DoZhongyanz(to, player, choice)
      if to ~= player then
        table.removeOne(choices, choice)
        DoZhongyanz(player, player, choices[1])
      end
    end
  end,
})

return zhongyan
