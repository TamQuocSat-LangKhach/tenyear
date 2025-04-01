local ruizhan = fk.CreateSkill {
  name = "ruizhan",
}

Fk:loadTranslationTable{
  ["ruizhan"] = "锐战",
  [":ruizhan"] = "其他角色准备阶段，若其手牌数不小于体力值，你可以与其拼点：若你赢或者拼点牌中有【杀】，你视为对其使用一张【杀】；"..
  "若两项均满足且此【杀】造成伤害，你获得其一张牌。",

  ["#ruizhan-invoke"] = "锐战：你可以与 %dest 拼点，若赢或拼点牌中有【杀】，视为对其使用【杀】",
  ["#ruizhan-prey"] = "锐战：获得 %dest 一张牌",

  ["$ruizhan1"] = "敌势汹汹，当急攻以挫其锐。",
  ["$ruizhan2"] = "威愿领骑兵千人，以破敌前军。",
}

ruizhan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ruizhan.name) and target ~= player and target.phase == Player.Start and
      target:getHandcardNum() >= target.hp and player:canPindian(target)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = ruizhan.name,
      prompt = "#ruizhan-invoke::" .. target.id
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pindian = player:pindian({target}, ruizhan.name)
    if player.dead or target.dead or player:isProhibited(target, Fk:cloneCard("slash")) then return end
    local yes1 = pindian.results[target].winner == player
    local yes2 = (pindian.fromCard and pindian.fromCard.trueName == "slash") or
      (pindian.results[target].toCard and pindian.results[target].toCard.trueName == "slash")
    if yes1 or yes2 then
      local use = room:useVirtualCard("slash", nil, player, target, ruizhan.name, true)
      if yes1 and yes2 and use and use.damageDealt and use.damageDealt[target] and
        not player.dead and not target.dead and not target:isNude() then
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = ruizhan.name,
          prompt = "#ruizhan-prey::" .. target.id,
        })
        room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, ruizhan.name, nil, false, player)
      end
    end
  end,
})

return ruizhan
