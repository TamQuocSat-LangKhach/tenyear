local wangyuan = fk.CreateSkill {
  name = "wangyuan"
}

Fk:loadTranslationTable{
  ['wangyuan'] = '妄缘',
  ['ruiji_wang'] = '妄',
  ['#wangyuan-invoke'] = '妄缘：是否增加一张“妄”？',
  [':wangyuan'] = '当你于回合外失去牌后，你可以随机将牌堆中一张基本牌或锦囊牌置于你的武将牌上，称为“妄”（“妄”的牌名不重复且至多为游戏人数）。',
  ['$wangyuan1'] = '小女子不才，愿伴公子余生。',
  ['$wangyuan2'] = '纵有万钧之力，然不斩情丝。',
}

wangyuan:addEffect(fk.AfterCardsMove, {
  anim_type = "special",
  derived_piles = "ruiji_wang",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(wangyuan.name) and player.phase == Player.NotActive and #player:getPile("ruiji_wang") < #player.room.players then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = wangyuan.name,
      prompt = "#wangyuan-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(player:getPile("ruiji_wang")) do
      table.insertIfNeed(names, Fk:getCardById(id, true).trueName)
    end
    local cards = table.filter(room.draw_pile, function(id)
      local card = Fk:getCardById(id)
      return card.type ~= Card.TypeEquip and not table.contains(names, card.trueName)
    end)
    if #cards > 0 then
      player:addToPile("ruiji_wang", table.random(cards), true, wangyuan.name)
    end
  end,
})

return wangyuan
