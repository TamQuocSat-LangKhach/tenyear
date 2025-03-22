local shiming = fk.CreateSkill {
  name = "shiming",
}

Fk:loadTranslationTable{
  ["shiming"] = "识命",
  [":shiming"] = "每轮限一次，一名角色的摸牌阶段开始时，你可以观看牌堆顶三张牌并调整顺序，且可以将其中一张置于牌堆底，若如此做，"..
  "当前回合角色可以放弃摸牌，改为对自己造成1点伤害，然后从牌堆底摸三张牌。",

  ["#shiming-invoke"] = "识命：%dest 的摸牌阶段，你可以先观看牌堆顶三张牌，将其中一张置于牌堆底",
  ["#shiming-damage"] = "识命：你可以对自己造成1点伤害，放弃摸牌，改为从牌堆底摸三张牌",

  ["$shiming1"] = "今天命在北，我等已尽人事。",
  ["$shiming2"] = "益州国疲民敝，非人力可续之。",
}

shiming:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shiming.name) and target.phase == Player.Draw and
      player:usedSkillTimes(shiming.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = shiming.name,
      prompt = "#shiming-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3)
    room:askToGuanxing(player, {
      cards = ids,
      bottom_limit = {0, 1},
      skill_name = shiming.name
    })
    if room:askToSkillInvoke(target, {
      skill_name = shiming.name,
      prompt = "#shiming-damage"
    }) then
      data.phase_end = true
      room:damage{
        from = target,
        to = target,
        damage = 1,
        skillName = shiming.name,
      }
      if not target.dead then
        target:drawCards(3, shiming.name, "bottom")
      end
    end
  end,
})

return shiming
