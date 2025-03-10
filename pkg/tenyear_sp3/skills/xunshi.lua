local xunshi = fk.CreateSkill {
  name = "xunshi"
}

Fk:loadTranslationTable{
  ['xunshi'] = '巡使',
  ['#xunshi_trigger'] = '巡使',
  ['#xunshi-choose'] = '巡御两界，路寻不平！可为此 %arg 额外指定任意个目标',
  [':xunshi'] = '锁定技，你的多目标锦囊牌均视为无色【杀】。你使用无色牌无距离和次数限制且可以额外指定任意个目标，然后〖神裁〗的发动次数+1（至多为5）。',
  ['$xunshi1'] = '秉身为正，辟易万邪！',
  ['$xunshi2'] = '巡御两界，路寻不平！',
}

xunshi:addEffect('filter', {
  mute = true,
  frequency = Skill.Compulsory,
  card_filter = function(self, player, card)
    return player:hasSkill(skill.name) and card.multiple_targets and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", Card.NoSuit, card.number)
  end,
})

xunshi:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunshi.name) and data.card.color == Card.NoColor
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, skill.name)
    player:broadcastSkillInvoke(skill.name)
    if player:hasSkill(shencai, true) and player:getMark("xunshi") < 4 then
      room:addPlayerMark(player, "xunshi", 1)
    end
    local targets = room:getUseExtraTargets(data)
    local n = #targets
    if n == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = n,
      prompt = "#xunshi-choose:::"..data.card:toLogString(),
      skill_name = skill.name,
      cancelable = true,
    })
    if #tos > 0 then
      table.forEach(tos, function (id)
        table.insert(data.tos, {id})
      end)
      room:sendLog{ type = "#AddTargetsBySkill", from = target.id, to = tos, arg = skill.name, arg2 = data.card:toLogString() }
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return player == target and data.card.color == Card.NoColor and player:hasSkill(skill.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

xunshi:addEffect('targetmod', {
  bypass_times = function(self, player, skill2, scope, card)
    return card and card.color == Card.NoColor and player:hasSkill(skill.name)
  end,
  bypass_distances =  function(skill, player, skill2, card)
    return card and card.color == Card.NoColor and player:hasSkill(skill.name)
  end,
})

return xunshi
