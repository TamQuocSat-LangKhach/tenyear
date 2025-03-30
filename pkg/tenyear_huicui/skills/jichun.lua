local jichun = fk.CreateSkill {
  name = "jichun",
}

Fk:loadTranslationTable{
  ["jichun"] = "寄春",
  [":jichun"] = "出牌阶段各限一次，你可以展示一张牌，然后选择一项：1.将此牌交给一名手牌数小于你的角色，然后摸X张牌；"..
  "2.弃置此牌，然后弃置一名手牌数大于你的角色区域里至多X张牌。（X为此牌的牌名字数）",

  ["#jichun"] = "寄春：展示一张牌，选择一项",
  ["jichun1"] = "将%arg交给一名手牌数小于你的角色，摸%arg2张牌",
  ["jichun2"] = "弃置%arg，弃置一名手牌数大于你的角色区域内%arg2张牌",
  ["#jichun-give"] = "寄春：将%arg交给一名手牌数小于你的角色并摸%arg2张牌",
  ["#jichun-discard"] = "寄春：选择一名手牌数大于你的角色，弃置其区域里至多%arg张牌",

  ["$jichun1"] = "寒冬已至，花开不远矣。",
  ["$jichun2"] = "梅凌霜雪，其香不逊晚来者。",
}

jichun:addEffect("active", {
  anim_type = "control",
  prompt = "#jichun",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(jichun.name, Player.HistoryPhase) < 2 and #player:getTableMark("jichun-phase") < 2
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local card = Fk:getCardById(effect.cards[1])
    local n = Fk:translate(card.trueName, "zh_CN"):len()
    player:showCards(effect.cards)
    local targets = table.filter(room.alive_players, function (p)
      return p:getHandcardNum() < player:getHandcardNum()
    end)
    local all_choices = {
      "jichun1:::"..card:toLogString()..":"..n,
      "jichun2:::"..card:toLogString()..":"..n,
    }
    local choices = table.simpleClone(all_choices)
    if table.contains(player:getTableMark("jichun-phase"), 2) then
      table.remove(choices, 2)
    end
    if #targets == 0 or table.contains(player:getTableMark("jichun-phase"), 1) then
      table.remove(choices, 1)
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = jichun.name,
      all_choices = all_choices,
    })
    room:addTableMark(player, "jichun-phase", tonumber(choice[7]))
    if choice:startsWith("jichun1") then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#jichun-give:::"..card:toLogString()..":"..n,
        skill_name = jichun.name,
        cancelable = false,
      })[1]
      room:moveCardTo(effect.cards, Player.Hand, to, fk.ReasonGive, jichun.name, nil, true, player)
      if not player.dead then
        player:drawCards(n, jichun.name)
      end
    elseif not player:prohibitDiscard(card) then
      room:throwCard(effect.cards, jichun.name, player)
      if player.dead then return end
      targets = table.filter(room.alive_players, function (p)
        return p:getHandcardNum() > player:getHandcardNum()
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#jichun-discard:::"..n,
        skill_name = jichun.name,
        cancelable = false,
      })[1]
      local cards = room:askToChooseCards(player, {
        skill_name = jichun.name,
        target = to,
        min = 1,
        max = n,
        flag = "hej",
      })
      if #cards > 0 then
        room:throwCard(cards, jichun.name, to, player)
      end
    end
  end,
})

jichun:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "jichun-phase", 0)
end)

return jichun
