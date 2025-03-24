local jinglun = fk.CreateSkill {
  name = "jinglun",
}

Fk:loadTranslationTable{
  ["jinglun"] = "经纶",
  [":jinglun"] = "每回合限一次，你距离1以内的角色造成伤害后，你可以令其摸X张牌，并对其发动〖忠言〗（X为其装备区牌数）。",

  ["#jinglun-invoke"] = "经纶：是否令 %dest 摸牌并对其发动“忠言”？",

  ["$jinglun1"] = "千夫诺诺，不如一士谔谔。",
  ["$jinglun2"] = "忠言如药，苦口而利身。",
}

jinglun:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jinglun.name) and
      target and not target.dead and player:distanceTo(target) <= 1 and
      player:usedSkillTimes(jinglun.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = jinglun.name,
      prompt = "#jinglun-invoke::" .. target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #target:getCardIds("e")
    if n > 0 then
      target:drawCards(n, jinglun.name)
    end
    if target.dead then return end
    local skill = Fk.skills["zhongyanz"]
    skill:onUse(room, {
      from = player,
      tos = {target},
    })
  end,
})

return jinglun
