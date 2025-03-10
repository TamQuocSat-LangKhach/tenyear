local ty_ex__zhanjue = fk.CreateSkill {
  name = "ty_ex__zhanjue"
}

Fk:loadTranslationTable{
  ['ty_ex__zhanjue'] = '战绝',
  ['#ty_ex__zhanjue'] = '战绝：你可以将除因勤王获得的牌外的所有手牌当【决斗】使用，然后你和受伤的角色各摸一张牌',
  ['@@ty_ex__qinwang-inhand-turn'] = '勤王',
  [':ty_ex__zhanjue'] = '出牌阶段，你可以将所有手牌（至少一张）当【决斗】使用，然后此【决斗】结算结束后，你和因此【决斗】受伤的角色各摸一张牌。若你本阶段因此技能而摸过至少三张牌，本阶段你的〖战绝〗失效。',
  ['$ty_ex__zhanjue1'] = '千里锦绣江山，岂能拱手相让！',
  ['$ty_ex__zhanjue2'] = '先帝一生心血，安可坐以待毙！',
}

ty_ex__zhanjue:addEffect('viewas', {
  anim_type = "offensive",
  card_num = 0,
  prompt = "#ty_ex__zhanjue",
  times = function(self)
    return self.player.phase == Player.Play and 3 - self.player:getMark("ty_ex__zhanjue-phase") or -1
  end,
  card_filter = function(self, player, to_select, selected)
    return false
  end,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("duel")
    local cards = table.filter(player:getCardIds("h"), function (id) 
      return Fk:getCardById(id):getMark("@@ty_ex__qinwang-inhand-turn") == 0 
    end)
    card:addSubcards(cards)
    return card
  end,
  after_use = function(self, player, use)
    local room = player.room
    if not player.dead then
      player:drawCards(1, ty_ex__zhanjue.name)
      room:addPlayerMark(player, "ty_ex__zhanjue-phase", 1)
    end
    if use.damageDealt then
      for _, p in ipairs(room.alive_players) do
        if use.damageDealt[p.id] then
          p:drawCards(1, ty_ex__zhanjue.name)
          if p == player then
            room:addPlayerMark(player, "ty_ex__zhanjue-phase", 1)
          end
        end
      end
    end
  end,
  enabled_at_play = function(self, player)
    return player:getMark("ty_ex__zhanjue-phase") < 3 and table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@ty_ex__qinwang-inhand") == 0 
    end)
  end
})

return ty_ex__zhanjue
