local bingji = fk.CreateSkill {
  name = "bingji"
}

Fk:loadTranslationTable{
  ['bingji'] = '秉纪',
  ['#bingji'] = '秉纪：展示所有手牌，视为对一名其他角色使用【杀】或【桃】',
  ['@bingji-phase'] = '秉纪',
  ['#bingji-choice'] = '秉纪：选择对其他角色使用的牌名',
  ['#bingji-choose'] = '秉纪：视为对一名其他角色使用【%arg】',
  [':bingji'] = '出牌阶段每种花色限一次，若你的手牌均为同一花色，则你可以展示所有手牌（至少一张），然后视为对一名其他角色使用一张【杀】（有距离限制且不计入次数）或一张【桃】。',
  ['$bingji1'] = '权其轻重，而后施令。',
  ['$bingji2'] = '罪而后赦，以立恩威。',
}

bingji:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#bingji",
  can_use = function(self, player)
    if not player:isKongcheng() then
      local suit = Fk:getCardById(player.player_cards[Player.Hand][1]):getSuitString(true)
      return not table.contains(player:getTableMark("@bingji-phase"), suit)
        and table.every(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getSuitString(true) == suit end)
    end
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, player, room, effect, event)
    local suit = Fk:getCardById(player.player_cards[Player.Hand][1]):getSuitString(true)
    room:addTableMark(player, "@bingji-phase", suit)
    player:showCards(player.player_cards[Player.Hand])
    local targets = {["peach"] = {}, ["slash"] = {}}
    local choices = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player:canUseTo(Fk:cloneCard("slash"), p, {bypass_times = true}) then
        table.insert(targets["slash"], p.id)
      end
      local peach = Fk:cloneCard("peach")
      if not player:prohibitUse(peach) and not player:isProhibited(p, peach) and p:isWounded() then
        table.insert(targets["peach"], p.id)
      end
    end
    if #targets["peach"] > 0 then table.insert(choices, "peach") end
    if #targets["slash"] > 0 then table.insert(choices, "slash") end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = bingji.name,
      prompt = "#bingji-choice",
      detailed = false,
      all_choices = {"slash", "peach"}
    })
    local tos = room:askToChoosePlayers(player, {
      targets = Fk:getPlayerByIds(targets[choice]),
      min_num = 1,
      max_num = 1,
      prompt = "#bingji-choose:::"..choice,
      skill_name = bingji.name
    })
    local to = room:getPlayerById(tos[1])
    room:useVirtualCard(choice, nil, player, to, bingji.name, true)
  end
})

return bingji
