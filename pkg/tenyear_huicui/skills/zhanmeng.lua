local zhanmeng = fk.CreateSkill {
  name = "zhanmeng",
}

Fk:loadTranslationTable {
  ["zhanmeng"] = "占梦",
  [":zhanmeng"] = "你使用牌时，可以执行以下一项（每回合每项各限一次）：<br>"..
  "1.上一回合内，若没有同名牌被使用，你获得一张非伤害牌。<br>"..
  "2.下一回合内，当同名牌首次被使用后，你获得一张伤害牌。<br>"..
  "3.令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害。",

  ["zhanmeng1"] = "获得一张非伤害牌",
  ["zhanmeng2"] = "下回合内，当同名牌首次被使用后，你获得一张伤害牌",
  ["zhanmeng3"] = "令一名角色弃两张牌，若点数之和大于10，对其造成1点火焰伤害",
  ["#zhanmeng-choose"] = "占梦: 令一名角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害",
  ["#zhanmeng-discard"] = "占梦：弃置两张牌，若点数之和大于10，%src 对你造成1点火焰伤害",
  ["@zhanmeng_delay"] = "占梦",
  ["@zhanmeng_delay-turn"] = "占梦",

  ["$zhanmeng1"] = "梦境缥缈，然有迹可占。",
  ["$zhanmeng2"] = "万物有兆，唯梦可卜。",
}

zhanmeng:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhanmeng.name) then
      local room = player.room
      local choices = {}
      if player:getMark("zhanmeng1-turn") == 0 then
        local yes = false
        local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
        local turn_event_id = turn_event and turn_event.id or room.logic:getCurrentEvent().id
        local turn_events = room.logic:getEventsByRule(GameEvent.Turn, 1, function (e)
          return e.id < turn_event_id
        end)
        if #turn_events > 0 then
          room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
            if e.id > turn_events[1].id and e.id < turn_events[1].end_id then
              if e.data.card.trueName == data.card.trueName then
                yes = true
                return true
              end
            end
          end, turn_events[1].id)
        end
        if not yes then
          table.insert(choices, "zhanmeng1")
        end
      end
      if player:getMark("zhanmeng2-turn") == 0 then
        table.insert(choices, "zhanmeng2")
      end
      if player:getMark("zhanmeng3-turn") == 0 and
        table.find(room:getOtherPlayers(player, false), function (p)
          return not p:isNude()
        end) then
        table.insert(choices, "zhanmeng3")
      end
      if #choices > 0 then
        event:setCostData(self, {extra_data = choices})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = event:getCostData(self).extra_data
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhanmeng.name,
      all_choices = {"zhanmeng1", "zhanmeng2", "zhanmeng3", "Cancel"}
    })
    if choice ~= "Cancel" then
      if choice == "zhanmeng3" then
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return not p:isNude()
        end)
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#zhanmeng-choose",
          skill_name = zhanmeng.name,
          cancelable = true,
        })
        if #to > 0 then
          event:setCostData(self, {tos = to, choice = choice})
          return true
        else
          return
        end
      else
        event:setCostData(self, {choice = choice})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "zhanmeng1" then
      local cards = table.filter(room.draw_pile, function (id)
        return not Fk:getCardById(id).is_damage_card
      end)
      if #cards > 0 then
        room:moveCards({
          ids = table.random(cards, 1),
          to = player,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player,
          skillName = zhanmeng.name,
        })
      end
    elseif choice == "zhanmeng2" then
      room:setPlayerMark(player, "@zhanmeng_delay", data.card.trueName)
    elseif choice == "zhanmeng3" then
      local to = event:getCostData(self).tos[1]
      local cards = room:askToDiscard(to, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = zhanmeng.name,
        cancelable = false,
        prompt = "#zhanmeng-discard:"..player.id,
      })
      if #cards > 0 then
        local n = 0
        for _, id in ipairs(cards) do
          n = n + Fk:getCardById(id).number
        end
        if n > 10 and not to.dead then
          room:damage{
            from = player,
            to = to,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = zhanmeng.name,
          }
        end
      end
    end
  end,
})

zhanmeng:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return player:getMark("@zhanmeng_delay") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@zhanmeng_delay-turn", player:getMark("@zhanmeng_delay"))
    room:setPlayerMark(player, "@zhanmeng_delay", 0)
  end,
})

zhanmeng:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@zhanmeng_delay-turn") == data.card.trueName
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@zhanmeng_delay-turn", 0)
    local cards = table.filter(room.draw_pile, function (id)
      return Fk:getCardById(id).is_damage_card
    end)
    if #cards > 0 then
      room:moveCards({
        ids = table.random(cards, 1),
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = zhanmeng.name,
      })
    end
  end,
})

zhanmeng:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "zhanmeng1", 0)
  room:setPlayerMark(player, "zhanmeng2", 0)
  room:setPlayerMark(player, "zhanmeng3", 0)
end)

return zhanmeng
