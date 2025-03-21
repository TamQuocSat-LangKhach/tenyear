local longsong = fk.CreateSkill {
  name = "longsong"
}

Fk:loadTranslationTable{
  ['longsong'] = '龙诵',
  ['#longsong-invoke'] = '龙诵：你可以交给或获得一名其他角色一张红色牌，本阶段获得其拥有的一个“出牌阶段”技能',
  [':longsong'] = '出牌阶段开始时，你可以交给或随机获得一名其他角色一张红色牌，然后你本阶段视为拥有该角色的一个“出牌阶段”的技能直到你发动之（若未获得其的技能则改为随机获得一个技能池中的技能）。<br><font color=>村：能获取的技能包括所有主动技和转化技、描述前4字为“出牌阶段”且后不接“开始时”和“结束时”的技能；随机技能池同许劭。</font>',
  ['$longsong1'] = '百家诸子，且听九霄龙吟。',
  ['$longsong2'] = '朗朗书声，岂虚于刀斧铮鸣。',
}

longsong:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(longsong) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local tos, cards = player.room:askToChooseCardsAndPlayers(player, {
      min_card_num = 0,
      max_card_num = 1,
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_target_num = 1,
      max_target_num = 1,
      pattern = ".|.|heart,diamond",
      prompt = "#longsong-invoke",
      skill_name = longsong.name,
      cancelable = true
    })
    if #tos == 1 then
      event:setCostData(skill, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(skill)
    local to = room:getPlayerById(cost_data.tos[1])
    local cards = table.simpleClone(cost_data.cards)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, longsong.name, nil, false, player.id)
    else
      cards = table.filter(to:getCardIds("he"), function(id) return Fk:getCardById(id).color == Card.Red end)
      if #cards > 0 then
        room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonPrey, longsong.name, nil, false, player.id)
      end
    end
    if player.dead then return end
    local skills = {}
    local ban_list = {"xionghuo", "mobile__xionghuo", "n_dunshi", "dunshi"}
    for _, s in ipairs(to.player_skills) do
      if not table.contains(ban_list, s.name) and s:isPlayerSkill(to) and not player:hasSkill(s, true) and s.frequency < 4 then
        if table.contains(longsong_skills, s.name) or s:isInstanceOf(ActiveSkill) or s:isInstanceOf(ViewAsSkill) then
          table.insertIfNeed(skills, s.name)
        elseif s:isInstanceOf(TriggerSkill) then
          local str = Fk:translate(":"..s.name)
          if string.sub(str, 1, 12) == "出牌阶段" and string.sub(str, 13, 18) ~= "开始" and string.sub(str, 13, 18) ~= "结束" then
            table.insertIfNeed(skills, s.name)
          end
        end
      end
    end
    if #skills == 0 then
      skills = table.filter(longsong_skills, function (skill_name)
        return Fk.skills[skill_name] and not player:hasSkill(skill_name, true)
      end)
    end
    if #skills > 0 then
      local skill = table.random(skills)
      room:setPlayerMark(player, "longsong-phase", skill)
      room:handleAddLoseSkills(player, skill, nil, true, false)
      room.logic:getCurrentEvent():findParent(GameEvent.Phase):addCleaner(function()
        room:handleAddLoseSkills(player, "-"..skill)
      end)
    end
  end,
})

longsong:addEffect('invalidity', {
  invalidity_func = function(self, from, skill_name)
    return from:getMark("longsong-phase") ~= 0 and from:getMark("longsong-phase") == skill.name and
      from:usedSkillTimes(skill.name, Player.HistoryPhase) > 0
  end
})

return longsong
