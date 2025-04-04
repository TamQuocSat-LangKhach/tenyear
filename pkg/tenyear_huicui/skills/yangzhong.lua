local yangzhong = fk.CreateSkill {
  name = "yangzhong",
}

Fk:loadTranslationTable{
  ["yangzhong"] = "殃众",
  [":yangzhong"] = "当你造成或受到伤害后，伤害来源可以弃置两张牌，令受到伤害的角色失去1点体力。",

  ["#yangzhong-invoke"] = "殃众：你可以弃置两张牌，令 %dest 失去1点体力",

  ["$yangzhong1"] = "宦祸所起，池鱼所终！",
  ["$yangzhong2"] = "窃权利己，弄祸殃众！",
}

yangzhong:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yangzhong.name) and
      not data.to.dead and #player:getCardIds("he") > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = yangzhong.name,
      cancelable = true,
      prompt = "#yangzhong-invoke::"..data.to.id,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {data.to}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, yangzhong.name, player, player)
    if not data.to.dead then
      room:loseHp(data.to, 1, yangzhong.name)
    end
  end
})

yangzhong:addEffect(fk.Damaged, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yangzhong.name) and
      data.from and not data.from.dead and
      #data.from:getCardIds("he") > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(data.from, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = yangzhong.name,
      cancelable = true,
      prompt = "#yangzhong-invoke::"..player.id,
      skip = true,
    })
    if #cards > 0 then
      room:doIndicate(data.from, {player})
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, yangzhong.name, data.from, data.from)
    if not player.dead then
      room:loseHp(player, 1, yangzhong.name)
    end
  end
})

return yangzhong
