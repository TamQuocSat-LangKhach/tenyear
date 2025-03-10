local ty_ex__longyin = fk.CreateSkill {
  name = "ty_ex__longyin"
}

Fk:loadTranslationTable{
  ['ty_ex__longyin'] = '龙吟',
  ['#ty_ex__longyin-invoke'] = '龙吟：你可以弃置一张牌令 %dest 的【杀】不计入次数限制',
  ['ty_ex__jiezhong'] = '竭忠',
  [':ty_ex__longyin'] = '每当一名角色在其出牌阶段使用【杀】时，你可以弃置一张牌令此【杀】不计入出牌阶段使用次数，若此【杀】为红色，你摸一张牌。若你以此法弃置的牌点数与此【杀】相同，你重置〖竭忠〗。',
  ['$ty_ex__longyin1'] = '风云将起，龙虎齐鸣！',
  ['$ty_ex__longyin2'] = '武圣龙威，破敌无惧！'
}

ty_ex__longyin:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ty_ex__longyin.name) and target.phase == Player.Play and data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ty_ex__longyin.name,
      cancelable = true,
      prompt = "#ty_ex__longyin-invoke::" .. target.id
    })
    if #cards > 0 then
      event:setCostData(self, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(event:getCostData(self), ty_ex__longyin.name, player, player)
    if not data.extraUse then
      data.extraUse = true
      target:addCardUseHistory(data.card.trueName, -1)
    end
    if data.card.color == Card.Red and not player.dead then
      player:drawCards(1, ty_ex__longyin.name)
    end
    if data.card.number == Fk:getCardById(event:getCostData(self)[1]).number and player:usedSkillTimes("ty_ex__jiezhong", Player.HistoryGame) > 0 then
      player:setSkillUseHistory("ty_ex__jiezhong", 0, Player.HistoryGame)
    end
  end,
})

return ty_ex__longyin
