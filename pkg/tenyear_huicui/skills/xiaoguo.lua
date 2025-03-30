local xiaoguo = fk.CreateSkill {
  name = "ty__xiaoguo",
}

Fk:loadTranslationTable {
  ["ty__xiaoguo"] = "骁果",
  [":ty__xiaoguo"] = "其他角色的结束阶段，你可以弃置一张手牌。若如此做，该角色需弃置一张装备牌并令你摸一张牌，否则受到你对其造成的1点伤害。",

  ["#ty__xiaoguo-invoke"] = "骁果：弃一张手牌，%dest 需弃置一张装备牌并令你摸一张牌，否则你对其造成1点伤害",
  ["#ty__xiaoguo-discard"] = "骁果：你需弃置一张装备牌并令 %src 摸一张牌，否则其对你造成1点伤害",

  ["$ty__xiaoguo1"] = "三军听我号令，不得撤退！",
  ["$ty__xiaoguo2"] = "看我先登城头，立下首功！",
}

xiaoguo:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xiaoguo.name) and target.phase == Player.Finish and not target.dead and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = xiaoguo.name,
      prompt = "#ty__xiaoguo-invoke::"..target.id,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, xiaoguo.name, player, player)
    if target.dead then return false end
    if #room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = xiaoguo.name,
      pattern = ".|.|.|.|.|equip",
      prompt = "#ty__xiaoguo-discard:"..player.id,
      cancelable = true,
    }) > 0 then
      if not player.dead then
        player:drawCards(1, xiaoguo.name)
      end
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = xiaoguo.name,
      }
    end
  end,
})

return xiaoguo
