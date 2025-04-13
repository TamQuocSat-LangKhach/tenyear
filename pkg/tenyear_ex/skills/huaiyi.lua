local huaiyi = fk.CreateSkill {
  name = "ty_ex__huaiyi",
}

Fk:loadTranslationTable{
  ["ty_ex__huaiyi"] = "怀异",
  [":ty_ex__huaiyi"] = "出牌阶段限一次，你可以展示所有手牌。若仅有一种颜色，你摸一张牌，然后此技能本阶段改为“出牌阶段限两次”；"..
  "若有两种颜色，你弃置其中一种颜色的牌，然后获得至多X名角色各一张牌（X为弃置的手牌数），若你获得的牌大于一张，你失去1点体力。",

  ["#ty_ex__huaiyi"] = "怀异：展示手牌，只有一种颜色摸一张牌，有两种颜色则弃置其中一种，获得等量角色各一张牌",
  ["#ty_ex__huaiyi-choose"] = "怀异：你可以获得至多%arg名角色各一张牌",

  ["$ty_ex__huaiyi1"] = "曹刘可王，孤亦可王！",
  ["$ty_ex__huaiyi2"] = "汉失其鹿，天下豪杰当共逐之。",
}

huaiyi:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#ty_ex__huaiyi",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(huaiyi.name, Player.HistoryPhase) < 1 + player:getMark("ty_ex__huaiyi-phase") and
      not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = table.simpleClone(player:getCardIds("h"))
    player:showCards(cards)
    if player.dead then return end
    if not table.find(cards, function (id)
        return table.find(cards, function (id2)
          return Fk:getCardById(id).color ~= Fk:getCardById(id2).color
        end) ~= nil
      end) then
      if player:getMark("ty_ex__huaiyi-phase") == 0 then
        room:setPlayerMark(player, "ty_ex__huaiyi-phase", 1)
      end
      player:drawCards(1, huaiyi.name)
      return
    end
    if player:isKongcheng() then return end
    local red = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id) and Fk:getCardById(id).color == Card.Red and not player:prohibitDiscard(id)
    end)
    local black = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id) and Fk:getCardById(id).color == Card.Black and not player:prohibitDiscard(id)
    end)
    local colors = {}
    if #red > 0 then
      table.insert(colors, "red")
    end
    if #black > 0 then
      table.insert(colors, "black")
    end
    if #colors == 0 then return end
    local color = room:askToChoice(player, {
      choices = colors,
      skill_name = huaiyi.name,
      all_choices = {"red", "black"},
    })
    cards = color == "red" and red or black
    room:throwCard(cards, huaiyi.name, player, player)
    if player.dead then return end
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    if #targets == 0 then return end
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = #cards,
      skill_name = huaiyi.name,
      prompt = "#ty_ex__huaiyi-choose:::"..#cards,
    })
    if #targets > 0 then
      room:sortByAction(targets)
      local n = 0
      for _, to in ipairs(targets) do
        if not to:isNude() and not to.dead then
          local id = room:askToChooseCard(player, {
            target = to,
            flag = "he",
            skill_name = huaiyi.name,
          })
          n = n + 1
          room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, huaiyi.name, nil, false, player)
          if player.dead then return end
        end
      end
      if n > 1 and not player.dead then
        room:loseHp(player, 1, huaiyi.name)
      end
    end
  end,
})

return huaiyi
