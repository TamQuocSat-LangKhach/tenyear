local zhengding = fk.CreateSkill {
  name = "zhengding"
}

Fk:loadTranslationTable{
  ['zhengding'] = '正订',
  [':zhengding'] = '锁定技，你的回合外，当你使用或打出牌响应其他角色使用的牌时，若你使用或打出的牌与其使用的牌颜色相同，你加1点体力上限，回复1点体力。',
  ['$zhengding1'] = '行义修正，改故用新。',
  ['$zhengding2'] = '义约谬误，有所正订。',
}

zhengding:addEffect(fk.CardUsing, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhengding.name) and target == player and player.phase == Player.NotActive and data.responseToEvent then
      if (event == fk.CardUsing and data.toCard and data.toCard.color == data.card.color) or
        (event == fk.CardResponding and data.responseToEvent.card and data.responseToEvent.card.color == data.card.color) then
        return data.responseToEvent.from ~= player.id
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if not player.dead then
      room:recover({ who = player, num = 1, skill_name = zhengding.name })
    end
  end,
})

zhengding:addEffect(fk.CardResponding, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhengding.name) and target == player and player.phase == Player.NotActive and data.responseToEvent then
      if (event == fk.CardUsing and data.toCard and data.toCard.color == data.card.color) or
        (event == fk.CardResponding and data.responseToEvent.card and data.responseToEvent.card.color == data.card.color) then
        return data.responseToEvent.from ~= player.id
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if not player.dead then
      room:recover({ who = player, num = 1, skill_name = zhengding.name })
    end
  end,
})

return zhengding
