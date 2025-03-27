local fengying = fk.CreateSkill {
  name = "ty__fengying",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ty__fengying"] = "奉迎",
  [":ty__fengying"] = "限定技，出牌阶段，你可以弃置所有手牌，若如此做，此回合结束后，你执行一个额外回合；此额外回合开始时，若你的体力值全场最少，"..
  "你将手牌摸至体力上限。",

  ["#ty__fengying"] = "奉迎：你可以弃置所有手牌，此回合结束后执行一个额外回合！",

  ["$ty__fengying1"] = "二臣恭奉，以迎皇嗣。",
  ["$ty__fengying2"] = "奉旨典选，以迎忠良。",
}

fengying:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#ty__fengying",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(fengying.name, Player.HistoryGame) == 0 and
      table.find(player:getCardIds("h"), function(id)
        return not player:prohibitDiscard(Fk:getCardById(id))
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:throwAllCards("h", fengying.name)
    if not player.dead then
      player:gainAnExtraTurn(true, fengying.name)
    end
  end,
})

fengying:addEffect(fk.TurnStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getCurrentExtraTurnReason() == fengying.name and
      player:getHandcardNum() < player.maxHp and
      table.every(player.room.alive_players, function (p)
        return p.hp >= player.hp
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), fengying.name)
  end,
})

return fengying
