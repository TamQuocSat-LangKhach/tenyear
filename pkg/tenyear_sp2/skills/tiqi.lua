local tiqi = fk.CreateSkill {
  name = "tiqi"
}

Fk:loadTranslationTable{
  ['tiqi'] = '涕泣',
  ['tiqi_add'] = '增加手牌上限',
  ['tiqi_minus'] = '减少手牌上限',
  ['#tiqi-choice'] = '涕泣：你可以令%dest本回合的手牌上限增加或减少 %arg',
  [':tiqi'] = '每回合限一次，其他角色的额定的出牌阶段、弃牌阶段、结束阶段开始前，若其于此回合的摸牌阶段内因摸牌而得到过的牌数之和不等于2，你摸那个相差数值的牌，然后可以选择令该角色的手牌上限于此回合内增加或减少同样的数值。',
  ['$tiqi1'] = '远望中原，涕泪交流。',
  ['$tiqi2'] = '瞻望家乡，泣涕如雨。',
}

tiqi:addEffect(fk.EventPhaseChanging, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if
      not (
      player:hasSkill(tiqi.name) and
      player ~= target and
      target and
      not target.dead and
      target:getMark("tiqi-turn") ~= 2 and
      player:usedSkillTimes(tiqi.name) < 1
    )
    then
      return false
    end

    if data.to == Player.Play or data.to == Player.Discard or data.to == Player.Finish then
      --FIXME:无法判断是否处于额外阶段@Ho-spair
      return
        target.skipped_phases[Player.Draw] or
        #player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
          return e.data[2] == Player.Draw
        end, Player.HistoryTurn) > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.abs(target:getMark("tiqi-turn") - 2)
    player:drawCards(n, tiqi.name)
    local choice = room:askToChoice(player, {
      choices = {"tiqi_add", "tiqi_minus", "Cancel"},
      skill_name = tiqi.name,
      prompt = "#tiqi-choice::" .. target.id .. ":" .. tostring(n),
    })
    if choice == "tiqi_add" then
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, n)
    elseif choice == "tiqi_minus" then
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, n)
    end
  end,
})

tiqi:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player.phase == Player.Draw
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to == player.id and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        player.room:addPlayerMark(player, "tiqi-turn", #move.moveInfo)
      end
    end
  end,
})

return tiqi
