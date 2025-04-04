local rihui = fk.CreateSkill {
  name = "rihui",
}

Fk:loadTranslationTable{
  ["rihui"] = "日慧",
  [":rihui"] = "每回合限一次，当你使用指定唯一其他角色为目标的普通锦囊牌或黑色基本牌后，若其：不是“信众”，所有“信众”均视为对其使用此牌；"..
  "是“信众”，你可以获得其区域内的一张牌。",

  ["#rihui-use"] = "日慧：你可以令所有“信众”视为对 %dest 使用一张【%arg】",
  ["#rihui-get"] = "日慧：你可以获得 %dest 区域内一张牌",

  ["$rihui1"] = "甲子双至，黄巾再起。",
  ["$rihui2"] = "日中必彗，操刀必割。",
}

rihui:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(rihui.name) and
      (data.card:isCommonTrick() or (data.card.type == Card.TypeBasic and data.card.color == Card.Black)) and
      data:isOnlyTarget(data.tos[1]) and data.tos[1] ~= player and
      player:usedSkillTimes(rihui.name, Player.HistoryTurn) == 0 then
      if data.tos[1]:getMark("@@xinzhong") > 0 then
        return not data.tos[1]:isAllNude()
      else
        return table.find(player.room:getOtherPlayers(player, false), function(p)
          return p:getMark("@@xinzhong") > 0 and not p:isProhibited(data.tos[1], Fk:cloneCard(data.card.name))
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if data.tos[1]:getMark("@@xinzhong") == 0 then
      return room:askToSkillInvoke(player, {
        skill_name = rihui.name,
        prompt = "#rihui-use::"..data.tos[1].id..":"..data.card.name,
      })
    elseif room:askToSkillInvoke(player, {
        skill_name = rihui.name,
        prompt = "#rihui-get::"..data.tos[1].id,
      }) then
      event:setCostData(self, {tos = {data.tos[1]}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.tos[1]
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        if to.dead then return end
        if p:getMark("@@xinzhong") > 0 then
          local card = Fk:cloneCard(data.card.name)
          card.skillName = rihui.name
          local use = {
            from = p,
            tos = {to},
            card = card,
            extraUse = true,
            subTos = data.subTos,
          }
          room:useCard(use)
        end
      end
    else
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "hej",
        skill_name = rihui.name,
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player, rihui.name)
    end
  end,
})

return rihui
