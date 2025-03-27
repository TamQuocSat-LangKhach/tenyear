local xiangmian = fk.CreateSkill {
  name = "xiangmian"
}

Fk:loadTranslationTable{
  ['xiangmian'] = '相面',
  ['#xiangmian-active'] = '发动相面，令一名其他角色判定',
  ['@xiangmian'] = '相面',
  [':xiangmian'] = '出牌阶段限一次，你可以令一名其他角色进行一次判定，当该角色使用判定花色的牌或使用第X张牌后（X为判定点数），其失去所有体力。每名其他角色限一次。',
  ['$xiangmian1'] = '以吾之见，阁下命不久矣。',
  ['$xiangmian2'] = '印堂发黑，将军危在旦夕。',
}

xiangmian:addEffect('active', {
  anim_type = "offensive",
  prompt = "#xiangmian-active",
  can_use = function(self, player)
    return player:usedSkillTimes(xiangmian.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select):getMark("xiangmian_suit") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local judge = {
      who = target,
      reason = xiangmian.name,
      pattern = ".",
    }
    room:judge(judge)
    room:setPlayerMark(target, "xiangmian_suit", judge.card:getSuitString(true))
    room:setPlayerMark(target, "xiangmian_num", judge.card.number)
    room:setPlayerMark(target, "@xiangmian", string.format("%s%d", Fk:translate(target:getMark("xiangmian_suit")), target:getMark("xiangmian_num")))
  end,
})

xiangmian:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and target:getMark("xiangmian_num") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card:getSuitString(true) == target:getMark("xiangmian_suit") or target:getMark("xiangmian_num") == 1 then
      room:setPlayerMark(target, "xiangmian_num", 0)
      room:setPlayerMark(target, "@xiangmian", 0)
      room:loseHp(target, target.hp, xiangmian.name)
    else
      room:addPlayerMark(target, "xiangmian_num", -1)
      room:setPlayerMark(target, "@xiangmian", string.format("%s%d", Fk:translate(target:getMark("xiangmian_suit")), target:getMark("xiangmian_num")))
    end
  end,
})

return xiangmian
