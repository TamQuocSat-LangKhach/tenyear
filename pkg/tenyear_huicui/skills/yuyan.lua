local yuyan = fk.CreateSkill {
  name = "yuyan"
}

Fk:loadTranslationTable{
  ['yuyan'] = '预言',
  ['#yuyan-choose'] = '是否发动预言，选择一名角色，若其是本轮第一个进入濒死状态或造成伤害的角色，你获得增益',
  ['#yuyan_delay'] = '预言',
  ['@@yuyan-round'] = '预言',
  ['ty__fenyin'] = '奋音',
  [':yuyan'] = '每轮游戏开始时，你选择一名角色，若其是本轮第一个进入濒死状态的角色，则你获得技能〖奋音〗直到你的回合结束。若其是本轮第一个造成伤害的角色，则你摸两张牌。',
  ['$yuyan1'] = '差若毫厘，谬以千里，需慎之。',
  ['$yuyan2'] = '六爻之动，三极之道也。',
}

yuyan:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yuyan.name)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#yuyan-choose",
      skill_name = yuyan.name,
      cancelable = true,
      no_indicate = true
    })
    if #to > 0 then
      event:setCostData(skill, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "yuyan-round", event:getCostData(skill).id)
  end,
})

yuyan:addEffect({fk.AfterDying, fk.Damage}, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not target or player.dead or player:getMark("yuyan-round") ~= target.id then return false end
    local room = player.room
    if event == fk.AfterDying then
      if player:getMark("yuyan_dying_effected-round") > 0 then return false end
      local x = player:getMark("yuyan_dying_record-round")
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.Dying, 1, function (e)
          local dying = e.data[1]
          x = dying.who.id
          room:setPlayerMark(player, "yuyan_dying_record-round", x)
          return true
        end, Player.HistoryRound)
      end
      return target.id == x
    elseif event == fk.Damage then
      local damage_event = room.logic:getCurrentEvent()
      if not damage_event then return false end
      local x = player:getMark("yuyan_damage_record-round")
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local reason = e.data[3]
          if reason == "damage" then
            local first_damage_event = e:findParent(GameEvent.Damage)
            if first_damage_event then
              x = first_damage_event.id
              room:setPlayerMark(player, "yuyan_damage_record-round", x)
            end
            return true
          end
        end, Player.HistoryRound)
      end
      return damage_event.id == x
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(yuyan.name)
    local room = player.room
    if not target.dead then
      room:addPlayerMark(target, "@@yuyan-round")
    end
    if event == fk.AfterDying then
      room:addPlayerMark(player, "yuyan_dying_effected-round")
      if not player:hasSkill("ty__fenyin", true) then
        room:addPlayerMark(player, "yuyan_tmpfenyin")
        room:handleAddLoseSkills(player, "ty__fenyin", nil, true, false)
      end
    elseif event == fk.Damage then
      player:drawCards(2, yuyan.name)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("yuyan_tmpfenyin") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "yuyan_tmpfenyin", 0)
    room:handleAddLoseSkills(player, "-ty__fenyin", nil, true, false)
  end,
})

return yuyan
