local xieshou = fk.CreateSkill {
  name = "xieshou",
}

Fk:loadTranslationTable{
  ["xieshou"] = "协守",
  [":xieshou"] = "每回合限一次，一名角色受到伤害后，若你与其距离不大于2，你可以令你的手牌上限-1，然后其选择一项：1.回复1点体力；"..
  "2.复原武将牌并摸两张牌。",

  ["#xieshou-invoke"] = "协守：你可以手牌上限-1，令 %dest 选择回复体力，或复原武将牌并摸牌",
  ["xieshou_draw"] = "复原武将牌并摸两张牌",

  ["$xieshou1"] = "此城所能守者，在你我之协力。",
  ["$xieshou2"] = "据地利而拥人和，其天时在我。",
}

xieshou:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xieshou.name) and
      not target.dead and player:distanceTo(target) <= 2 and not target:isRemoved() and
      player:usedSkillTimes(xieshou.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = xieshou.name,
      prompt = "#xieshou-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
    local choices = {"xieshou_draw"}
    if target:isWounded() then
      table.insert(choices, 1, "recover")
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = xieshou.name,
    })
    if choice == "recover" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = xieshou.name,
      }
    else
      target:reset()
      if not target.dead then
        target:drawCards(2, xieshou.name)
      end
    end
  end,
})

return xieshou
