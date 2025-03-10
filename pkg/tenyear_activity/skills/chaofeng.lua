local chaofeng = fk.CreateSkill {
  name = "chaofeng"
}

Fk:loadTranslationTable{
  ['chaofeng'] = '朝凤',
  ['#chaofeng-invoke'] = '朝凤：你可以弃置弃置一张手牌，摸一张牌',
  [':chaofeng'] = '每阶段限一次，当你于出牌阶段使用牌造成伤害时，你可以弃置一张手牌，然后摸一张牌。若弃置的牌与造成伤害的牌：颜色相同，则多摸一张牌；类型相同，则此伤害+1。',
  ['$chaofeng1'] = '鸾凤归巢，百鸟齐鸣。',
  ['$chaofeng2'] = '鸾凤之响，所闻皆朝。',
}

chaofeng:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chaofeng.name) and not player:isKongcheng() and data.card and player.phase == Player.Play and
      player:usedSkillTimes(chaofeng.name, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = chaofeng.name,
      cancelable = true,
      prompt = "#chaofeng-invoke",
      skip = true
    })
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self), chaofeng.name, player, player)
    local card = Fk:getCardById(event:getCostData(self)[1])
    local n = (data.card.color == card.color) and 2 or 1
    if not player.dead then
      player:drawCards(n, chaofeng.name)
    end
    if data.card.type == card.type then
      data.damage = data.damage + 1
    end
  end,
})

return chaofeng
