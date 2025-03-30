local qiongying = fk.CreateSkill {
  name = "qiongying",
}

Fk:loadTranslationTable{
  ["qiongying"] = "琼英",
  [":qiongying"] = "出牌阶段限一次，你可以移动场上一张牌，然后你弃置一张同花色的手牌（若没有需展示手牌）。",

  ["#qiongying"] = "琼英：你可以移动场上一张牌，然后弃置一张此花色的手牌",

  ["$qiongying1"] = "冰心碎玉壶，光转琼英灿。",
  ["$qiongying2"] = "玉心玲珑意，撷英倚西楼。",
}

qiongying:addEffect("active", {
  anim_type = "control",
  prompt = "#qiongying",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(qiongying.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (skill, player, to_select, selected)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return to_select:canMoveCardsInBoardTo(selected[1]) or selected[1]:canMoveCardsInBoardTo(to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local result = room:askToMoveCardInBoard(player, {
      target_one = effect.tos[1],
      target_two = effect.tos[2],
      skill_name = qiongying.name,
    })
    if player.dead or player:isKongcheng() or not result then return end
    if #room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = qiongying.name,
      cancelable = false,
      pattern = ".|.|"..result.card:getSuitString(),
    }) == 0 then
      player:showCards(player:getCardIds("h"))
    end
  end,
})

return qiongying
