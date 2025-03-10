local liushi = fk.CreateSkill {
  name = "liushi"
}

Fk:loadTranslationTable{
  ['liushi'] = '流矢',
  ['@liushi'] = '流矢',
  [':liushi'] = '出牌阶段，你可以将一张<font color=>♥</font>牌置于牌堆顶，视为对一名角色使用一张【杀】（不计入次数且无距离限制）。受到此【杀】伤害的角色手牌上限-1。',
  ['$liushi1'] = '就你叫夏侯惇？',
  ['$liushi2'] = '兀那贼将，且吃我一箭！',
}

liushi:addEffect('active', {
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:prohibitUse(Fk:cloneCard("slash"))
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Heart
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id
      and not player:isProhibited(Fk:currentRoom():getPlayerById(to_select), Fk:cloneCard("slash"))
  end,
  on_use = function(self, room, effect, event)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = liushi.name,
      moveVisible = true
    })
    local slash = Fk:cloneCard("slash")
    slash.skillName = liushi.name
    room:useCard({
      from = player.id,
      tos = {{target.id}},
      card = slash,
      extraUse = true,
    })
    if use.damageDealt then
      for _, p in ipairs(room.alive_players) do
        if use.damageDealt[p.id] then
          room:addPlayerMark(target, "@liushi", 1)
        end
      end
    end
  end,
})

local liushi_maxcards = fk.CreateSkill {
  name = "#liushi_maxcards"
}

liushi_maxcards:addEffect('maxcards', {
  correct_func = function(self, player)
    return -player:getMark("@liushi")
  end,
})

return liushi, liushi_maxcards
