local jixu = fk.CreateSkill { name = "jixu" }

Fk:loadTranslationTable {
  ['jixu'] = '击虚',
  ['#jixu'] = '击虚：令任意名体力值相同的角色猜测你手牌中是否有【杀】',
  ['#jixu-choice'] = '击虚：猜测 %src 的手牌中是否有【杀】',
  ['@@jixu-turn'] = '击虚',
  ['#jixu_trigger'] = '击虚',
  [':jixu'] = '出牌阶段限一次，你可令任意名体力值相同的其他角色同时猜测你的手牌中是否有【杀】。若有角色猜错，且你：有【杀】，你于本回合使用【杀】额外指定所有猜错的角色为目标；没有【杀】，你弃置所有猜错的角色各一张牌。然后你摸等同于猜错的角色数的牌。若没有角色猜错，则你结束此阶段。',
  ['$jixu1'] = '击虚箭射，懈敌戒备。',
  ['$jixu2'] = '虚实难辨，方迷敌方之心！',
}

jixu:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 999,
  prompt = "#jixu",
  can_use = function(self, player)
    return player:usedSkillTimes(jixu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if to_select ~= player.id then
      if #selected == 0 then
        return true
      else
        return Fk:currentRoom():getPlayerById(to_select).hp == Fk:currentRoom():getPlayerById(selected[1]).hp
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    local result = U.askForJointChoice(targets, {"yes", "no"}, jixu.name, "#jixu-choice:"..player.id, true)
    local right = table.find(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash" end) and "yes" or "no"
    local n = 0
    for _, p in ipairs(targets) do
      local choice = result[p.id]
      if choice ~= right then
        n = n + 1
        room:doIndicate(player.id, {p.id})
        if right == "yes" then
          room:setPlayerMark(p, "@@jixu-turn", 1)
        else
          if not p:isNude() then
            local id = room:askToChooseCard(player, {
              target = p,
              flag = "he",
              skill_name = jixu.name,
            })
            room:throwCard({id}, jixu.name, p, player)
          end
        end
      end
    end
    if n > 0 then
      player:drawCards(n, jixu.name)
    else
      player._phase_end = true
    end
  end,
})

jixu:addEffect(fk.AfterCardTargetDeclared, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(jixu.name, Player.HistoryTurn) > 0 and data.card.trueName == "slash" and
      table.find(player.room:getOtherPlayers(player), function(p)
        return p:getMark("@@jixu-turn") > 0 and table.contains(player.room:getUseExtraTargets(data, true), p.id)
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:getMark("@@jixu-turn") > 0 and table.contains(room:getUseExtraTargets(data, true), p.id) then
        room:doIndicate(player.id, {p.id})
        TargetGroup:pushTargets(data.targetGroup, p.id)
      end
    end
  end,
})

return jixu
