local lingxi = fk.CreateSkill {
  name = "lingxi",
}

Fk:loadTranslationTable{
  ["lingxi"] = "灵犀",
  [":lingxi"] = "出牌阶段开始时或结束时，你可以将至多体力上限张牌置于你的武将牌上，称为“翼”。当“翼”被移去后，你将手牌调整至“翼”花色数的两倍。",

  ["lingxi_wing"] = "翼",
  ["#lingxi-ask"] = "灵犀：你可以将至多 %arg 张牌置为“翼”",

  ["$lingxi1"] = "灵犀渡清潭，涟漪扰我心。",
  ["$lingxi2"] = "心有玲珑曲，万籁皆空灵。",
}

local spec = {
  derived_piles = "lingxi_wing",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lingxi.name) and player.phase == Player.Play and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = player.maxHp,
      include_equip = true,
      skill_name = lingxi.name,
      cancelable = true,
      prompt = "#lingxi-ask:::"..player.maxHp,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("lingxi_wing", event:getCostData(self).cards, true, lingxi.name)
  end,
}

lingxi:addEffect(fk.EventPhaseStart, spec)
lingxi:addEffect(fk.EventPhaseEnd, spec)

lingxi:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(lingxi.name) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromSpecialName == "lingxi_wing" then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {}
    for _, id in ipairs(player:getPile("lingxi_wing")) do
      local suit = Fk:getCardById(id).suit
      table.insertIfNeed(suits, suit)
    end
    table.removeOne(suits, Card.NoSuit)
    local x = (2 * #suits) - player:getHandcardNum()
    if x > 0 then
      player:drawCards(x, lingxi.name)
    elseif x < 0 then
      room:askToDiscard(player, {
        min_num = -x,
        max_num = -x,
        include_equip = false,
        skill_name = lingxi.name,
        cancelable = false,
      })
    end
  end,
})

return lingxi
