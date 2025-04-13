local zhanjue = fk.CreateSkill {
  name = "ty_ex__zhanjue",
}

Fk:loadTranslationTable{
  ["ty_ex__zhanjue"] = "战绝",
  [":ty_ex__zhanjue"] = "出牌阶段，你可以将所有手牌（至少一张）当【决斗】使用，此【决斗】结算结束后，你和因此【决斗】受伤的角色"..
  "各摸一张牌。若你本阶段因此至少摸过三张牌，本回合〖战绝〗失效。",

  ["#ty_ex__zhanjue"] = "战绝：将所有手牌当【决斗】使用，然后你和受伤的角色各摸一张牌",

  ["$ty_ex__zhanjue1"] = "千里锦绣江山，岂能拱手相让！",
  ["$ty_ex__zhanjue2"] = "先帝一生心血，安可坐以待毙！",
}

zhanjue:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#ty_ex__zhanjue",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("duel")
    cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@ty_ex__qinwang-inhand-turn") == 0
    end)
    card:addSubcards(cards)
    return card
  end,
  after_use = function(self, player, use)
    local room = player.room
    if not player.dead then
      room:addPlayerMark(player, "ty_ex__zhanjue-phase", 1)
      player:drawCards(1, zhanjue.name)
    end
    if use.damageDealt then
      for _, p in ipairs(room:getAlivePlayers()) do
        if use.damageDealt[p] and not p.dead then
          if p == player then
            room:addPlayerMark(player, "ty_ex__zhanjue-phase", 1)
          end
          p:drawCards(1, zhanjue.name)
        end
      end
    end
    if player:getMark("ty_ex__zhanjue-phase") > 2 then
      room:invalidateSkill(player, zhanjue.name, "-turn")
    end
  end,
  enabled_at_play = function(self, player)
    return table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@ty_ex__qinwang-inhand") == 0
    end)
  end
})

return zhanjue
