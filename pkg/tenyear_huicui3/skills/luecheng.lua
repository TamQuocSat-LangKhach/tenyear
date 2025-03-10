local luecheng = fk.CreateSkill {
  name = "luecheng"
}

Fk:loadTranslationTable{
  ['luecheng'] = '掠城',
  ['#luecheng'] = '掠城：选择一名其他角色，本回合对其使用当前手牌中的【杀】无次数限制',
  ['@@luecheng-turn'] = '被掠城',
  ['@@luecheng-inhand-phase'] = '掠城',
  ['#luecheng_delay'] = '掠城',
  ['#luecheng-slash'] = '掠城：你可以依次对 %dest 使用手牌中所有【杀】！',
  [':luecheng'] = '出牌阶段限一次，你可以选择一名其他角色，你本回合对其使用当前手牌中的【杀】无次数限制。若如此做，回合结束时，该角色展示手牌：若其中有【杀】，其可选择对你依次使用手牌中所有的【杀】。',
  ['$luecheng1'] = '我等一无所有，普天又有何惧？',
  ['$luecheng2'] = '我视百城为饵，皆可食之果腹。',
}

-- Active Skill
luecheng:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#luecheng",
  can_use = function(self, player)
    return player:usedSkillTimes(luecheng.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "@@luecheng-turn", 1)
    local card
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      card = Fk:getCardById(id)
      if card.trueName == "slash" then
        room:setCardMark(card, "@@luecheng-inhand-phase", 1)
      end
    end
  end,
})

-- TargetMod Skill
luecheng:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and to:getMark("@@luecheng-turn") ~= 0 and card.trueName == "slash" and card:getMark("@@luecheng-inhand-phase") ~= 0
  end,
})

-- Trigger Skill
luecheng:addEffect(fk.EventPhaseEnd, {
  mute = true,
  can_trigger = function(self, event, target, player)
    return not (player.dead or target.dead) and target.phase == Player.Finish and
      player:getMark("@@luecheng-turn") ~= 0 and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local cards = player:getCardIds(Player.Hand)
    player:showCards(cards)
    local slashs = table.filter(cards, function(id)
      return Fk:getCardById(id).trueName == "slash"
    end)
    while #slashs > 0 do
      local pat = "slash|.|.|hand|.|.|" .. table.concat(slashs, ",")
      local use = room:askToUseCard(player, {
        pattern = pat,
        prompt = "#luecheng-slash::" .. target.id,
        cancelable = true,
        extra_data = { exclusive_targets = {target.id}, bypass_distances = true, bypass_times = true }
      })
      if use then
        use.extraUse = true
        room:useCard(use)
      else
        break
      end
      if player.dead or target.dead then break end
      slashs = table.filter(slashs, function(id)
        return table.contains(player:getCardIds(Player.Hand), id) and Fk:getCardById(id).trueName == "slash"
      end)
    end
  end,
  can_refresh = function(self, event, player, data)
    return player == target and data.card.trueName == "slash" and data.card:getMark("@@luecheng-inhand-phase") ~= 0 and
      table.find(TargetGroup:getRealTargets(data.tos), function(pid)
        return player.room:getPlayerById(pid):getMark("@@luecheng-turn") > 0
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

return luecheng
