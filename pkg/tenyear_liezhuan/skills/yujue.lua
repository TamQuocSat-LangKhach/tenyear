local yujue = fk.CreateSkill {
  name = "yujue"
}

Fk:loadTranslationTable{
  ['yujue'] = '鬻爵',
  ['#yujue-give'] = '鬻爵：请交给 %src 一张手牌',
  ['zhihu'] = '执笏',
  [':yujue'] = '出牌阶段限一次，你可以废除你的一个装备栏，并选择一名有手牌的其他角色，令其交给你一张手牌，然后其获得技能“执笏”直到你的下个回合开始。',
  ['$yujue1'] = '国库空虚，鬻爵可解。',
  ['$yujue2'] = '卖官鬻爵，酣歌畅饮。',
}

yujue:addEffect('active', {
  anim_type = "support",
  interaction = function(self, player)
    local slots = {}
    for _, slot in ipairs({"WeaponSlot","ArmorSlot","OffensiveRideSlot","DefensiveRideSlot","TreasureSlot"}) do
      local subtype = Util.convertSubtypeAndEquipSlot(slot)
      if #player:getAvailableEquipSlots(subtype) > 0 then
        table.insert(slots, slot)
      end
    end
    if #slots == 0 then return end
    return UI.ComboBox {choices = slots}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(yujue.name, Player.HistoryPhase) < 1 and #player:getAvailableEquipSlots() > 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:abortPlayerArea(player, skill.interaction.data)
    if not player.dead and not to:isKongcheng() then
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        pattern = ".",
        prompt = "#yujue-give:"..player.id,
        skill_name = yujue.name,
      })
      if #card > 0 then
        room:obtainCard(player, card[1], false, fk.ReasonGive)
      end
    end
    if not to:hasSkill("zhihu",true) then
      room:addTableMarkIfNeed(player, "yujue_skill", to.id)
      room:handleAddLoseSkills(to, "zhihu", nil)
    end
  end,
})

yujue:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player == target and type(player:getMark("yujue_skill")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("yujue_skill")
    room:setPlayerMark(player, "yujue_skill", 0)
    for _, pid in ipairs(mark) do
      local p = room:getPlayerById(pid)
      room:handleAddLoseSkills(p, "-zhihu", nil, false)
    end
  end,
})

return yujue
