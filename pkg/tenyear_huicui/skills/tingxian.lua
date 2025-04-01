local tingxian = fk.CreateSkill {
  name = "tingxian",
}

Fk:loadTranslationTable{
  ["tingxian"] = "铤险",
  [":tingxian"] = "每回合限一次，你使用【杀】指定目标后，你可以摸X张牌，然后可以令此【杀】对其中至多X个目标无效（X为你装备区的牌数+1）。",

  ["#tingxian-invoke"] = "铤险：你可以摸%arg张牌，然后可以令此【杀】对至多等量的目标无效",
  ["#tingxian-choose"] = "铤险：你可以令此【杀】对至多%arg名目标无效",

  ["$tingxian1"] = "大争之世，当举兵行义。",
  ["$tingxian2"] = "聚兵三千众，可为天下先。",
}

tingxian:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tingxian.name) and
      data.card.trueName == "slash" and data.firstTarget and
      player:usedSkillTimes(tingxian.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local n = #player:getCardIds("e") + 1
    return player.room:askToSkillInvoke(player, {
      skill_name = tingxian.name,
      prompt = "#tingxian-invoke:::" .. n,
    })
  end,
  on_use = function(self, event, target, player, data)
    local n = #player:getCardIds("e") + 1
    player:drawCards(n, tingxian.name)
    local targets = table.filter(data.use.tos, function (p)
      return not p.dead
    end)
    if #targets == 0 or player.dead then return end
    local tos = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = n,
      prompt = "#tingxian-choose:::" .. n,
      skill_name = tingxian.name,
    })
    if #tos > 0 then
      data.use.nullifiedTargets = data.use.nullifiedTargets or {}
      for _, p in ipairs(tos) do
        table.insertIfNeed(data.use.nullifiedTargets, p)
      end
    end
  end,
})

return tingxian
