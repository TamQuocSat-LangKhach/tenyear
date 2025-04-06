local xibing = fk.CreateSkill {
  name = "xibing",
}

Fk:loadTranslationTable{
  ["xibing"] = "息兵",
  [":xibing"] = "每回合限一次，当一名其他角色在其出牌阶段内使用黑色【杀】或黑色普通锦囊牌指定唯一目标后，你可以"..
  "令该角色将手牌摸至体力值（至多摸至五张），然后其本回合不能再使用牌。",

  ["#xibing-invoke"] = "息兵：你可以令 %dest 将手牌摸至体力值（至多五张），然后其本回合不能使用牌",

  ["$xibing1"] = "千里运粮，非用兵之利。",
  ["$xibing2"] = "宜弘一代之治，绍三王之迹。",
}

xibing:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xibing.name) and target ~= player and target.phase == Player.Play and
      data.card.color == Card.Black and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      data:isOnlyTarget(data.to) and target:getHandcardNum() < math.min(target.hp, 5) and not target.dead and
      player:usedSkillTimes(xibing.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = xibing.name,
      prompt = "#xibing-invoke::" .. target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "xibing-turn", 1)
    target:drawCards(math.min(target.hp, 5) - target:getHandcardNum(), xibing.name)
  end,
})

xibing:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and player:getMark("xibing-turn") > 0
  end,
})

return xibing
