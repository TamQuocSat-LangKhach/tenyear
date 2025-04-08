local weilie = fk.CreateSkill {
  name = "weilie",
}

Fk:loadTranslationTable{
  ["weilie"] = "炜烈",
  [":weilie"] = "每局游戏限一次，出牌阶段，你可以弃置一张牌令一名角色回复1点体力，然后若其已受伤，其摸一张牌。"..
  "你每次发动〖浮萍〗记录牌名时，此技能可发动次数+1。",

  ["#weilie"] = "炜烈：弃一张牌，令一名角色回复1点体力",

  ["$weilie1"] = "好学尚贞烈，义形必沾巾。",
  ["$weilie2"] = "贞烈过男子，何处弱须眉？"
}

weilie:addEffect("active", {
  anim_type = "support",
  times = function(self, player)
    return 1 + player:usedSkillTimes("#fuping_1_trig", Player.HistoryGame) - player:usedSkillTimes(weilie.name, Player.HistoryGame)
  end,
  prompt = "#weilie",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(weilie.name, Player.HistoryGame) <= player:usedSkillTimes("#fuping_1_trig", Player.HistoryGame)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select:isWounded()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, weilie.name, player, player)
    if target:isWounded() and not target.dead then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = weilie.name
      }
    end
    if target:isWounded() and not target.dead then
      target:drawCards(1, weilie.name)
    end
  end,
})

return weilie
