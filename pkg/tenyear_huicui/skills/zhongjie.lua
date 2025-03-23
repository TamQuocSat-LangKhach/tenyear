local zhongjie = fk.CreateSkill {
  name = "zhongjie"
}

Fk:loadTranslationTable{
  ['zhongjie'] = '忠节',
  ['#zhongjie-invoke'] = '你可以对%dest发动 忠节，令其回复1点体力并摸一张牌',
  [':zhongjie'] = '每轮限一次，当一名角色因失去体力而进入濒死状态时，你可以令其回复1点体力并摸一张牌。',
  ['$zhongjie1'] = '气节之士，不可不救。',
  ['$zhongjie2'] = '志士遭祸，应施以援手。',
}

zhongjie:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and player:usedSkillTimes(zhongjie.name, Player.HistoryRound) == 0 and
      not data.damage and not target.dead and target.hp < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zhongjie.name,
      prompt = "#zhongjie-invoke::" .. target.id
    }) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = zhongjie.name
    }
    if not target.dead then
      target:drawCards(1, zhongjie.name)
    end
  end,
})

return zhongjie
