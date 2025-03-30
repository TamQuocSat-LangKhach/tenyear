local zhengding = fk.CreateSkill {
  name = "zhengding",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhengding"] = "正订",
  [":zhengding"] = "锁定技，你的回合外，当你使用或打出牌响应其他角色使用的牌时，若你使用或打出的牌与其使用的牌颜色相同，你加1点体力上限，"..
  "回复1点体力。",

  ["$zhengding1"] = "行义修正，改故用新。",
  ["$zhengding2"] = "义约谬误，有所正订。",
}

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skill_name = zhengding.name,
      }
    end
  end,
}

zhengding:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengding.name) and data.responseToEvent and
      player.room.current ~= player and data.toCard and data.toCard.color == data.card.color and
      data.responseToEvent.from ~= player
  end,
  on_use = spec.on_use,
})

zhengding:addEffect(fk.CardResponding, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengding.name) and data.responseToEvent and
      player.room.current ~= player and data.responseToEvent.card and data.responseToEvent.card.color == data.card.color and
      data.responseToEvent.from ~= player
  end,
  on_use = spec.on_use,
})

return zhengding
