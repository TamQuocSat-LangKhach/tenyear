local sushou = fk.CreateSkill {
  name = "sushou"
}

Fk:loadTranslationTable{
  ['sushou'] = '夙守',
  ['#sushou-invoke'] = '你可以对%dest发动 夙守',
  ['#sushou-exchange'] = '夙守：选择要交换你与%dest的至多%arg张手牌',
  [':sushou'] = '一名角色的出牌阶段开始时，若其手牌数是全场唯一最多的，你可以失去1点体力并摸X张牌。若此时不是你的回合内，你观看当前回合角色一半数量的手牌（向下取整），你可以用至多X张手牌替换其中等量的牌。（X为你已损失的体力值）',
  ['$sushou1'] = '敌众我寡，怎可少谋？',
  ['$sushou2'] = '临城据守，当出奇计。',
}

sushou:addEffect(fk.EventPhaseStart, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(sushou.name) and target.phase == Player.Play and player.hp > 0 and not target.dead and
      table.every(player.room.alive_players, function (p)
        return p == target or p:getHandcardNum() < target:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {skill_name = sushou.name, prompt = "#sushou-invoke::" .. target.id}) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, sushou.name)
    if player.dead then return false end
    local x = player:getLostHp()
    if x > 0 then
      room:drawCards(player, x, sushou.name)
    end
    if player == target then return false end
    local cards = target:getCardIds(Player.Hand)
    if #cards < 2 then return false end
    cards = table.random(cards, #cards // 2)
    local handcards = player:getCardIds(Player.Hand)
    cards = U.askToExchange(player, {
      piles = {handcards},
      piles_name = {"needhand"},
      skill_name = "#sushou-exchange::" .. target.id .. ":" .. tostring(x),
      top_limit = {x}
    }, cards)
    if #cards == 0 then return false end
    handcards = table.filter(cards, function (id)
      return table.contains(handcards, id)
    end)
    cards = table.filter(cards, function (id)
      return not table.contains(handcards, id)
    end)
    U.swapCards(room, player, player, target, handcards, cards, sushou.name)
  end,
})

return sushou
