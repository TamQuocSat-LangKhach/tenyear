local ty_ex__fuhun = fk.CreateSkill {
  name = "ty_ex__fuhun"
}

Fk:loadTranslationTable{
  ['ty_ex__fuhun'] = '父魂',
  [':ty_ex__fuhun'] = '你可以将两张手牌当【杀】使用或打出；当你于出牌阶段内以此法造成伤害后，本回合获得〖武圣〗和〖咆哮〗。',
  ['$ty_ex__fuhun1'] = '擎刀执矛，以效先父之法。',
  ['$ty_ex__fuhun2'] = '苍天在上，儿必不堕父亲威名！',
}

-- ViewAsSkill effect
ty_ex__fuhun:addEffect('viewas', {
  name = "ty_ex__fuhun",
  pattern = "slash",
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and table.contains(player:getHandlyIds(true), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = ty_ex__fuhun.name
    c:addSubcards(cards)
    return c
  end,
})

-- TriggerSkill effect
ty_ex__fuhun:addEffect(fk.Damage, {
  name = "#ty_ex__fuhun_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and table.contains(data.card.skillNames, "ty_ex__fuhun") and player.phase == Player.Play
      and not (player:hasSkill("ex__wusheng", true) and player:hasSkill("ex__paoxiao", true))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = table.filter({"ex__wusheng","ex__paoxiao"}, function(s) return not player:hasSkill(s,true) end)
    room:handleAddLoseSkills(player, table.concat(skills, "|"))
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
    end)
  end,
})

return ty_ex__fuhun
