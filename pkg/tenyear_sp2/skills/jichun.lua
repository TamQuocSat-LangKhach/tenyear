local jichun = fk.CreateSkill {
  name = "jichun"
}

Fk:loadTranslationTable{
  ['jichun'] = '寄春',
  ['#jichun-active'] = '发动 寄春，选择一张牌展示之',
  ['jichun1'] = '将展示牌交给一名手牌数小于你的角色并摸牌',
  ['jichun2'] = '弃置展示牌，然后弃置一名手牌数大于你的角色区域里的牌',
  ['#jichun-choice'] = '寄春：你展示的%arg牌名字数为%arg2，清选择：',
  ['#jichun-give'] = '寄春：将展示的%arg交给一名手牌数小于你的角色并摸%arg2张牌',
  ['#jichun-discard'] = '寄春：选择一名手牌数大于你的角色弃置其区域里至多%arg张牌',
  [':jichun'] = '出牌阶段限两次，你可以展示一张牌，选择于当前阶段内未选择过的项：1.将此牌交给一名手牌数小于你的角色，然后摸X张牌；2.弃置此牌，然后弃置一名手牌数大于你的角色区域里至多X张牌。（X为此牌的牌名字数）',
  ['$jichun1'] = '寒冬已至，花开不远矣。',
  ['$jichun2'] = '梅凌霜雪，其香不逊晚来者。',
}

jichun:addEffect('active', {
  anim_type = "support",
  prompt = "#jichun-active",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(jichun.name, Player.HistoryPhase) < 2 and
      (player:getMark("jichun1-phase") == 0 or player:getMark("jichun2-phase") == 0)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:getCardById(effect.cards[1])
    local n = Fk:translate(card.trueName, "zh_CN"):len()
    player:showCards(effect.cards)
    --room:delay(1000)
    local targets = table.map(table.filter(room.alive_players, function (p)
      return p:getHandcardNum() < player:getHandcardNum()
    end), Util.IdMapper)
    local choices = {}
    if #targets > 0 and player:getMark("jichun1-phase") == 0 then
      table.insert(choices, "jichun1")
    end
    if player:getMark("jichun2-phase") == 0 then
      table.insert(choices, "jichun2")
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = jichun.name,
      prompt = "#jichun-choice:::"..card:toLogString()..":"..tostring(n),
      all_choices = {"jichun1", "jichun2"},
    })
    room:setPlayerMark(player, choice.."-phase", 1)
    if choice == "jichun1" then
      local targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#jichun-give:::" .. card:toLogString() .. ":" .. tostring(n),
        skill_name = jichun.name,
      })
      room:moveCardTo(effect.cards, Player.Hand, room:getPlayerById(targets[1]), fk.ReasonGive, jichun.name,
        nil, true, player.id)
      if not player.dead then
        player:drawCards(n, jichun.name)
      end
    elseif not player:prohibitDiscard(card) then
      room:throwCard(effect.cards, jichun.name, player)
      if player.dead then return end
      local targets = table.map(table.filter(room.alive_players, function (p)
        return p:getHandcardNum() > player:getHandcardNum()
      end), Util.IdMapper)
      if #targets == 0 then return end
      local target_ids = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#jichun-discard:::" .. tostring(n),
        skill_name = jichun.name,
      })
      local to = room:getPlayerById(target_ids[1])
      local cards = room:askToChooseCards(player, {
        target = to,
        min = 1,
        max = n,
        flag = "hej",
        reason = jichun.name,
      })
      if #cards > 0 then
        room:throwCard(cards, jichun.name, to, player)
      end
    end
  end,

  on_lose = function (skill, player)
    local room = player.room
    room:setPlayerMark(player, "jichun1-phase", 0)
    room:setPlayerMark(player, "jichun2-phase", 0)
  end,
})

return jichun
