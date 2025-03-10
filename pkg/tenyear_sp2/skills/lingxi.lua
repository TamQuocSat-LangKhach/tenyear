local lingxi = fk.CreateSkill {
  name = "lingxi"
}

Fk:loadTranslationTable{
  ['lingxi'] = '灵犀',
  ['lingxi_wing'] = '翼',
  ['#lingxi-put'] = '灵犀：将至多 %arg 张牌置入“翼”',
  [':lingxi'] = '出牌阶段开始时或结束时，你可以将至多体力上限张牌置于你的武将牌上，称为“翼”。当你的“翼”被移去后，你将手牌摸至或弃置至“翼”包含的花色数的两倍。',
  ['$lingxi1'] = '灵犀渡清潭，涟漪扰我心。',
  ['$lingxi2'] = '心有玲珑曲，万籁皆空灵。',
}

lingxi:addEffect(fk.EventPhaseStart, {
  derived_piles = "lingxi_wing",
  mute = true,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(lingxi.name) then return false end
    return target == player and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local x = player.maxHp
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = x,
      include_equip = true,
      skill_name = lingxi.name,
      cancelable = true,
      prompt = "#lingxi-put:::"..x
    })
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(lingxi.name)
    room:notifySkillInvoked(player, lingxi.name, "special")
    player:addToPile("lingxi_wing", event:getCostData(self), true, lingxi.name)
  end,
})

lingxi:addEffect(fk.EventPhaseEnd, {
  derived_piles = "lingxi_wing",
  mute = true,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(lingxi.name) then return false end
    return target == player and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local x = player.maxHp
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = x,
      include_equip = true,
      skill_name = lingxi.name,
      cancelable = true,
      prompt = "#lingxi-put:::"..x
    })
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(lingxi.name)
    room:notifySkillInvoked(player, lingxi.name, "special")
    player:addToPile("lingxi_wing", event:getCostData(self), true, lingxi.name)
  end,
})

lingxi:addEffect(fk.AfterCardsMove, {
  derived_piles = "lingxi_wing",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(lingxi.name) then return false end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromSpecialName == "lingxi_wing" then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(lingxi.name)
    local suits = {}
    for _, id in ipairs(player:getPile("lingxi_wing")) do
      local suit = Fk:getCardById(id).suit
      table.insertIfNeed(suits, suit)
    end
    local x = (2 * #suits) - player:getHandcardNum()
    if x > 0 then
      room:notifySkillInvoked(player, lingxi.name, "drawcard")
      player:drawCards(x, lingxi.name)
    elseif x < 0 then
      room:notifySkillInvoked(player, lingxi.name, "negative")
      room:askToDiscard(player, {
        min_num = -x,
        max_num = -x,
        include_equip = false,
        skill_name = lingxi.name,
        cancelable = false
      })
    end
  end,
})

return lingxi
