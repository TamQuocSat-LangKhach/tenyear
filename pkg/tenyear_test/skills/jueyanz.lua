local jueyanz = fk.CreateSkill{
  name = "jueyanz",
  dynamic_desc = function (self, player)
    return "jueyanz_inner:"
      ..(1 + player:getMark("jueyanz_draw"))
      ..":"..(1 + player:getMark("jueyanz_prey"))
      ..":"..(1 + player:getMark("jueyanz_pindian"))
  end
}

Fk:loadTranslationTable{
  ["jueyanz"] = "诀言",
  [":jueyanz"] = "当你使用仅指定唯一目标的手牌结算结束后（每回合每种类别限一次），你可以选择一项：<br>"..
  "1.摸1张牌；<br>2.随机获得弃牌堆1张牌；<br>3.与一名角色拼点，赢的角色对没赢的角色造成1点伤害。<br>"..
  "然后，此次选择的选项的数值改为1，其他选项的数值均+1。",

  [":jueyanz_inner"] = "当你使用仅指定唯一目标的手牌结算结束后（每回合每种类别限一次），你可以选择一项：<br>"..
  "1.摸{1}张牌；<br>2.随机获得弃牌堆{2}张牌；<br>3.与一名角色拼点，赢的角色对没赢的角色造成{3}点伤害。<br>"..
  "然后，此次选择的选项的数值改为1，其他选项的数值均+1。",

  ["jueyanz_draw"] = "摸%arg张牌",
  ["jueyanz_prey"] = "随机获得弃牌堆%arg张牌",
  ["jueyanz_pindian"] = "与一名角色拼点，赢者对没赢者造成%arg点伤害",
  ["#jueyanz-choose"] = "诀言：与一名角色拼点，赢的角色对没赢的角色造成%arg点伤害",

  ["$jueyanz1"] = "",
  ["$jueyanz2"] = "",
}

jueyanz:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jueyanz.name) and
      data:IsUsingHandcard(player) and #data.tos > 0 and data:isOnlyTarget(data.tos[1]) and
      not table.contains(player:getTableMark("jueyanz-turn"), data.card.type)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local all_choices = {
      "jueyanz_draw:::"..(1 + player:getMark("jueyanz_draw")),
      "jueyanz_prey:::"..(1 + player:getMark("jueyanz_prey")),
      "jueyanz_pindian:::"..(1 + player:getMark("jueyanz_pindian")),
      "Cancel",
    }
    local choices = table.simpleClone(all_choices)
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canPindian(p)
    end)
    if #targets == 0 then
      table.remove(choices, 3)
    end
    if #room.discard_pile == 0 then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = jueyanz.name,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      if choice:startsWith("jueyanz_pindian") then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = jueyanz.name,
          prompt = "#jueyanz-choose:::"..(1 + player:getMark("jueyanz_pindian")),
          cancelable = true,
        })
        if #to > 0 then
          event:setCostData(self, {tos = to, choice = string.split(choice, ":")[1]})
          return true
        end
      else
        event:setCostData(self, {choice = string.split(choice, ":")[1]})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "jueyanz-turn", data.card.type)
    local choice = event:getCostData(self).choice
    if choice == "jueyanz_draw" then
      player:drawCards(1 + player:getMark("jueyanz_draw"), jueyanz.name)
    elseif choice == "jueyanz_prey" then
      local cards = table.random(room.discard_pile, 1 + player:getMark("jueyanz_prey"))
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, jueyanz.name, nil, true, player)
    elseif choice == "jueyanz_pindian" then
      local to = event:getCostData(self).tos[1]
      local pindian = player:pindian({to}, jueyanz.name)
      local winner = pindian.results[to].winner
      if winner then
        if winner == to then
          to = player
        end
        if not to.dead then
          room:damage{
            from = winner,
            to = to,
            damage = 1 + player:getMark("jueyanz_pindian"),
            skillName = jueyanz.name,
          }
        end
      end
    end
    if not player.dead and player:hasSkill(jueyanz.name, true) then
      for _, c in ipairs({"jueyanz_draw", "jueyanz_prey", "jueyanz_pindian"}) do
        if c == choice then
          room:setPlayerMark(player, c, 0)
        else
          room:addPlayerMark(player, c, 1)
        end
      end
    end
  end,
})

jueyanz:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, name in ipairs({"jueyanz_draw", "jueyanz_prey", "jueyanz_pindian", "jueyanz-turn"}) do
    room:setPlayerMark(player, name, 0)
  end
end)

return jueyanz
