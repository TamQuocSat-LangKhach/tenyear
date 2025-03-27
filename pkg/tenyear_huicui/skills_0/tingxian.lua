local tingxian = fk.CreateSkill {
  name = "tingxian"
}

Fk:loadTranslationTable{
  ['tingxian'] = '铤险',
  ['#tingxian-invoke'] = '铤险：你可以摸%arg张牌，然后可以令此【杀】对至多等量的目标无效',
  ['#tingxian-choose'] = '铤险：你可以令此【杀】对至多%arg名目标无效',
  [':tingxian'] = '每回合限一次，你使用【杀】指定目标后，你可以摸X张牌，然后可以令此【杀】对其中至多X个目标无效（X为你装备区的牌数+1）。',
  ['$tingxian1'] = '大争之世，当举兵行义。',
  ['$tingxian2'] = '聚兵三千众，可为天下先。',
}

tingxian:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tingxian) and data.card.trueName == "slash" and data.firstTarget and
      player:usedSkillTimes(tingxian.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Equip] + 1
    return player.room:askToSkillInvoke(player, {
      skill_name = tingxian.name,
      prompt = "#tingxian-invoke:::" .. n
    })
  end,
  on_use = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Equip] + 1
    player:drawCards(n, tingxian.name)
    local targets = player.room:askToChoosePlayers(player, {
      targets = AimGroup:getAllTargets(data.tos),
      min_num = 1,
      max_num = n,
      prompt = "#tingxian-choose:::" .. n,
      skill_name = tingxian.name
    })
    if #targets > 0 then
      table.insertTable(data.nullifiedTargets, targets)
    end
  end,
})

return tingxian
