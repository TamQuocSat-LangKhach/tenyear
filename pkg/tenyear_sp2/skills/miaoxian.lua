local miaoxian = fk.CreateSkill {
  name = "miaoxian"
}

Fk:loadTranslationTable{
  ['miaoxian'] = '妙弦',
  ['#miaoxian'] = '妙弦：将手牌中的黑色牌当任意锦囊牌使用',
  ['#miaoxian_trigger'] = '妙弦',
  [':miaoxian'] = '每回合限一次，你可以将手牌中的唯一黑色牌当任意一张普通锦囊牌使用；当你使用手牌中的唯一红色牌时，你摸一张牌。',
  ['$miaoxian1'] = '女为悦者容，士为知己死。',
  ['$miaoxian2'] = '与君高歌，请君侧耳。',
}

miaoxian:addEffect('viewas', {
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#miaoxian",
  interaction = function(self)
    local blackcards = table.filter(self.player:getCardIds(Player.Hand), function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return false end
    local all_names = U.getAllCardNames("t")
    local names = U.getViewAsCardNames(self, "miaoxian", all_names, blackcards)
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    if not self.interaction.data then return nil end
    local blackcards = table.filter(player:getCardIds(Player.Hand), function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(blackcards[1])
    card.skillName = miaoxian.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and
      player:usedSkillTimes(miaoxian.name, Player.HistoryTurn) == 0 and
      #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes(miaoxian.name, Player.HistoryTurn) == 0 and
      #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
})

miaoxian:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(miaoxian.name) and table.every(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color ~= Card.Red end) and player.room:getCurrent():getCardUseReason().card.color == Card.Red and
      not (player.room:getCurrent():getCardUseReason().card:isVirtual() and #player.room:getCurrent():getCardUseReason().card.subcards ~= 1)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, miaoxian.name, self.anim_type)
    player:broadcastSkillInvoke(miaoxian.name)
    player:drawCards(1, "miaoxian")
  end,
})

return miaoxian
