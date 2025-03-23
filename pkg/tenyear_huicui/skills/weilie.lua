local weilie = fk.CreateSkill {
  name = "weilie"
}

Fk:loadTranslationTable{
  ['weilie'] = '炜烈',
  ['#weilie-active'] = '炜烈：弃一张牌令一名已受伤的角色回复体力（剩余 %arg 次）',
  ['@$fuping'] = '浮萍',
  [':weilie'] = '每局游戏限一次，出牌阶段，你可以弃置一张牌令一名角色回复1点体力，然后若其已受伤，则其摸一张牌。你每次发动〖浮萍〗记录牌名时，此技能可发动次数+1。',
  ['$weilie1'] = '好学尚贞烈，义形必沾巾。',
  ['$weilie2'] = '贞烈过男子，何处弱须眉？'
}

weilie:addEffect('active', {
  anim_type = "support",
  prompt = function (self, player)
    return "#weilie-active:::" .. tostring(#player:getTableMark("@$fuping") - player:usedSkillTimes(weilie.name, Player.HistoryGame) + 1)
  end,
  times = function(self, player)
    return 1 + #player:getTableMark("@$fuping") - player:usedSkillTimes(weilie.name, Player.HistoryGame)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(weilie.name, Player.HistoryGame) <= #player:getTableMark("@$fuping")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):isWounded()
  end,
  card_num = 1,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, weilie.name, from, from)
    local target = room:getPlayerById(effect.tos[1])
    if not target.dead then
      room:recover({
        who = target,
        num = 1,
        recoverBy = from,
        skillName = weilie.name
      })
    end
    if not target.dead and target:isWounded() then
      room:drawCards(target, 1, weilie.name)
    end
  end,
})

return weilie
