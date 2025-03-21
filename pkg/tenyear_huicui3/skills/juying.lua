local juying = fk.CreateSkill {
  name = "juying"
}

Fk:loadTranslationTable{
  ['juying'] = '踞营',
  ['juying1'] = '下个回合出牌阶段使用【杀】上限+1',
  ['juying2'] = '本回合手牌上限+2',
  ['juying3'] = '摸三张牌',
  ['#juying-choice'] = '踞营：你可以选择任意项，每比体力值多选一项便弃一张牌',
  [':juying'] = '出牌阶段结束时，若你本阶段使用【杀】或【酒】的次数小于次数上限，你可以选择任意项：1.下个回合出牌阶段使用【杀】次数上限+1；2.本回合手牌上限+2；3.摸三张牌。若你选择的选项数大于你的体力值，你弃置一张牌。',
  ['$juying1'] = '垒石为寨，纵万军亦可阻。',
  ['$juying2'] = '如虎踞汝南，攻守自有我。',
}

juying:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(juying) and player.phase == Player.Play then
      for _, name in ipairs({ "slash", "analeptic" }) do
        local card = Fk:cloneCard(name)
        local card_skill = card.skill
        local status_skills = Fk:currentRoom().status_skills[TargetModSkill] or Util.DummyTable
        for _, skill in ipairs(status_skills) do
          if skill:bypassTimesCheck(player, card_skill, Player.HistoryPhase, card, nil) then return true end
        end
        local history = name == "slash" and Player.HistoryPhase or Player.HistoryTurn
        local limit = card_skill:getMaxUseTime(player, history, card, nil)
        if not limit or player:usedCardTimes(name, Player.HistoryPhase) < limit then
          return true
        end
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local all_choices = {"juying1", "juying2", "juying3"}
    local choices = room:askToChoices(player, {
      choices = all_choices,
      min_num = 1,
      max_num = 3,
      skill_name = juying.name,
      prompt = "#juying-choice",
      cancelable = true
    })

    if #choices == 0 then return false end

    if table.contains(choices, "juying1") then
      room:addPlayerMark(player, juying.name)
    end
    if table.contains(choices, "juying2") then
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 2)
    end
    if table.contains(choices, "juying3") then
      player:drawCards(3, juying.name)
    end

    if not player.dead and #choices > player.hp then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = juying.name,
        cancelable = false
      })
    end
  end,
})

juying:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(juying.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.SlashResidue .. "-turn", player:getMark(juying.name))
    room:setPlayerMark(player, juying.name, 0)
  end,
})

return juying
