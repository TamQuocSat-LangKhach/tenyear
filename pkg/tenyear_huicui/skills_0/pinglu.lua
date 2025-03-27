local pinglu = fk.CreateSkill {
  name = "pinglu"
}

Fk:loadTranslationTable{
  ['pinglu'] = '平虏',
  ['#pinglu'] = '平虏：获得攻击范围内每名角色各一张随机手牌',
  ['@@pinglu-inhand-phase'] = '平虏',
  [':pinglu'] = '出牌阶段，你可以获得攻击范围内每名其他角色各一张随机手牌。你此阶段不能再发动该技能直到这些牌离开你的手牌。',
  ['$pinglu1'] = '惊涛卷千雪，如林敌舰今何存？',
  ['$pinglu2'] = '羽扇摧樯橹，纶巾曳风流。',
}

pinglu:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#pinglu",
  can_use = function(self, player)
    return not table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@pinglu-inhand-phase") > 0
    end) and
      table.find(Fk:currentRoom().alive_players, function (p)
        return player:inMyAttackRange(p) and not p:isKongcheng()
      end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then return end
      if player:inMyAttackRange(p) and not p.dead and not p:isKongcheng() then
        room:moveCardTo(table.random(p:getCardIds("h")), Card.PlayerHand, player, fk.ReasonPrey, pinglu.name, nil, false, player.id,
          "@@pinglu-inhand-phase")
      end
    end
  end,
})

return pinglu
