local beiyu = fk.CreateSkill {
  name = "beiyu",
}

Fk:loadTranslationTable{
  ["beiyu"] = "备预",
  [":beiyu"] = "出牌阶段限一次，你可以将手牌摸至体力上限，然后将一种花色的所有手牌以任意顺序置于牌堆底。",

  ["#beiyu"] = "备预：将手牌摸至体力上限，然后将一种花色的手牌置于牌堆底",
  ["#beiyu-choose"] = "备预：选择一种花色，将所有此花色的手牌置于牌堆底",

  ["$beiyu1"] = "备预不虞，善之大者也。",
  ["$beiyu2"] = "宜选步骑二万，为讨贼之备。",
}

beiyu:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#beiyu",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(beiyu.name, Player.HistoryPhase) == 0 and player:getHandcardNum() < player.maxHp
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:drawCards(player.maxHp - player:getHandcardNum(), beiyu.name)
    if player.dead or player:isKongcheng() then return end
    local choices = {}
    for _, id in ipairs(player:getCardIds("h")) do
      if Fk:getCardById(id).suit ~= Card.NoSuit then
        table.insertIfNeed(choices, Fk:getCardById(id):getSuitString(true))
      end
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = beiyu.name,
      prompt = "#beiyu-choose",
      all_choices = {"log_spade", "log_heart", "log_club", "log_diamond"},
    })
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getSuitString(true) == choice
    end)
    if #cards > 1 then
      local result = room:askToGuanxing(player, {
        cards = cards,
        skill_name = beiyu.name,
        skip = true,
        area_names = {"Bottom", ""}
      })
      cards = result.top
    end
    room:moveCards({
      ids = cards,
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = beiyu.name,
      proposer = player,
      drawPilePosition = -1,
    })
  end,
})

return beiyu
