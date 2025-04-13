local qiaoshi = fk.CreateSkill {
  name = "ty_ex__qiaoshi",
}

Fk:loadTranslationTable{
  ["ty_ex__qiaoshi"] = "樵拾",
  [":ty_ex__qiaoshi"] = "其他角色的结束阶段，若其手牌数等于你，你可以与其各摸一张牌，若这两张牌花色相同，你可以重复此流程。",

  ["#ty_ex__qiaoshi-invoke"] = "樵拾：你可以与 %dest 各摸一张牌",

  ["$ty_ex__qiaoshi1"] = "暖风细雨，心有灵犀。",
  ["$ty_ex__qiaoshi2"] = "樵采城郭外，忽见郎君来。",
}

qiaoshi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(qiaoshi.name) and target.phase == Player.Finish and
      player:getHandcardNum() == target:getHandcardNum() and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = qiaoshi.name,
      prompt = "#ty_ex__qiaoshi-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    while true do
      local card1, card2
      local cards = player:drawCards(1, qiaoshi.name)
      if #cards == 1 then
        card1 = Fk:getCardById(cards[1])
      end
      if not target.dead then
        cards = target:drawCards(1, qiaoshi.name)
        if #cards == 1 then
          card2 = Fk:getCardById(cards[1])
        end
      end
      if not (card1 and card2 and card1:compareSuitWith(card2) and
        room:askToSkillInvoke(player, {
          skill_name = qiaoshi.name,
          prompt = "#ty_ex__qiaoshi-invoke::"..target.id,
        })) then
        break
      end
    end
  end,
})

return qiaoshi
