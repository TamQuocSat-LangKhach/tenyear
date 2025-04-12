local fuhun = fk.CreateSkill {
  name = "ty_ex__fuhun",
}

Fk:loadTranslationTable{
  ["ty_ex__fuhun"] = "父魂",
  [":ty_ex__fuhun"] = "你可以将两张手牌当【杀】使用或打出；当你于出牌阶段内以此法造成伤害后，本回合获得〖武圣〗和〖咆哮〗。",

  ["#ty_ex__fuhun"] = "父魂：将两张手牌当【杀】使用或打出",

  ["$ty_ex__fuhun1"] = "擎刀执矛，以效先父之法。",
  ["$ty_ex__fuhun2"] = "苍天在上，儿必不堕父亲威名！",
}

fuhun:addEffect("viewas", {
  prompt = "#ty_ex__fuhun",
  pattern = "slash",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2 and table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = fuhun.name
    c:addSubcards(cards)
    return c
  end,
})

fuhun:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuhun.name) and
      data.card and table.contains(data.card.skillNames, fuhun.name) and
      player.phase == Player.Play
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local skills = {}
    for _, skill_name in ipairs({"ex__wusheng", "ex__paoxiao"}) do
      if not player:hasSkill(skill_name, true) then
        table.insert(skills, skill_name)
      end
    end
    if #skills > 0 then
      room:handleAddLoseSkills(player, table.concat(skills, "|"))
      room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
        room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"))
      end)
    end
  end,
})

return fuhun
