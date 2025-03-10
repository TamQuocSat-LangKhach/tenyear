local ty__fengying = fk.CreateSkill {
  name = "ty__fengying"
}

Fk:loadTranslationTable{
  ['ty__fengying'] = '奉迎',
  ['#ty__fengying'] = '奉迎：你可以弃置所有手牌，此回合结束后执行一个额外回合！',
  ['#ty__fengying_delay'] = '奉迎',
  [':ty__fengying'] = '限定技，出牌阶段，你可以弃置所有手牌，若如此做，此回合结束后，你执行一个额外回合，此额外回合开始时，若你的体力值全场最少，你将手牌摸至体力上限。',
  ['$ty__fengying1'] = '二臣恭奉，以迎皇嗣。',
  ['$ty__fengying2'] = '奉旨典选，以迎忠良。',
}

-- 主动技效果
ty__fengying:addEffect('active', {
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  prompt = function(self, player)
    return "#" .. skill.name
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(ty__fengying.name, Player.HistoryGame) == 0 and
      table.find(player:getCardIds("h"), function(id)
        return not player:prohibitDiscard(Fk:getCardById(id))
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:askToDiscard(player, {
      min_num = #player:getCardIds("h"),
      max_num = #player:getCardIds("h"),
      skill_name = ty__fengying.name,
    })
    if not player.dead then
      player:gainAnExtraTurn(true, ty__fengying.name)
    end
  end,
})

-- 触发技效果
ty__fengying:addEffect(fk.TurnStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:insideExtraTurn() and player:getCurrentExtraTurnReason() == ty__fengying.name and
      player:getHandcardNum() < player.maxHp and
      table.every(player.room.alive_players, function (p)
        return p.hp >= player.hp
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), ty__fengying.name)
  end,
})

return ty__fengying
