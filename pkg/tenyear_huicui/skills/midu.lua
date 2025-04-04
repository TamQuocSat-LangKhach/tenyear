local midu = fk.CreateSkill {
  name = "midu",
}

Fk:loadTranslationTable{
  ["midu"] = "弥笃",
  [":midu"] = "出牌阶段限一次，你可以选择一项：1.废除任意个装备栏或判定区，令一名角色摸等量的牌；2.恢复一个被废除的装备栏或判定区，"..
  "你获得〖活墨〗直到你下个回合开始。",

  ["midu1"] = "废除",
  ["midu2"] = "恢复",
  ["#midu-abort"] = "弥笃：选择要废除的区域",
  ["#midu-draw"] = "弥笃：令一名角色摸%arg张牌",
  ["#midu-resume"] = "弥笃：选择要恢复的区域",

  ["$midu1"] = "皓首穷经，其心不移。",
  ["$midu2"] = "竹简册书，百读不厌。",
}

midu:addEffect("active", {
  anim_type = "support",
  prompt = function (self, player)
    return "#"..self.interaction.data
  end,
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    local choices = {}
    if #player:getAvailableEquipSlots() > 0 or not table.contains(player.sealedSlots, Player.JudgeSlot) then
      table.insert(choices, "midu1")
    end
    if #player.sealedSlots > 0 then
      table.insert(choices, "midu2")
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(midu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    if self.interaction.data == "midu1" then
      local choices = {}
      if not table.contains(player.sealedSlots, Player.JudgeSlot) then
        table.insert(choices, "JudgeSlot")
      end
      table.insertTable(choices, player:getAvailableEquipSlots())
      local choice = room:askToChoices(player, {
        choices = choices,
        min_num = 1,
        max_num = #choices,
        skill_name = midu.name,
        prompt = "#midu-abort",
      })
      room:abortPlayerArea(player, choice)
      if not player.dead then
        local to = room:askToChoosePlayers(player, {
          targets = room.alive_players,
          min_num = 1,
          max_num = 1,
          prompt = "#midu-draw:::"..#choice,
          skill_name = midu.name,
          cancelable = false,
        })[1]
        to:drawCards(#choice, midu.name)
      end
    else
      local choices = table.simpleClone(player.sealedSlots)
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = midu.name,
        prompt = "#midu-resume",
      })
      room:resumePlayerArea(player, {choice})
      if not player:hasSkill("ty_ex__huomo", true) then
        room:setPlayerMark(player, midu.name, 1)
        room:handleAddLoseSkills(player, "ty_ex__huomo")
      end
    end
  end,
})

midu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(midu.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, midu.name, 0)
    room:handleAddLoseSkills(player, "-ty_ex__huomo", nil)
  end,
})

return midu
