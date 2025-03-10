local cunwei = fk.CreateSkill {
  name = "cunwei"
}

Fk:loadTranslationTable{
  ['cunwei'] = '存畏',
  [':cunwei'] = '锁定技，当你成为锦囊牌的目标后，若你：是此牌唯一目标，你摸一张牌；不是此牌唯一目标，你弃置一张牌。',
  ['$cunwei1'] = '陛下专宠，诸侯畏惧。',
  ['$cunwei2'] = '君侧之人，众所畏惧。',
}

cunwei:addEffect(fk.TargetConfirmed, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(cunwei.name) and data.card.type == Card.TypeTrick then
      return U.isOnlyTarget(player, data, fk.TargetConfirmed) or not player:isNude()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(cunwei.name)
    if U.isOnlyTarget(player, data, fk.TargetConfirmed) then
      room:notifySkillInvoked(player, cunwei.name, "drawcard")
      player:drawCards(1, cunwei.name)
    else
      room:notifySkillInvoked(player, cunwei.name, "negative")
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = cunwei.name,
        cancelable = false,
      })
    end
  end,
})

return cunwei
