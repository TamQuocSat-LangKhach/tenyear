local wangxi = fk.CreateSkill {
  name = "ty__wangxi",
}

Fk:loadTranslationTable{
  ["ty__wangxi"] = "忘隙",
  [":ty__wangxi"] = "当你对其他角色造成1点伤害后，或当你受到其他角色造成的1点伤害后，若其存活，你可以摸两张牌，然后将一张牌交给该角色。",

  ["#ty__wangxi-invoke"] = "忘隙：是否对 %dest 发动“忘隙”，摸两张牌并交给其一张牌",
  ["#ty__wangxi-give"] = "忘隙：交给 %dest 一张牌",

  ["$ty__wangxi1"] = "小隙沉舟，同心方可戮力。",
  ["$ty__wangxi2"] = "为天下苍生，自当化解私怨。",
}

wangxi:addEffect(fk.Damage, {
  anim_type = "drawcard",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wangxi.name) and
      data.to ~= player and not data.to.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = wangxi.name,
      prompt = "#ty__wangxi-invoke::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, wangxi.name)
    if player.dead or player:isNude() or data.to.dead then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = wangxi.name,
      prompt = "#ty__wangxi-give::"..data.to.id,
    })
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, data.to, fk.ReasonGive, wangxi.name, nil, false, player)
    end
  end,
})

wangxi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wangxi.name) and
      data.from and data.from ~= player and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = wangxi.name,
      prompt = "#ty__wangxi-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, wangxi.name)
    if player.dead or player:isNude() or data.from.dead then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = wangxi.name,
      prompt = "#ty__wangxi-give::"..data.from.id,
    })
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, data.from, fk.ReasonGive, wangxi.name, nil, false, player)
    end
  end,
})

return wangxi
