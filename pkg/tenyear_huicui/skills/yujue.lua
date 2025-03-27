local yujue = fk.CreateSkill {
  name = "yujue",
}

Fk:loadTranslationTable{
  ["yujue"] = "鬻爵",
  [":yujue"] = "出牌阶段限一次，你可以废除一个装备栏并选择一名有手牌的其他角色，令其交给你一张手牌，其获得技能〖执笏〗直到你下个回合开始。",

  ["#yujue"] = "鬻爵：废除一个装备栏，令一名角色交给你一张手牌，其获得“执笏”直到你下回合开始",
  ["#yujue-give"] = "鬻爵：请交给 %src 一张手牌",

  ["$yujue1"] = "国库空虚，鬻爵可解。",
  ["$yujue2"] = "卖官鬻爵，酣歌畅饮。",
}

yujue:addEffect("active", {
  anim_type = "support",
  prompt = "#yujue",
  interaction = function(self, player)
    return UI.ComboBox { choices = player:getAvailableEquipSlots() }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(yujue.name, Player.HistoryPhase) < 1 and #player:getAvailableEquipSlots() > 0
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:abortPlayerArea(player, self.interaction.data)
    if not player.dead and not target.dead and not target:isKongcheng() then
      local card = room:askToCards(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        prompt = "#yujue-give:"..player.id,
        skill_name = yujue.name,
        cancelable = false,
      })
      room:obtainCard(player, card, false, fk.ReasonGive, target, yujue.name)
    end
    if not target:hasSkill("zhihu",true) then
      room:addTableMarkIfNeed(player, "yujue_skill", target.id)
      room:handleAddLoseSkills(target, "zhihu")
    end
  end,
})

yujue:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("yujue_skill") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("yujue_skill")
    room:setPlayerMark(player, "yujue_skill", 0)
    for _, id in ipairs(mark) do
      local p = room:getPlayerById(id)
      room:handleAddLoseSkills(p, "-zhihu")
    end
  end,
})

return yujue
