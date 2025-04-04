local luecheng = fk.CreateSkill {
  name = "luecheng",
}

Fk:loadTranslationTable{
  ["luecheng"] = "掠城",
  [":luecheng"] = "出牌阶段限一次，你可以选择一名其他角色，你本回合对其使用当前手牌中的【杀】无次数限制。若如此做，回合结束时，"..
  "该角色展示手牌：若其中有【杀】，其可以对你依次使用手牌中所有的【杀】。",

  ["#luecheng"] = "掠城：选择一名其他角色，本回合对其使用当前手牌中的【杀】无次数限制",
  ["@@luecheng-turn"] = "被掠城",
  ["@@luecheng-inhand-phase"] = "掠城",
  ["#luecheng-slash"] = "掠城：你可以依次对 %dest 使用手牌中所有【杀】！",

  ["$luecheng1"] = "我等一无所有，普天又有何惧？",
  ["$luecheng2"] = "我视百城为饵，皆可食之果腹。",
}

luecheng:addEffect("active", {
  anim_type = "offensive",
  prompt = "#luecheng",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(luecheng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(target, "@@luecheng-turn", player.id)
    local card
    for _, id in ipairs(player:getCardIds("h")) do
      card = Fk:getCardById(id)
      if card.trueName == "slash" then
        room:setCardMark(card, "@@luecheng-inhand-phase", 1)
      end
    end
  end,
})

luecheng:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(to:getTableMark("@@luecheng-turn"), player.id) and
      card.trueName == "slash" and card:getMark("@@luecheng-inhand-phase") > 0
  end,
})

luecheng:addEffect(fk.EventPhaseEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and target.phase == Player.Finish and
      not player:isKongcheng() and
      table.find(player:getTableMark("@@luecheng-turn"), function (id)
        return not player.room:getPlayerById(id).dead
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:showCards(player:getCardIds("h"))
    if player.dead then return end
    local slashs = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end)
    local targets = table.map(player:getTableMark("@@luecheng-turn"), Util.Id2PlayerMapper)
    targets = table.filter(targets, function(p)
      return not p.dead
    end)
    while not player.dead and #slashs > 0 and #targets > 0 do
      local use = room:askToUseCard(player, {
        skill_name = luecheng.name,
        pattern = "slash|.|.|hand|.|.|" .. table.concat(slashs, ","),
        prompt = "#luecheng-slash::"..targets[1].id,
        cancelable = true,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          exclusive_targets = player:getTableMark("@@luecheng-turn"),
        }
      })
      if use then
        use.extraUse = true
        room:useCard(use)
      else
        break
      end
      slashs = table.filter(slashs, function(id)
        return table.contains(player:getCardIds("h"), id) and Fk:getCardById(id).trueName == "slash"
      end)
      targets = table.filter(targets, function(p)
        return not p.dead
      end)
    end
  end,
})

luecheng:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and
      data.card:getMark("@@luecheng-inhand-phase") > 0 and
      table.find(data.tos, function(p)
        return table.contains(p:getTableMark("@@luecheng-turn"), player.id)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

return luecheng
