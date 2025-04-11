local ty_ex__qiaoshi = fk.CreateSkill {
  name = "ty_ex__qiaoshi"
}

Fk:loadTranslationTable{
  ['ty_ex__qiaoshi'] = '樵拾',
  ['#ty_ex__qiaoshi-invoke'] = '樵拾：你可以与 %dest 各摸一张牌',
  [':ty_ex__qiaoshi'] = '其他角色的结束阶段，若其手牌数等于你，你可以与其各摸一张牌，若这两张牌颜色相同，你可以重复此流程。',
  ['$ty_ex__qiaoshi1'] = '暖风细雨，心有灵犀。',
  ['$ty_ex__qiaoshi2'] = '樵采城郭外，忽见郎君来。',
}

ty_ex__qiaoshi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(ty_ex__qiaoshi.name) and target.phase == Player.Finish and
      player:getHandcardNum() == target:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty_ex__qiaoshi.name,
      prompt = "#ty_ex__qiaoshi-invoke::"..target.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(player:drawCards(1, ty_ex__qiaoshi.name)[1])
    local card1 = Fk:getCardById(target:drawCards(1, ty_ex__qiaoshi.name)[1])
    if card.color == card1.color then
      for i = 1, 99, 1 do
        if room:askToSkillInvoke(player, {
          skill_name = ty_ex__qiaoshi.name,
          prompt = "#ty_ex__qiaoshi-invoke::"..target.id
        }) then
          card = Fk:getCardById(player:drawCards(1, ty_ex__qiaoshi.name)[1])
          card1 = Fk:getCardById(target:drawCards(1, ty_ex__qiaoshi.name)[1])
          if card.color ~= card1.color then
            return
          end
        else
          return
        end
      end
    end
  end,
})

return ty_ex__qiaoshi
