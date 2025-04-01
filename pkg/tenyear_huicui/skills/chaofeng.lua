local chaofeng = fk.CreateSkill {
  name = "chaofeng",
}

Fk:loadTranslationTable{
  ["chaofeng"] = "朝凤",
  [":chaofeng"] = "每阶段限一次，当你于出牌阶段使用牌造成伤害时，你可以弃置一张手牌，然后摸一张牌。若弃置的牌与造成伤害的牌："..
  "颜色相同，则多摸一张牌；类型相同，则此伤害+1。",

  ["#chaofeng-invoke"] = "朝凤：你可以弃一张手牌，摸一张牌；若为%arg则多摸一张，若为%arg2则对 %dest伤害+1",

  ["$chaofeng1"] = "鸾凤归巢，百鸟齐鸣。",
  ["$chaofeng2"] = "鸾凤之响，所闻皆朝。",
}

chaofeng:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chaofeng.name) and
      data.card and player.phase == Player.Play and not player:isKongcheng() and
      player:usedSkillTimes(chaofeng.name, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = chaofeng.name,
      cancelable = true,
      prompt = "#chaofeng-invoke::"..data.to.id..":"..data.card:getColorString()..":"..data.card:getTypeString(),
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(event:getCostData(self).cards[1])
    room:throwCard(card, chaofeng.name, player, player)
    local n = (data.card.color == card.color) and 2 or 1
    if not player.dead then
      player:drawCards(n, chaofeng.name)
    end
    if data.card.type == card.type then
      data:changeDamage(1)
    end
  end,
})

return chaofeng
