local rihui = fk.CreateSkill {
  name = "rihui"
}

Fk:loadTranslationTable{
  ['rihui'] = '日慧',
  ['@@xinzhong'] = '信众',
  ['#rihui-use'] = '日慧：你可以令所有“信众”视为对 %dest 使用一张【%arg】',
  ['#rihui-get'] = '日慧：你可以获得 %dest 区域内一张牌',
  [':rihui'] = '每回合限一次，当你使用指定唯一其他角色为目标的普通锦囊牌或黑色基本牌后，若其：不是“信众”，所有“信众”均视为对其使用此牌；是“信众”，你可以获得其区域内的一张牌。',
  ['$rihui1'] = '甲子双至，黄巾再起。',
  ['$rihui2'] = '日中必彗，操刀必割。',
}

rihui:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(rihui.name) and player:usedSkillTimes(rihui.name, Player.HistoryTurn) == 0 and
      (data.card:isCommonTrick() or (data.card.type == Card.TypeBasic and data.card.color == Card.Black)) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to.dead then return end
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
          return room:askToSkillInvoke(player, { skill_name = rihui.name, prompt = "#rihui-use::" .. to.id .. ":" .. data.card.name })
        end
      end
    else
      if to:isAllNude() then return end
      return room:askToSkillInvoke(player, { skill_name = rihui.name, prompt = "#rihui-get::" .. to.id })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
          if to.dead or p.dead then return end
          room:useVirtualCard(data.card.name, nil, p, to, rihui.name, true)
        end
      end
    else
      local id = room:askToChooseCard(player, { target = to, flag = "hej", skill_name = rihui.name })
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
})

return rihui
