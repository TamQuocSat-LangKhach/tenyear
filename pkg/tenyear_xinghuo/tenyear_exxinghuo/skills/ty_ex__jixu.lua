local ty_ex__jixu = fk.CreateSkill {
  name = "ty_ex__jixu"
}

Fk:loadTranslationTable{
  ['ty_ex__jixu'] = '击虚',
  ['#ty_ex__jixu'] = '击虚：令至多%arg名角色猜测你手牌中是否有【杀】',
  ['#ty_ex__jixu-choice'] = '击虚：猜测 %src 的手牌中是否有【杀】',
  ['@@ty_ex__jixu-turn'] = '击虚',
  ['#ty_ex__jixu_trigger'] = '击虚',
  ['#ty_ex__jixu-invoke'] = '击虚：是否额外指定所有“击虚”猜错的角色为目标？',
  [':ty_ex__jixu'] = '出牌阶段限一次，你可以令至多你体力值数量的其他角色各猜测你的手牌中是否有【杀】。若你的手牌中：有【杀】，此阶段你使用【杀】次数上限+X且可以额外指定所有猜错的角色为目标；没有【杀】，你弃置所有猜错的角色各一张牌。然后你摸X张牌（X为猜错的角色数）。',
  ['$ty_ex__jixu1'] = '辨坚识钝，可解充栋之牛！',
  ['$ty_ex__jixu2'] = '以锐欺虚，可击泰山之踵！',
}

ty_ex__jixu:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = function(player)
    return player.hp
  end,
  prompt = function(player)
    return "#ty_ex__jixu:::"..player.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__jixu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < player.hp and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local targets = table.map(effect.tos, function(id) return room:getPlayerById(id) end)
    local result = U.askForJointChoice(targets, {"yes", "no"}, ty_ex__jixu.name, "#ty_ex__jixu-choice:"..player.id, true)
    local right = table.find(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash" end) and "yes" or "no"
    local n = 0
    for _, p in ipairs(targets) do
      if player.dead then return end
      local choice = result[p.id]
      if choice ~= right then
        n = n + 1
        if not p.dead then
          room:doIndicate(player.id, {p.id})
          if right == "yes" then
            room:setPlayerMark(p, "@@ty_ex__jixu-turn", 1)
          else
            if not p:isNude() then
              local id = room:askToChooseCard(player, {
                target = p,
                flag = "he",
                skill_name = ty_ex__jixu.name
              })
              room:throwCard({id}, ty_ex__jixu.name, p, player)
            end
          end
        end
      end
    end
    if n > 0 and not player.dead then
      if right == "yes" then
        room:setPlayerMark(player, "ty_ex__jixu-turn", n)
      end
      player:drawCards(n, ty_ex__jixu.name)
    end
  end,
})

ty_ex__jixu:addEffect("trigger", {
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(ty_ex__jixu.name, Player.HistoryTurn) > 0 and data.card.trueName == "slash" and
      table.find(player.room:getOtherPlayers(player), function(p)
        return p:getMark("@@ty_ex__jixu-turn") > 0 and table.contains(player.room:getUseExtraTargets(data, true), p.id) end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = ty_ex__jixu.name,
      prompt = "#ty_ex__jixu-invoke"
    }) then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if p:getMark("@@ty_ex__jixu-turn") > 0 and table.contains(room:getUseExtraTargets(data, true), p.id) then
          room:doIndicate(player.id, {p.id})
          table.insertTable(data.tos, {{p.id}})
        end
      end
    end
  end,
})

ty_ex__jixu:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark(ty_ex__jixu.name .. "-turn") > 0 and scope == Player.HistoryPhase then
      return player:getMark(ty_ex__jixu.name .. "-turn")
    end
  end,
})

return ty_ex__jixu
