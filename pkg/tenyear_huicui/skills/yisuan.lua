local yisuan = fk.CreateSkill {
  name = "yisuan",
}

Fk:loadTranslationTable{
  ["yisuan"] = "亦算",
  [":yisuan"] = "每阶段限一次，当你于出牌阶段内使用普通锦囊牌结算后，你可以减1点体力上限，从弃牌堆获得之。",

  ["#yisuan-invoke"] = "亦算：是否减1点体力上限，获得%arg？",

  ["$yisuan1"] = "吾亦能善算谋划。",
  ["$yisuan2"] = "算计人心，我也可略施一二。",
}

yisuan:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yisuan.name) and player.phase == Player.Play and
      data.card:isCommonTrick() and player.room:getCardArea(data.card) == Card.Processing and
      player:usedSkillTimes(yisuan.name, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yisuan.name,
      prompt = "#yisuan-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    room:obtainCard(player, data.card, true, fk.ReasonJustMove, player, yisuan.name)
  end,
})

return yisuan
