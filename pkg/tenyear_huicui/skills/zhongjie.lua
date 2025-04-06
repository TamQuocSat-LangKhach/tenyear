local zhongjie = fk.CreateSkill {
  name = "zhongjie",
}

Fk:loadTranslationTable{
  ["zhongjie"] = "忠节",
  [":zhongjie"] = "每轮限一次，当一名角色因失去体力而进入濒死状态时，你可以令其回复1点体力并摸一张牌。",

  ["#zhongjie-invoke"] = "忠节：你可以令 %dest 回复1点体力并摸一张牌",

  ["$zhongjie1"] = "气节之士，不可不救。",
  ["$zhongjie2"] = "志士遭祸，应施以援手。",
}

zhongjie:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhongjie.name) and
      player:usedSkillTimes(zhongjie.name, Player.HistoryRound) == 0 and
      not data.damage and not target.dead and target.dying then
      local losehp_event = player.room.logic:getCurrentEvent():findParent(GameEvent.LoseHp)
      return losehp_event and losehp_event.data.who == target
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zhongjie.name,
      prompt = "#zhongjie-invoke::" .. target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = zhongjie.name,
    }
    if not target.dead then
      target:drawCards(1, zhongjie.name)
    end
  end,
})

return zhongjie
