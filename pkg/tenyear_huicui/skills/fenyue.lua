local fenyue = fk.CreateSkill {
  name = "ty__fenyue",
}

Fk:loadTranslationTable{
  ["ty__fenyue"] = "奋钺",
  [":ty__fenyue"] = "出牌阶段限X次（X为与你不同阵营的存活角色数），你可以与一名角色拼点，若你赢，根据你拼点的牌的点数执行以下效果："..
  "小于等于K：视为对其使用一张雷【杀】；小于等于9：获得牌堆中的一张【杀】；小于等于5：获得其一张牌。",

  ["#ty__fenyue"] = "奋钺：与一名角色拼点，若你赢，根据你拼点牌的点数执行效果",

  ["$ty__fenyue1"] = "逆贼势大，且扎营寨，击其懈怠。",
  ["$ty__fenyue2"] = "兵有其变，不在众寡。",
}

fenyue:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty__fenyue",
  times = function(self, player)
    if player.phase == Player.Play then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.role ~= player.role and
          not (table.contains({"lord", "loyalist"}, player.role) and table.contains({"lord", "loyalist"}, p.role)) then
          n = n + 1
        end
      end
      return n - player:usedSkillTimes(fenyue.name, Player.HistoryPhase)
    else
      return -1
    end
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p.role ~= player.role and
        not (table.contains({"lord", "loyalist"}, player.role) and table.contains({"lord", "loyalist"}, p.role)) then
        n = n + 1
      end
    end
    return player:usedSkillTimes(fenyue.name, Player.HistoryPhase) < n
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, fenyue.name)
    if pindian.results[target].winner == player then
      if pindian.fromCard.number < 6 then
        if not target:isNude() and not player.dead then
          local id = room:askToChooseCard(player, {
            target = target,
            flag = "he",
            skill_name = fenyue.name,
          })
          room:obtainCard(player, id, false, fk.ReasonPrey)
        end
      end
      if pindian.fromCard.number < 10 and not player.dead then
        local card = room:getCardsFromPileByRule("slash")
        if #card > 0 then
          room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, fenyue.name, nil, true, player)
        end
      end
      if pindian.fromCard.number < 14 and not target.dead then
        room:useVirtualCard("thunder__slash", nil, player, target, fenyue.name, true)
      end
    end
  end,
})

return fenyue
