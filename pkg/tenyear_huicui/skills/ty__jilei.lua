local ty__jilei = fk.CreateSkill {
  name = "ty__jilei"
}

Fk:loadTranslationTable{
  ['ty__jilei'] = '鸡肋',
  ['#ty__jilei-invoke'] = '鸡肋：是否令 %dest 不能使用、打出、弃置一种类别的牌直到其下回合开始？',
  ['@ty__jilei'] = '鸡肋',
  [':ty__jilei'] = '当你受到伤害后，你可以声明一种牌的类别，伤害来源不能使用、打出或弃置你声明的此类手牌直到其下回合开始。',
  ['$ty__jilei1'] = '今进退两难，势若鸡肋，魏王必当罢兵而还。',
  ['$ty__jilei2'] = '汝可令士卒收拾行装，魏王明日必定退兵。',
}

ty__jilei:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__jilei.name) and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {skill_name = ty__jilei.name, prompt = "#ty__jilei-invoke::" .. data.from.id}) then
      room:doIndicate(player.id, {data.from.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"basic", "trick", "equip"},
      skill_name = ty__jilei.name
    })
    local mark = data.from:getTableMark("@ty__jilei")
    if table.insertIfNeed(mark, choice .. "_char") then
      room:setPlayerMark(data.from, "@ty__jilei", mark)
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty__jilei") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty__jilei", 0)
  end,
})

local ty__jilei_prohibit = fk.CreateSkill {
  name = "#ty__jilei_prohibit"
}

ty__jilei_prohibit:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_discard = function(self, player, card)
    return table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char")
  end,
})

return ty__jilei
