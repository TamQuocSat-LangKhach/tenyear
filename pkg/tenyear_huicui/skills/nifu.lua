local nifu = fk.CreateSkill {
  name = "nifu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["nifu"] = "匿伏",
  [":nifu"] = "锁定技，每名角色的回合结束时，你将手牌摸或弃至三张。",

  ["$nifu1"] = "当为贤妻宜室，莫做妒妇祸家。",
  ["$nifu2"] = "将军且往沙场驰骋，妾身自有苟全之法。",
}

nifu:addEffect(fk.TurnEnd, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(nifu.name) and player:getHandcardNum() ~= 3
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
