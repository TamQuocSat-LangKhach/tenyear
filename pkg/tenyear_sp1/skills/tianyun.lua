local tianyun = fk.CreateSkill {
  name = "tianyun"
}

Fk:loadTranslationTable{
  ['tianyun'] = '天运',
  ['#tianyun-choose'] = '天运：你可以令一名角色摸%arg张牌，然后你失去1点体力',
  [':tianyun'] = '获得起始手牌后，你再从牌堆中随机获得手牌中没有的花色各一张牌。<br>一名角色的回合开始时，若其座次等于游戏轮数，你可以观看牌堆顶的X张牌，然后以任意顺序置于牌堆顶或牌堆底，若你将所有牌均置于牌堆底，则你可以令一名角色摸X张牌（X为你手牌中的花色数），若如此做，你失去1点体力。',
  ['$tianyun1'] = '天垂象，见吉凶。',
  ['$tianyun2'] = '治历数，知风气。',
}

tianyun:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(tianyun) then return false end
    local suits = {"spade", "heart", "club", "diamond"}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      table.removeOne(suits, Fk:getCardById(id):getSuitString())
    end
    return #suits > 0
  end,
  on_cost = function(self, event, target, player)
    if event == fk.GameStart then
      return true
    elseif event == fk.TurnStart then
      return player.room:askToSkillInvoke(player, { skill_name = tianyun.name })
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local suits = {"spade", "heart", "club", "diamond"}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      table.removeOne(suits, Fk:getCardById(id):getSuitString())
    end
    if event == fk.GameStart then
      local cards = {}
      while #suits > 0 do
        local pattern = table.random(suits)
        table.removeOne(suits, pattern)
        table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
      end
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = tianyun.name,
        })
      end
    elseif event == fk.TurnStart then
      local x = 4 - #suits
      if x == 0 then return false end
      local result = room:askToGuanxing(player, { cards = room:getNCards(x) })
      if #result.top == 0 then
        local targets = player.room:askToChoosePlayers(player, {
          targets = table.map(room.alive_players, Util.IdMapper),
          min_num = 1,
          max_num = 1,
          prompt = "#tianyun-choose:::" .. tostring(x),
          skill_name = tianyun.name,
          cancelable = true
        })
        if #targets > 0 then
          room:drawCards(room:getPlayerById(targets[1]), x, tianyun.name)
          if not player.dead then
            room:loseHp(player, 1, tianyun.name)
          end
        end
      end
    end
  end,
})

tianyun:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(tianyun) then return false end
    return target.seat == player.room:getBanner("RoundCount") and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player)
    if event == fk.GameStart then
      return true
    elseif event == fk.TurnStart then
      return player.room:askToSkillInvoke(player, { skill_name = tianyun.name })
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local suits = {"spade", "heart", "club", "diamond"}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      table.removeOne(suits, Fk:getCardById(id):getSuitString())
    end
    if event == fk.GameStart then
      local cards = {}
      while #suits > 0 do
        local pattern = table.random(suits)
        table.removeOne(suits, pattern)
        table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
      end
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = tianyun.name,
        })
      end
    elseif event == fk.TurnStart then
      local x = 4 - #suits
      if x == 0 then return false end
      local result = room:askToGuanxing(player, { cards = room:getNCards(x) })
      if #result.top == 0 then
        local targets = player.room:askToChoosePlayers(player, {
          targets = table.map(room.alive_players, Util.IdMapper),
          min_num = 1,
          max_num = 1,
          prompt = "#tianyun-choose:::" .. tostring(x),
          skill_name = tianyun.name,
          cancelable = true
        })
        if #targets > 0 then
          room:drawCards(room:getPlayerById(targets[1]), x, tianyun.name)
          if not player.dead then
            room:loseHp(player, 1, tianyun.name)
          end
        end
      end
    end
  end,
})

return tianyun
