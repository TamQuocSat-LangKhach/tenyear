local anliao = fk.CreateSkill {
  name = "anliao",
}

Fk:loadTranslationTable{
  ["anliao"] = "安辽",
  [":anliao"] = "出牌阶段限X次（X为群势力角色数），你可以重铸一名角色的一张牌。",

  ["#anliao"] = "安辽：你可以重铸一名角色的一张牌",

  ["$anliao1"] = "地阔天高，大有可为。",
  ["$anliao2"] = "水草丰沛，当展宏图。",
}

anliao:addEffect("active", {
  anim_type = "control",
  prompt = "#anliao",
  times = function(self, player)
    if player.phase == Player.Play then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.kingdom == "qun" then
          n = n + 1
        end
      end
      return math.max(0, n - player:usedSkillTimes(anliao.name, Player.HistoryPhase))
    end
    return -1
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p.kingdom == "qun" then
        n = n + 1
      end
    end
    return player:usedSkillTimes(anliao.name, Player.HistoryPhase) < n
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not to_select:isNude()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "he",
      skill_name = anliao.name,
    })
    room:recastCard({id}, target, anliao.name)
  end,
})

return anliao
