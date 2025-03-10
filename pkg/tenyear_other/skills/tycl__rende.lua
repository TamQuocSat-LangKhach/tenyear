local tycl__rende = fk.CreateSkill {
  name = "tycl__rende"
}

Fk:loadTranslationTable{
  ['tycl__rende'] = '章武',
  ['#tycl__rende'] = '章武：获得一名其他角色两张手牌，然后视为使用一张基本牌',
  ['#tycl__rende-ask'] = '章武：你可视为使用一张基本牌',
  [':tycl__rende'] = '出牌阶段每名其他角色限一次，你可以获得一名其他角色两张手牌，然后视为使用一张基本牌。',
  ['$tycl__rende1'] = '惟贤惟德能服于人。',
  ['$tycl__rende2'] = '以德服人。',
}

tycl__rende:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#tycl__rende",
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= player.id and target:getMark("tycl__rende-phase") == 0 and target:getHandcardNum() > 1
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "tycl__rende-phase", 1)
    local cards = room:askToChooseCards(player, {
      min = 2,
      max = 2,
      flag = "h",
      skill_name = tycl__rende.name
    })
    room:obtainCard(player.id, cards, false, fk.ReasonPrey)
    if player.dead then return end
    local mark = player:getMark("tycl__rende")
    if mark == 0 then
      mark = U.getAllCardNames("b")
      room:setPlayerMark(player, "tycl__rende", mark)
    end
    if #mark == 0 then return end
    U.askForUseVirtualCard(room, player, mark, nil, tycl__rende.name, "#tycl__rende-ask", true, false, false, false)
  end,
})

return tycl__rende
