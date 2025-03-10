local funing = fk.CreateSkill {
  name = "funing"
}

Fk:loadTranslationTable{
  ['funing'] = '抚宁',
  ['#funing-invoke'] = '抚宁：你可以摸两张牌，然后弃置%arg张牌',
  [':funing'] = '当你使用一张牌时，你可以摸两张牌然后弃置X张牌（X为此技能本回合发动次数）。',
  ['$funing1'] = '为国效力，不可逞一时之气。',
  ['$funing2'] = '诸将和睦，方为国家之幸。',
}

funing:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {skill_name = skill.name, prompt = "#funing-invoke:::"..player:usedSkillTimes(skill.name, Player.HistoryTurn) + 1})
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, funing.name)
    local n = player:usedSkillTimes(skill.name, Player.HistoryTurn)
    player.room:askToDiscard(player, {min_num = n, max_num = n, include_equip = true, skill_name = skill.name, cancelable = false})
  end,
})

return funing
