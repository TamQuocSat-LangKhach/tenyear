local jiezhen = fk.CreateSkill {
  name = "jiezhen"
}

Fk:loadTranslationTable{
  ['jiezhen'] = '解阵',
  ['#jiezhen-active'] = '发动 解阵，将一名角色的技能替换为〖八阵〗',
  ['@@jiezhen'] = '解阵',
  ['#jiezhen_trigger'] = '解阵',
  [':jiezhen'] = '出牌阶段限一次，你可令一名其他角色的所有技能替换为〖八阵〗（锁定技、限定技、觉醒技、主公技除外）。你的回合开始时或当其【八卦阵】判定后，你令其失去〖八阵〗并获得原技能，然后你获得其区域里的一张牌。',
  ['$jiezhen1'] = '八阵无破，唯解死而向生。',
  ['$jiezhen2'] = '此阵，可由景门入、生门出。',
}

jiezhen:addEffect('active', {
  anim_type = "control",
  prompt = "#jiezhen-active",
  can_use = function(self, player)
    return player:usedSkillTimes(jiezhen.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select.id ~= player.id and Fk:currentRoom():getPlayerById(to_select.id):getMark("@@jiezhen") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "@@jiezhen", 1)
    room:setPlayerMark(target, "jiezhen_source", effect.from.id)
    if not target:hasSkill("bazhen", true) then
      room:addPlayerMark(target, "jiezhen_tmpbazhen")
      room:handleAddLoseSkills(target, "bazhen", nil, true, false)
    end
  end,
})

jiezhen:addEffect({fk.FinishJudge, fk.TurnStart}, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jiezhen.name) then
      if event == fk.FinishJudge then
        return not target.dead and table.contains({"bazhen", "eight_diagram"}, data.reason) and
          target:getMark("jiezhen_source") == player.id
      elseif event == fk.TurnStart then
        if target == player then
          for _, p in ipairs(player.room.alive_players) do
            if p:getMark("jiezhen_source") == player.id then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    if event == fk.TurnStart then
      tos = table.filter(room.alive_players, function (p) return p:getMark("jiezhen_source") == player.id end)
    else
      table.insert(tos, target)
    end
    room:doIndicate(player.id, table.map(tos, Util.IdMapper))
    for _, to in ipairs(tos) do
      if player.dead then break end
      room:setPlayerMark(to, "jiezhen_source", 0)
      room:setPlayerMark(to, "@@jiezhen", 0)
      if to:getMark("jiezhen_tmpbazhen") > 0 then
        room:handleAddLoseSkills(to, "-bazhen", nil, true, false)
      end
      if not to:isAllNude() then
        local card = room:askToChooseCard(player, {
          target = to,
          flag = "hej",
          skill_name = jiezhen.name
        })
        room:obtainCard(player.id, card, false, fk.ReasonPrey)
      end
    end
  end,
})

jiezhen:addEffect('invalidity', {
  invalidity_func = function(self, from, skill_to_check)
    if from:getMark("@@jiezhen") > 0 then
      return not (table.contains({Skill.Compulsory, Skill.Limited, Skill.Wake}, skill_to_check.frequency) or
        not skill_to_check:isPlayerSkill(from) or skill_to_check.lordSkill)
    end
  end
})

return jiezhen
