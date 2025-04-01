local bingji = fk.CreateSkill {
  name = "bingji",
}

Fk:loadTranslationTable{
  ["bingji"] = "秉纪",
  [":bingji"] = "出牌阶段每种花色限一次，若你的手牌均为同一花色，则你可以展示所有手牌（至少一张），然后视为对一名其他角色使用一张【杀】"..
  "（有距离限制且不计入次数）或一张【桃】。",

  ["#bingji"] = "秉纪：展示所有手牌，视为对一名其他角色使用【杀】或【桃】",
  ["@bingji-phase"] = "秉纪",
  ["#bingji-use"] = "秉纪：视为对一名其他角色使用一张【杀】或【桃】",

  ["$bingji1"] = "权其轻重，而后施令。",
  ["$bingji2"] = "罪而后赦，以立恩威。",
}

bingji:addEffect("active", {
  anim_type = "control",
  prompt = "#bingji",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng() and
      not table.contains(player:getTableMark("@bingji-phase"), Fk:getCardById(player:getCardIds("h")[1]):getSuitString(true)) and
      table.every(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):compareSuitWith(Fk:getCardById(player:getCardIds("h")[1]))
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:addTableMark(player, "@bingji-phase", Fk:getCardById(player:getCardIds("h")[1]):getSuitString(true))
    player:showCards(player:getCardIds("h"))
    if player.dead or #room:getOtherPlayers(player, false) == 0 then return end
    local names = {}
    for _, name in ipairs({"slash", "peach"}) do
      local card = Fk:cloneCard(name)
      card.skillName = bingji.name
      if table.find(room:getOtherPlayers(player, false), function(p)
        return player:canUseTo(card, p, {bypass_distances = false, bypass_times = true})
      end) then
        table.insert(names, name)
      end
    end
    if #names == 0 then return end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "bingji_viewas",
      prompt = "#bingji-use",
      cancelable = false,
    })
    if not (success and dat) then
      dat = {}
      dat.interaction = names[1]
      local card = Fk:cloneCard(dat.interaction)
      card.skillName = bingji.name
      dat.targets = {table.filter(room:getOtherPlayers(player, false), function(p)
        return player:canUseTo(card, p, {bypass_distances = false, bypass_times = true})
      end)[1]}
    end
    room:useVirtualCard(dat.interaction, nil, player, dat.targets, bingji.name, true)
  end
})

return bingji
