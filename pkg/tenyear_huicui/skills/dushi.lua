local dushi = fk.CreateSkill {
  name = "dushi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dushi"] = "毒逝",
  [":dushi"] = "锁定技，你处于濒死状态时，其他角色不能对你使用【桃】。你死亡时，你选择一名其他角色获得〖毒逝〗。",

  ["#dushi-choose"] = "毒逝：令一名其他角色获得“毒逝”",

  ["$dushi1"] = "孤无病，此药无需服。",
  ["$dushi2"] = "辟恶之毒，为最毒。",
}

dushi:addEffect(fk.Death, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dushi.name, false, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:hasSkill(dushi.name, true)
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#dushi-choose",
      skill_name = dushi.name,
      cancelable = false,
    })[1]
    room:handleAddLoseSkills(to, dushi.name)
  end,
})

dushi:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(dushi.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke(dushi.name)
    player.room:notifySkillInvoked(player, dushi.name)
  end
})

dushi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if card.name == "peach" and not player.dying then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p.dying and p:hasSkill(dushi.name) and p ~= player
      end)
    end
  end,
})

return dushi
