local tianyun = fk.CreateSkill {
  name = "tianyun",
}

Fk:loadTranslationTable{
  ["tianyun"] = "天运",
  [":tianyun"] = "获得起始手牌后，你再从牌堆中随机获得手牌中没有的花色各一张牌。<br>"..
  "一名角色回合开始时，若其座次等于游戏轮数，你可以观看牌堆顶的X张牌，然后以任意顺序置于牌堆顶或牌堆底，若你将所有牌均置于牌堆底，"..
  "则你可以令一名角色摸X张牌（X为你手牌中的花色数），若如此做，你失去1点体力。",

  ["#tianyun-choose"] = "天运：你可以令一名角色摸%arg张牌，然后你失去1点体力",

  ["$tianyun1"] = "天垂象，见吉凶。",
  ["$tianyun2"] = "治历数，知风气。",
}

tianyun:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tianyun.name) then
      local suits = {"spade", "heart", "club", "diamond"}
      for _, id in ipairs(player:getCardIds("h")) do
        table.removeOne(suits, Fk:getCardById(id):getSuitString())
      end
      return #suits > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "heart", "club", "diamond"}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      table.removeOne(suits, Fk:getCardById(id):getSuitString())
    end
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      table.removeOne(suits, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player,
        skillName = tianyun.name,
      })
    end
  end,
})

tianyun:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tianyun.name) and target.seat == player.room:getBanner("RoundCount") and
      not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "heart", "club", "diamond"}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      table.removeOne(suits, Fk:getCardById(id):getSuitString())
    end
    local x = 4 - #suits
    local result = room:askToGuanxing(player, {
      skill_name = tianyun.name,
      cards = room:getNCards(x),
    })
    if #result.top == 0 then
      local to = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#tianyun-choose:::" .. x,
        skill_name = tianyun.name,
        cancelable = true,
      })
      if #to > 0 then
        to[1]:drawCards(x, tianyun.name)
        if not player.dead then
          room:loseHp(player, 1, tianyun.name)
        end
      end
    end
  end,
})

return tianyun
