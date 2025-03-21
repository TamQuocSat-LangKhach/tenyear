local jixu = fk.CreateSkill {
  name = "jixu",
}

Fk:loadTranslationTable {
  ["jixu"] = "击虚",
  [":jixu"] = "出牌阶段限一次，你可以令任意名体力值相同的其他角色同时猜测你的手牌中是否有【杀】。若有角色猜错，且你：有【杀】，"..
  "你于本回合使用【杀】额外指定所有猜错的角色为目标；没有【杀】，你弃置所有猜错的角色各一张牌。然后你摸等同于猜错的角色数的牌。"..
  "若没有角色猜错，则你结束此阶段。",

  ["#jixu"] = "击虚：令任意名体力值相同的角色猜测你手牌中是否有【杀】",
  ["#jixu-choice"] = "击虚：猜测 %src 的手牌中是否有【杀】",
  ["@@jixu-turn"] = "击虚",

  ["$jixu1"] = "击虚箭射，懈敌戒备。",
  ["$jixu2"] = "虚实难辨，方迷敌方之心！",
}

jixu:addEffect("active", {
  anim_type = "control",
  prompt = "#jixu",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 9,
  can_use = function(self, player)
    return player:usedSkillTimes(jixu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if to_select ~= player then
      if #selected == 0 then
        return true
      else
        return to_select.hp == selected[1].hp
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:sortByAction(effect.tos)
    local result = room:askToJointChoice(player, {
      players = effect.tos,
      choices = {"yes", "no"},
      skill_name = jixu.name,
      prompt = "#jixu-choice:"..player.id,
      send_log = true,
    })
    local right = table.find(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash" end) and "yes" or "no"
    local n = 0
    for _, p in ipairs(effect.tos) do
      local choice = result[p]
      if choice ~= right then
        n = n + 1
        room:doIndicate(player, {p})
        if right == "yes" then
          room:setPlayerMark(p, "@@jixu-turn", 1)
        else
          if not p:isNude() then
            local id = room:askToChooseCard(player, {
              target = p,
              flag = "he",
              skill_name = jixu.name,
            })
            room:throwCard(id, jixu.name, p, player)
            if player.dead then return end
          end
        end
      end
    end
    if n > 0 then
      if not player.dead then
        player:drawCards(n, jixu.name)
      end
    else
      player:endPlayPhase()
    end
  end,
})

jixu:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and
      player:usedEffectTimes(jixu.name, Player.HistoryTurn) > 0 and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@@jixu-turn") > 0 and table.contains(data:getExtraTargets({bypass_distances = true}), p)
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local tos = table.filter(player.room:getOtherPlayers(player, false), function(p)
      return p:getMark("@@jixu-turn") > 0 and table.contains(data:getExtraTargets({bypass_distances = true}), p)
    end)
    event:setCostData(self, {tos = tos})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:getMark("@@jixu-turn") > 0 and table.contains(data:getExtraTargets({bypass_distances = true}), p) then
        data:addTarget(p)
      end
    end
  end,
})

return jixu
