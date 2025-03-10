local fujue = fk.CreateSkill {
  name = "fujue"
}

Fk:loadTranslationTable{
  ['fujue'] = '复爵',
  ['#fujue'] = '复爵：你可以移动场上一张牌，然后将你的牌调整至五张',
  [':fujue'] = '出牌阶段限一次，你可以移动场上一张牌，然后将你的牌调整至五张。若此过程中你获得且失去过牌，本回合你计算与其他角色的距离-1。',
  ['$fujue1'] = '《周礼》有言，爵分公、侯、伯、子、男。',
  ['$fujue2'] = '复五等之爵，明尊卑之序。',
}

fujue:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  prompt = "#fujue",
  can_use = function(self, player)
    return player:usedSkillTimes(fujue.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (skill, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:currentRoom():getPlayerById(selected[1]):canMoveCardsInBoardTo(target)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    local result = room:askToMoveCardInBoard(player, {
      target_one = targets[1],
      target_two = targets[2],
      skill_name = fujue.name,
    })
    if not result then return end
    local yes1, yes2 = result.to == player.id, result.from == player.id
    if player.dead then return end
    local n = #player:getCardIds("he") - 5
    if n > 0 then
      if #room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = fujue.name,
        cancelable = false,
      }) > 0 then
        yes2 = true
      end
    elseif n < 0 then
      yes1 = true
      player:drawCards(-n, fujue.name)
    end
    if player.dead then return end
    if yes1 and yes2 then
      room:addPlayerMark(player, "fujue-turn", 1)
    end
  end,
})

fujue:addEffect('distance', {
  name = "#fujue_distance",
  correct_func = function(self, from, to)
    return -from:getMark("fujue-turn")
  end,
})

return fujue
