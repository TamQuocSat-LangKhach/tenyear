local kengqiang = fk.CreateSkill {
  name = "kengqiang"
}

Fk:loadTranslationTable{
  ['kengqiang'] = '铿锵',
  ['shangjue'] = '殇决',
  ['kengqiang1'] = '摸体力上限张牌',
  ['kengqiang2'] = '此伤害+1，你获得造成伤害的牌',
  ['#kengqiang-invoke'] = '铿锵：你可以选择一项',
  [':kengqiang'] = '每回合限一次，当你造成伤害时，你可以选择一项：1.摸X张牌（X为你的体力上限）；2.此伤害+1，你获得造成伤害的牌。',
  ['$kengqiang1'] = '女子着征袍，战意越关山。',
  ['$kengqiang2'] = '兴武效妇好，挥钺断苍穹！',
}

kengqiang:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(kengqiang.name) then
      if player:usedSkillTimes("shangjue", Player.HistoryGame) == 0 then
        return player:usedSkillTimes(kengqiang.name, Player.HistoryTurn) == 0 and
          player:getMark("kengqiang1-turn") == 0 and player:getMark("kengqiang2-turn") == 0
      else
        return player:getMark("kengqiang1-turn") == 0 or player:getMark("kengqiang2-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"kengqiang1", "kengqiang2", "Cancel"}
    local choices = table.simpleClone(all_choices)
    for i = 2, 1, -1 do
      if player:getMark("kengqiang"..i.."-turn") > 0 then
        table.remove(choices, i)
      end
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = kengqiang.name,
      prompt = "#kengqiang-invoke",
      detailed = false,
      all_choices = all_choices
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "kengqiang1" then
      player:drawCards(player.maxHp, kengqiang.name)
    else
      data.damage = data.damage + 1
      if data.card and room:getCardArea(data.card) == Card.Processing then
        room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, kengqiang.name, nil, true, player.id)
      end
    end
  end,
})

return kengqiang
