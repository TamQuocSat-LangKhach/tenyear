local zhente = fk.CreateSkill {
  name = "zhente"
}

Fk:loadTranslationTable{
  ['zhente'] = '贞特',
  ['#zhente-invoke'] = '是否使用贞特，令【%arg】对你无效或不能再使用%arg2牌',
  ['zhente_negate'] = '令【%arg】对%dest无效',
  ['zhente_colorlimit'] = '本回合不能再使用%arg牌',
  ['@zhente-turn'] = '贞特',
  [':zhente'] = '每名角色的回合限一次，当你成为其他角色使用基本牌或普通锦囊牌的目标后，你可令其选择一项：1.本回合不能再使用此颜色的牌；2.此牌对你无效。',
  ['$zhente1'] = '抗声昭节，义形于色。',
  ['$zhente2'] = '少履贞特之行，三从四德。',
}

zhente:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(skill.name) and player:usedSkillTimes(zhente.name) == 0 and data.from ~= player.id then
      return data.card:isCommonTrick() or data.card.type == Card.TypeBasic
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = zhente.name,
      prompt = "#zhente-invoke:".. data.from .. "::" .. data.card:toLogString() .. ":" .. data.card:getColorString(),
    }) then
      player.room:doIndicate(player.id, {data.from})
      event:setCostData(skill, true)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.from)
    local color = data.card:getColorString()
    local choice = room:askToChoice(to, {
      choices = {"zhente_negate::" .. tostring(player.id) .. ":" .. data.card.name,
        "zhente_colorlimit:::" .. color},
      skill_name = zhente.name
    })
    if choice:startsWith("zhente_negate") then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    else
      room:addTableMark(to, "@zhente-turn", color)
    end
  end,
})

local zhente_prohibit = fk.CreateSkill {
  name = "#zhente_prohibit"
}

zhente_prohibit:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    local mark = player:getMark("@zhente-turn")
    return type(mark) == "table" and table.contains(mark, card:getColorString())
  end,
})

return zhente, zhente_prohibit
