local yangzhong = fk.CreateSkill {
  name = "yangzhong"
}

Fk:loadTranslationTable{
  ['yangzhong'] = '殃众',
  ['#yangzhong-invoke'] = '殃众：你可以弃置两张牌，令 %dest 失去1点体力',
  [':yangzhong'] = '当你造成或受到伤害后，伤害来源可以弃置两张牌，令受到伤害的角色失去1点体力。',
  ['$yangzhong1'] = '窃权利己，弄祸殃众！',
  ['$yangzhong2'] = '宦祸所起，池鱼所终！'
}

yangzhong:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yangzhong.name) and data.from and not data.from.dead and not data.to.dead and
      #data.from:getCardIds{Player.Hand, Player.Equip} > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(data.from, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = yangzhong.name,
      cancelable = true,
      prompt = "#yangzhong-invoke::"..data.to.id
    })
    if #cards > 0 then
      event:setCostData(skill, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(skill), yangzhong.name, data.from, data.from)
    if not data.to.dead then
      room:loseHp(data.to, 1, yangzhong.name)
    end
  end
})

yangzhong:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yangzhong.name) and data.from and not data.from.dead and not data.to.dead and
      #data.from:getCardIds{Player.Hand, Player.Equip} > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(data.from, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = yangzhong.name,
      cancelable = true,
      prompt = "#yangzhong-invoke::"..data.to.id
    })
    if #cards > 0 then
      event:setCostData(skill, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(skill), yangzhong.name, data.from, data.from)
    if not data.to.dead then
      room:loseHp(data.to, 1, yangzhong.name)
    end
  end
})

return yangzhong
