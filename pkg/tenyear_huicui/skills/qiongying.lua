local qiongying = fk.CreateSkill {
  name = "qiongying"
}

Fk:loadTranslationTable{
  ['qiongying'] = '琼英',
  ['#qiongying'] = '琼英：你可以移动场上一张牌，然后弃置一张此花色的手牌',
  [':qiongying'] = '出牌阶段限一次，你可以移动场上一张牌，然后你弃置一张同花色的手牌（若没有需展示手牌）。',
  ['$qiongying1'] = '冰心碎玉壶，光转琼英灿。',
  ['$qiongying2'] = '玉心玲珑意，撷英倚西楼。',
}

qiongying:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  prompt = "#qiongying",
  can_use = function(self, player)
    return player:usedSkillTimes(qiongying.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (skill, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:currentRoom():getPlayerById(selected[1]):canMoveCardsInBoardTo(target, nil)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local result = room:askToMoveCardInBoard(player, {
      target_one = room:getPlayerById(effect.tos[1]),
      target_two = room:getPlayerById(effect.tos[2]),
      skill_name = qiongying.name
    })
    if player.dead or player:isKongcheng() then return end
    local suit = result.card:getSuitString()
    local discards = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = qiongying.name,
      cancelable = false,
      pattern = ".|.|" .. suit
    })
    if #discards == 0 then
      player:showCards(player:getCardIds("h"))
    end
  end,
})

return qiongying
