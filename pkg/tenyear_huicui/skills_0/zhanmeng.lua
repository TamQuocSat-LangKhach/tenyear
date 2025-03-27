local zhanmeng = fk.CreateSkill { name = "zhanmeng" }

Fk:loadTranslationTable {
  ['zhanmeng'] = '占梦',
  ['zhanmeng1'] = '你获得一张非伤害牌',
  ['zhanmeng2'] = '下一回合内，当同名牌首次被使用后，你获得一张伤害牌',
  ['zhanmeng3'] = '令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害',
  ['#zhanmeng-choice'] = '是否发动 占梦，选择一项效果',
  ['#zhanmeng-choose'] = '占梦: 令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害',
  ['#zhanmeng-discard'] = '占梦：弃置2张牌，若点数之和大于10，%src 对你造成1点火焰伤害',
  ['@zhanmeng_delay'] = '占梦',
  ['#zhanmeng_delay'] = '占梦',
  [':zhanmeng'] = '你使用牌时，可以执行以下一项（每回合每项各限一次）：<br>1.上一回合内，若没有同名牌被使用，你获得一张非伤害牌。<br>2.下一回合内，当同名牌首次被使用后，你获得一张伤害牌。<br>3.令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害。',
  ['$zhanmeng1'] = '梦境缥缈，然有迹可占。',
  ['$zhanmeng2'] = '万物有兆，唯梦可卜。',
}

zhanmeng:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhanmeng.name) then
      local room = player.room
      local mark = player:getMark("zhanmeng_last-turn")
      if type(mark) ~= "table" then
        mark = {}
        local logic = room.logic
        local current_event = logic:getCurrentEvent()
        local all_turn_events = logic.event_recorder[GameEvent.Turn]
        if type(all_turn_events) == "table" then
          local index = #all_turn_events
          if index > 0 then
            local turn_event = current_event:findParent(GameEvent.Turn)
            if turn_event ~= nil then
              index = index - 1
            end
            if index > 0 then
              current_event = all_turn_events[index]
              current_event:searchEvents(GameEvent.UseCard, 1, function (e)
                table.insertIfNeed(mark, e.data[1].card.trueName)
                return false
              end)
            end
          end
        end
        room:setPlayerMark(player, "zhanmeng_last-turn", mark)
      end
      return (player:getMark("zhanmeng1-turn") == 0 and not table.contains(mark, data.card.trueName)) or
        player:getMark("zhanmeng2-turn") == 0 or (player:getMark("zhanmeng3-turn") == 0 and
        not table.every(room.alive_players, function (p)
          return p == player or p:isNude()
        end))
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("zhanmeng_last-turn")
    local choices = {}
    self.cost_data = {}
    if player:getMark("zhanmeng1-turn") == 0 and not table.contains(mark, data.card.trueName) then
      table.insert(choices, "zhanmeng1")
    end
    if player:getMark("zhanmeng2-turn") == 0 then
      table.insert(choices, "zhanmeng2")
    end
    local targets = {}
    if player:getMark("zhanmeng3-turn") == 0 then
      for _, p in ipairs(room.alive_players) do
        if p ~= player and not p:isNude() then
          table.insertIfNeed(choices, "zhanmeng3")
          table.insert(targets, p.id)
        end
      end
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhanmeng.name,
      prompt = "#zhanmeng-choice",
      detailed = false,
      all_choices = {"zhanmeng1", "zhanmeng2", "zhanmeng3", "Cancel"}
    })
    if choice == "Cancel" then return false end
    event:setCostData(self, {choice})
    if choice == "zhanmeng3" then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#zhanmeng-choose",
        skill_name = zhanmeng.name,
        cancelable = true
      })
      if #to > 0 then
        event:setCostData(self, {choice, to[1]})
      else
        return false
      end
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self)[1]
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "zhanmeng1" then
      local cards = {}
      for _, id in ipairs(room.draw_pile) do
        if not Fk:getCardById(id).is_damage_card then
          table.insertIfNeed(cards, id)
        end
      end
      if #cards > 0 then
        local card = table.random(cards)
        room:moveCards({
          ids = {card},
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = zhanmeng.name,
        })
      end
    elseif choice == "zhanmeng2" then
      room:setPlayerMark(player, "zhanmeng_delay-turn", data.card.trueName)
    elseif choice == "zhanmeng3" then
      local p = room:getPlayerById(event:getCostData(self)[2])
      local cards = room:askToDiscard(p, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = zhanmeng.name,
        cancelable = false,
        pattern = ".",
        prompt = "#zhanmeng-discard:"..player.id
      })
      local x = Fk:getCardById(cards[1]).number
      if #cards == 2 then
        x = x + Fk:getCardById(cards[2]).number
      end
      if x > 10 and not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = zhanmeng.name,
        }
      end
    end
  end,
})

zhanmeng:addEffect(fk.AfterTurnEnd, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@zhanmeng_delay", player:getMark("zhanmeng_delay-turn"))
  end
})

local zhanmeng_delay = fk.CreateSkill { name = "#zhanmeng_delay" }

zhanmeng:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes(zhanmeng.name) == 0 and player:getMark("@zhanmeng_delay") == data.card.trueName
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id).is_damage_card then
        table.insertIfNeed(cards, id)
      end
    end
    if #cards > 0 then
      local card = table.random(cards)
      room:moveCards({
        ids = {card},
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = zhanmeng.name,
      })
    end
  end,
})

return zhanmeng
