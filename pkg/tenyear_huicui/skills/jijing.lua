local jijing = fk.CreateSkill {
  name = "jijing"
}

Fk:loadTranslationTable{
  ['jijing'] = '吉境',
  ['jijing_active'] = '吉境',
  ['#jijing-discard'] = '吉境：你可以弃置任意张点数之和为%arg的牌，回复1点体力',
  [':jijing'] = '当你受到伤害后，你可以判定，然后你可以弃置任意张点数之和等于判定结果的牌，若如此做，你回复1点体力',
  ['$jijing1'] = '吉梦赐福，顺应天命。',
  ['$jijing2'] = '梦之指引，必为吉运。',
}

jijing:addEffect(fk.Damaged, {
  anim_type = "defensive",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = skill.name,
    }
    room:judge(judge)
    if player.dead or player:isNude() then return end
    local n = judge.card.number
    room:setPlayerMark(player, "jijing-tmp", n)
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "jijing_active",
      prompt = "#jijing-discard:::" .. n,
      cancelable = true,
    })
    room:setPlayerMark(player, "jijing-tmp", 0)
    if success then
      room:throwCard(dat.cards, skill.name, player, player)
      if not player.dead and player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = skill.name,
        }
      end
    end
  end,
})

return jijing
