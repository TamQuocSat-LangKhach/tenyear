local shuangrui = fk.CreateSkill {
  name = "shuangrui",
}

Fk:loadTranslationTable{
  ["shuangrui"] = "双锐",
  [":shuangrui"] = "准备阶段，你可以选择一名其他角色，视为对其使用一张【杀】。若其：不在你攻击范围内，此【杀】不可响应，"..
  "你获得〖狩星〗直到回合结束；在你攻击范围内，此【杀】伤害+1，你获得〖铩雪〗直到回合结束。",

  ["#shuangrui-choose"] = "双锐：选择一名角色视为对其使用【杀】，你根据是否在其攻击范围内获得不同的技能",

  ["$shuangrui1"] = "刚柔并济，武学之道可不分男女。",
  ["$shuangrui2"] = "人言女子柔弱，我偏要以武证道。",
}

shuangrui:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shuangrui.name) and player.phase == Player.Start and
      #player.room.alive_players > 1
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#shuangrui-choose",
      skill_name = shuangrui.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = Fk:cloneCard("slash")
    card.skillName = shuangrui.name
    local use = {
      from = player,
      tos = {to},
      card = card,
      extraUse = true,
    }
    local skill = ""
    if player:inMyAttackRange(to) then
      use.additionalDamage = 1
      skill = "shaxue"
    else
      use.disresponsiveList = table.simpleClone(room.players)
      skill = "shouxing"
    end
    room:handleAddLoseSkills(player, skill)
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(player, "-"..skill)
    end)
    if player:canUseTo(card, to, {bypass_distances = true, bypass_times = true}) then
      room:useCard(use)
    end
  end,
})

return shuangrui
