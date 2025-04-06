local fenming = fk.CreateSkill{
  name = "ty__fenming",
}

Fk:loadTranslationTable{
  ["ty__fenming"] = "奋命",
  [":ty__fenming"] = "结束阶段，若你处于横置状态，你可以弃置所有处于横置状态角色的各一张牌。",

  ["$ty__fenming1"] = "东吴男儿，岂是贪生怕死之辈？",
  ["$ty__fenming2"] = "不惜性命，也要保主公周全！",
}

fenming:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fenming.name) and player.phase == Player.Finish and
      player.chained
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if player.dead then return end
      if p.chained and not p:isNude() and not p.dead then
        if p == player then
          room:askToDiscard(player, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = fenming.name,
            cancelable = false,
          })
        else
          local id = room:askToChooseCard(player, {
            target = p,
            flag = "he",
            skill_name = fenming.name,
          })
          room:throwCard(id, fenming.name, p, player)
        end
      end
    end
  end,
})

return fenming
