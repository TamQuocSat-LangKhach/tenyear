local zhongji = fk.CreateSkill {
  name = "zhongji",
}

Fk:loadTranslationTable{
  ["zhongji"] = "螽集",
  [":zhongji"] = "当你使用牌时，若你没有该花色的手牌且手牌数小于体力上限，你可以将手牌摸至体力上限并弃置X张牌（X为本回合发动此技能的次数）。",

  ["$zhongji1"] = "羸汉暴政不息，黄巾永世不绝。",
  ["$zhongji2"] = "宛洛膏如秋实，怎可不生螟虫？",
}

zhongji:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhongji.name) and
      player:getHandcardNum() < player.maxHp and
      not table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).suit == data.card.suit
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(player.maxHp - player:getHandcardNum(), zhongji.name)
    if player.dead then return end
    local n = player:usedSkillTimes(zhongji.name, Player.HistoryTurn)
    room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = zhongji.name,
      cancelable = false,
    })
  end,
})

return zhongji
