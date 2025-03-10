local lulue = fk.CreateSkill {
  name = "lulue"
}

Fk:loadTranslationTable{
  ['lulue'] = '掳掠',
  ['#lulue-choose'] = '掳掠：你可以令一名有手牌且手牌数小于你的其他角色选择一项',
  ['lulue_give'] = '将所有手牌交给其，其翻面',
  ['lulue_slash'] = '你翻面，视为对其使用【杀】',
  ['#lulue-choice'] = '掳掠：选择对 %src 执行的一项',
  [':lulue'] = '出牌阶段开始时，你可以令一名有手牌且手牌数小于你的其他角色选择：1.将所有手牌交给你，你翻面；2.翻面，视为对你使用【杀】。',
  ['$lulue1'] = '趁火打劫，乘危掳掠。',
  ['$lulue2'] = '天下大乱，掳掠以自保。',
}

lulue:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lulue.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (p:getHandcardNum() < #player.player_cards[Player.Hand] and not p:isKongcheng()) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#lulue-choose",
      skill_name = lulue.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, to[1].id)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local choice = room:askToChoice(to, {
      choices = {"lulue_give", "lulue_slash"},
      skill_name = lulue.name,
      prompt = "#lulue-choice:"..player.id
    })
    if choice == "lulue_give" then
      room:obtainCard(player.id, to:getCardIds(Player.Hand), false, fk.ReasonGive, to.id)
      player:turnOver()
    else
      to:turnOver()
      room:useVirtualCard("slash", nil, to, player, lulue.name, true)
    end
  end,
})

return lulue
