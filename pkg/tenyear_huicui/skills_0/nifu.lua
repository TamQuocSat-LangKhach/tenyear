local nifu = fk.CreateSkill {
  name = "nifu"
}

Fk:loadTranslationTable{
  ['nifu'] = '匿伏',
  [':nifu'] = '锁定技，一名角色的结束阶段，你将手牌摸至或弃置至三张。',
  ['$nifu1'] = '当为贤妻宜室，莫做妒妇祸家。',
  ['$nifu2'] = '将军且往沙场驰骋，妾身自有苟全之法。',
}

nifu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and target.phase == Player.Finish and player:getHandcardNum() ~= 3
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(nifu.name)
    local room = player.room
    local n = player:getHandcardNum() - 3
    if n < 0 then
      room:notifySkillInvoked(player, nifu.name, "drawcard")
      player:drawCards(-n, nifu.name)
    else
      room:notifySkillInvoked(player, nifu.name, "negative")
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = nifu.name,
        cancelable = false,
      })
    end
  end,
})

return nifu
