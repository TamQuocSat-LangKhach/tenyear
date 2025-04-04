local jianguo = fk.CreateSkill {
  name = "jianguo",
}

Fk:loadTranslationTable{
  ["jianguo"] = "谏国",
  [":jianguo"] = "出牌阶段各限一次，你可以令一名角色：1.摸一张牌，然后弃置一半手牌（向上取整）；2.弃置一张牌，"..
  "然后摸当前手牌数一半的牌（向上取整）。",

  ["#jianguo"] = "谏国：选择一项令一名角色执行（向上取整）",
  ["jianguo1"] = "摸一张牌，弃置一半手牌",
  ["jianguo2"] = "弃置一张牌，摸一半手牌",

  ["$jianguo1"] = "彭蠡雁惊，此诚平吴之时。",
  ["$jianguo2"] = "奏三陈之诏，谏一国之弊。",
}

jianguo:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "jianguo-phase", 0)
end)

jianguo:addEffect("active", {
  anim_type = "control",
  prompt = "#jianguo",
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local all_choices = {"jianguo1", "jianguo2"}
    local choices = table.filter(all_choices, function (choice)
      return not table.contains(player:getTableMark("jianguo-phase"), choice)
    end)
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(jianguo.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if self.interaction.data == "jianguo1" then
      return #selected == 0
    elseif self.interaction.data == "jianguo2" then
      return #selected == 0 and not to_select:isNude()
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "jianguo-phase", self.interaction.data)
    if self.interaction.data == "jianguo1" then
      target:drawCards(1, jianguo.name)
      if not target.dead and target:getHandcardNum() > 0 then
        local n = (target:getHandcardNum() + 1) // 2
        room:askToDiscard(target, {
          min_num = n,
          max_num = n,
          include_equip = false,
          skill_name = jianguo.name,
          cancelable = false,
        })
      end
    else
      room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = jianguo.name,
        cancelable = false,
      })
      if not target.dead and target:getHandcardNum() > 0 then
        local n = (target:getHandcardNum() + 1) // 2
        target:drawCards(n, jianguo.name)
      end
    end
  end,
})

return jianguo
