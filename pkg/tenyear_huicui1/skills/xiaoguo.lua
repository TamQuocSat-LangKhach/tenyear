local xiaoguo = fk.CreateSkill {
  name = "ty__xiaoguo"
}

Fk:loadTranslationTable{
  ['ty__xiaoguo'] = '骁果',
  ['#ty__xiaoguo-invoke'] = '骁果：你可以弃置一张手牌，%dest 需弃置一张装备牌并令你摸一张牌，否则你对其造成1点伤害',
  ['#ty__xiaoguo-discard'] = '骁果：你需弃置一张装备牌并令 %src 摸一张牌，否则其对你造成1点伤害',
  [':ty__xiaoguo'] = '其他角色的结束阶段，你可以弃置一张手牌，然后其选择一项：1.弃置一张装备牌，然后你摸一张牌；2.你对其造成1点伤害。',
  ['$ty__xia__guo1'] = '三军听我号令，不得撤退！',
  ['$ty__xia__guo2'] = '看我先登城头，立下首功！',
}

xiaoguo:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xiaoguo.name) and target.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = xiaoguo.name,
      cancelable = true,
      prompt = "#ty__xiaoguo-invoke::" .. target.id
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target.id}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    room:throwCard(cost_data.cards, xiaoguo.name, player, player)
    if target.dead then return end
    if #room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      pattern = ".|.|.|.|.|equip",
      skill_name = xiaoguo.name,
      cancelable = true,
      prompt = "#ty__xiaoguo-discard:" .. player.id
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
