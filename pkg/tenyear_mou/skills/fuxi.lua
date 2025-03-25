local fuxi = fk.CreateSkill {
  name = "fuxi",
}

Fk:loadTranslationTable{
  ["fuxi"] = "附袭",
  [":fuxi"] = "其他角色的出牌阶段开始时，若其为手牌数最多的角色，你可以选择：1.将一张牌交给其，你摸两张牌；2.弃置其一张牌，视为对其使用【杀】。",

  ["#fuxi-choice"] = "附袭：你可以对 %dest 发动“附袭”，选择一项",
  ["fuxi_discard"] = "弃置%dest一张牌，视为对其使用【杀】",
  ["fuxi_give"] = "交给%dest一张牌，你摸两张牌",
  ["#fuxi-give"] = "附袭：请交给 %dest 一张牌",

  ["$fuxi1"] = "可因势而附，亦可因势而袭。",
  ["$fuxi2"] = "仗剑在手，或亮之，或藏之。",
}

fuxi:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(fuxi.name) and target.phase == Player.Play and not target.dead and
      table.every(player.room.alive_players, function (p)
        return p:getHandcardNum() <= target:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"fuxi_discard::"..target.id, "Cancel"}
    if not player:isNude() then
      table.insert(choices, 2, "fuxi_give::"..target.id)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = fuxi.name,
      prompt = "#fuxi-choice::" .. target.id,
      detailed = false,
      all_choices = {"fuxi_discard::"..target.id, "fuxi_give::"..target.id, "Cancel"}
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(fuxi.name)
    if event:getCostData(self).choice:startsWith("fuxi_give") then
      room:notifySkillInvoked(player, fuxi.name, "support")
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = fuxi.name,
        cancelable = false,
        prompt = "#fuxi-give::" .. target.id,
      })
      room:obtainCard(target, cards, false, fk.ReasonGive, player, fuxi.name)
      if not player.dead then
        player:drawCards(2, fuxi.name)
      end
    else
      room:notifySkillInvoked(player, fuxi.name, "offensive")
      if not target:isNude() then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = fuxi.name,
        })
        room:throwCard(card, fuxi.name, target, player)
        if player.dead or target.dead then return end
      end
      room:useVirtualCard("slash", nil, player, target, fuxi.name, true)
    end
  end,
})

return fuxi
