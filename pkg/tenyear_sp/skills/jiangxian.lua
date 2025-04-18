local jiangxian = fk.CreateSkill {
  name = "jiangxian",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["jiangxian"] = "将贤",
  [":jiangxian"] = "限定技，出牌阶段，你可以令本回合使用因〖连捷〗摸的牌造成伤害时，此伤害+X（X为你本回合造成伤害次数，至多为5）。\
  若如此做，回合结束后失去〖连捷〗或〖朝镇〗。",

  ["#jiangxian"] = "将贤：令你本回合使用〖连捷〗牌伤害+1，回合结束时失去““连捷”或“朝镇”！",
  ["@@jiangxian-turn"] = "将贤",
  ["#jiangxian-lose"] = "将贤：选择失去的技能",
}

jiangxian:addEffect("active", {
  anim_type = "special",
  prompt = "#jiangxian",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(jiangxian.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    room:setPlayerMark(effect.from, "@@jiangxian-turn", 1)
  end,
})

jiangxian:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("@@jiangxian-turn") > 0 and data.card then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data
        if use.extra_data and use.extra_data.jiangxian == player then
          local n = #player.room.logic:getActualDamageEvents(5, function (e)
            return e.data.from == player
          end, Player.HistoryTurn)
          if n > 0 then
            event:setCostData(self, {choice = n})
            return true
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(event:getCostData(self).choice)
  end,
})

jiangxian:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@jiangxian-turn") > 0 and
      data.card.is_damage_card and data.card:getMark("@@lianjie-inhand-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.jiangxian = player
  end,
})

jiangxian:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@jiangxian-turn") > 0 and
      (player:hasSkill("lianjie", true) or player:hasSkill("chaozhen", true))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = table.filter({"lianjie", "chaozhen"}, function (s)
      return player:hasSkill(s, true)
    end)
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = jiangxian.name,
      prompt = "#jiangxian-lose",
    })
    room:handleAddLoseSkills(player, "-"..choice)
  end,
})

return jiangxian
