local jinjie = fk.CreateSkill {
  name = "jinjie",
}

Fk:loadTranslationTable{
  ["jinjie"] = "尽节",
  [":jinjie"] = "每轮限一次，一名角色进入濒死状态时，你可以令其摸0~3张牌，然后你可以弃置等量的牌令其回复1点体力。",

  ["#jinjie-invoke"] = "尽节：你可以令 %dest 摸0~3张牌，然后你可以弃等量牌令其回复体力",
  ["#jinjie-discard"] = "尽节：你可以弃置%arg张牌，令 %dest 回复1点体力",

  ["$jinjie1"] = "大汉养士百载，今乃奉节之时。",
  ["$jinjie2"] = "尔等皆忘天地君亲师乎？"
}

jinjie:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jinjie.name) and not target.dead and player:usedSkillTimes(jinjie.name, Player.HistoryRound) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"0", "1", "2", "3", "Cancel"},
      skill_name = jinjie.name,
      prompt = "#jinjie-invoke::"..target.id,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = tonumber(choice)})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = event:getCostData(self).choice
    if x > 0 then
      target:drawCards(x, jinjie.name)
      if player.dead or target.dead or not target:isWounded() or #player:getCardIds("he") < x or
        #room:askToDiscard(player, {
          min_num = x,
          max_num = x,
          include_equip = true,
          skill_name = jinjie.name,
          cancelable = true,
          prompt = "#jinjie-discard::"..target.id..":"..x,
        }) == 0 or
        target.dead or not target:isWounded() then return end
    end
    room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = jinjie.name,
    }
  end,
})

return jinjie
