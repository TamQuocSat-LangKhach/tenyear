local fuxi = fk.CreateSkill {
  name = "fuxi"
}

Fk:loadTranslationTable{
  ['fuxi'] = '附袭',
  ['fuxi_discard'] = '弃置其一张牌，视为对其使用【杀】',
  ['fuxi_give'] = '将一张牌交给该角色，你摸两张牌',
  ['#fuxi-choice'] = '是否对 %dest 发动 附袭，选择一项操作',
  ['#fuxi-give'] = '附袭：选择一张牌，交给 %dest',
  [':fuxi'] = '其他角色的出牌阶段开始时，若其为手牌数最多的角色，你可以选择：1.将一张牌交给其，你摸两张牌；2.弃置其一张牌，视为对其使用【杀】。',
  ['$fuxi1'] = '可因势而附，亦可因势而袭。',
  ['$fuxi2'] = '仗剑在手，或亮之，或藏之。',
}

fuxi:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fuxi.name) and target.phase == Player.Play and not target.dead and player ~= target and
      table.every(player.room.alive_players, function (p)
        return p == target or p:getHandcardNum() <= target:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel", "fuxi_discard"}
    if not player:isNude() then
      table.insert(choices, "fuxi_give")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = fuxi.name,
      prompt = "#fuxi-choice::" .. target.id,
      detailed = false,
      all_choices = {"fuxi_give", "fuxi_discard", "Cancel"}
    })
    if choice == "Cancel" then return false end
    room:doIndicate(player.id, {target.id})
    event:setCostData(self, choice)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(fuxi.name)
    if event:getCostData(self) == "fuxi_give" then
      room:notifySkillInvoked(player, fuxi.name, "support")
      local cards = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = fuxi.name,
        cancelable = false,
        pattern = ".",
        prompt = "#fuxi-give::" .. target.id
      })
      room:obtainCard(target, cards[1], false, fk.ReasonGive, player.id, fuxi.name)
      if not player.dead then
        player:drawCards(2, fuxi.name)
      end
    else
      room:notifySkillInvoked(player, fuxi.name, "offensive")
      if not target:isNude() then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = fuxi.name
        })
        room:throwCard({card}, fuxi.name, target, player)
        if player.dead or target.dead then return false end
      end
      room:useVirtualCard("slash", nil, player, target, fuxi.name, true)
    end
  end,
})

return fuxi
