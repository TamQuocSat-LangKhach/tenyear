local jiangxian = fk.CreateSkill {
  name = "jiangxian",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["jiangxian"] = "将贤",
  ["#jiangxian"] = "将贤：令你本回合使用〖连捷〗牌伤害+1，回合结束时失去““连捷”或“朝镇”！",
  ["@@jiangxian-turn"] = "将贤",
  ["#jiangxian_delay"] = "将贤",
  ["lianjie"] = "连捷",
  ["chaozhen"] = "朝镇",
  ["@@lianjie-inhand-turn"] = "连捷",
  [":jiangxian"] = "限定技，出牌阶段，你可以令本回合使用因〖连捷〗摸的牌造成伤害时，此伤害+1。若如此做，回合结束后失去〖连捷〗或〖朝镇〗。",
}

jiangxian:addEffect("active", {
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  prompt = "#jiangxian",
  can_use = function(self, player)
    return player:usedSkillTimes(jiangxian.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "@@jiangxian-turn", 1)
  end,
})

jiangxian:addEffect(fk.DamageCaused + fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target and target == player and player:getMark("@@jiangxian-turn") > 0 then
      if event == fk.DamageCaused then
        local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if use_event then
          local use = use_event.data[1]
          return (use.extra_data or {}).jiangxian == player.id
        end
      elseif event == fk.TurnEnd then
        return player:hasSkill(lianjie, true) and 
          (player:hasSkill(lianjie, true) or player:hasSkill(chaozhen, true))
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    elseif event == fk.TurnEnd then
      local choices = table.filter({"lianjie", "chaozhen"}, function (s)
        return player:hasSkill(s, true)
      end)
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = jiangxian.name,
        prompt = "#jiangxian-lose",
      })
      room:handleAddLoseSkills(player, "-"..choice, nil, true, false)
    end
  end,
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@jiangxian-turn") > 0 and data.card.is_damage_card and
      data.card:getMark("@@lianjie-inhand-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.jiangxian = player.id
  end,
})

return jiangxian
