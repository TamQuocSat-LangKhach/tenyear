local ty_ex__jiezhong = fk.CreateSkill {
  name = "ty_ex__jiezhong"
}

Fk:loadTranslationTable{
  ['ty_ex__jie__zhong'] = '竭忠',
  ['#ty_ex__jiezhong-invoke'] = '竭忠：是否发动“竭忠”摸%arg张牌？ ',
  [':ty_ex__jiezhong'] = '限定技，出牌阶段开始时，若你的手牌数小于体力上限，你可以将手牌补至体力上限（至多为5）。',
  ['$ty_ex__jiezhong1'] = '犯我疆土者，竭忠尽节以灭之。',
  ['$ty_ex__jiezhong2'] = '竭力尽能以立功于国，忠心不二。',
}

ty_ex__jie__zhong:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__jiezhong) and player.phase == Player.Play and
      math.min(player.maxHp, 5) > player:getHandcardNum() and player:usedSkillTimes(ty_ex__jiezhong.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local draw = math.min(player.maxHp, 5) - player:getHandcardNum()
    return player.room:askToSkillInvoke(player, {
      skill_name = ty_ex__jiezhong.name,
      prompt = "#ty_ex__jiezhong-invoke:::"..draw
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.min(player.maxHp, 5) - player:getHandcardNum()
    player:drawCards(n, ty_ex__jiezhong.name)
  end,
})

return ty_ex__jiezhong
