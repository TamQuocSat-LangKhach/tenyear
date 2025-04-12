local longyin = fk.CreateSkill {
  name = "ty_ex__longyin",
}

Fk:loadTranslationTable{
  ["ty_ex__longyin"] = "龙吟",
  [":ty_ex__longyin"] = "当一名角色于其出牌阶段使用【杀】时，你可以弃置一张牌令此【杀】不计入出牌阶段使用次数。若此【杀】为红色，"..
  "你摸一张牌；若你弃置的牌点数与此【杀】相同，你重置〖竭忠〗。",

  ["#ty_ex__longyin-invoke"] = "龙吟：你可以弃置一张牌，令 %dest 的【杀】不计入次数限制",

  ["$ty_ex__longyin1"] = "风云将起，龙虎齐鸣！",
  ["$ty_ex__longyin2"] = "武圣龙威，破敌无惧！"
}

longyin:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(longyin.name) and target.phase == Player.Play and
      data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = longyin.name,
      cancelable = true,
      prompt = "#ty_ex__longyin-invoke::" .. target.id,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cards = event:getCostData(self).cards
    player.room:throwCard(cards, longyin.name, player, player)
    if not data.extraUse then
      target:addCardUseHistory(data.card.trueName, -1)
      data.extraUse = true
    end
    if data.card.color == Card.Red and not player.dead then
      player:drawCards(1, longyin.name)
    end
    if data.card.number == Fk:getCardById(cards[1]).number then
      player:setSkillUseHistory("ty_ex__jiezhong", 0, Player.HistoryGame)
    end
  end,
})

return longyin
