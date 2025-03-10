local pianchong = fk.CreateSkill {
  name = "pianchong"
}

Fk:loadTranslationTable{
  ['pianchong'] = '偏宠',
  ['#pianchong-choice'] = '偏宠：选择一种颜色，失去此颜色的牌时，摸另一种颜色的牌',
  ['@pianchong'] = '偏宠',
  ['#pianchong_delay'] = '偏宠',
  [':pianchong'] = '摸牌阶段，你可以改为从牌堆获得红牌和黑牌各一张，然后选择一项直到你的下回合开始：1.你每失去一张红色牌时摸一张黑色牌，2.你每失去一张黑色牌时摸一张红色牌。',
  ['$pianchong1'] = '得陛下怜爱，恩宠不衰。',
  ['$pianchong2'] = '谬蒙圣恩，光授殊宠。',
}

pianchong:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(pianchong) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = {}
    local color = Card.NoColor
    for _, id in ipairs(room.draw_pile) do
      local _color = Fk:getCardById(id).color
      if _color ~= color and _color ~= Card.NoColor then
        color = _color
        table.insert(cards, id)
        if #cards == 2 then break end
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = pianchong.name,
        moveVisible = true,
      })
    end
    local choice = room:askToChoice(player, {
      choices = {"red", "black"},
      skill_name = pianchong.name,
      prompt = "#pianchong-choice"
    })
    room:addTableMarkIfNeed(player, "@pianchong", choice)
    return true
  end,

  can_refresh = function(self, event, target, player)
    return target == player and player:getMark("@pianchong") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, "@pianchong", 0)
  end,
})

local pianchong_delay = fk.CreateTriggerSkill{
  name = "#pianchong_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player)
    if player.dead then return false end
    local colors = player:getTableMark("@pianchong")
    if #colors == 0 then return false end
    local x, y = 0, 0
    local color
    for _, move in ipairs(event.data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            color = Fk:getCardById(info.cardId).color
            if color == Card.Red then
              x = x + 1
            elseif color == Card.Black then
              y = y + 1
            end
          end
        end
      end
    end
    if not table.contains(colors, "red") then
      x = 0
    end
    if not table.contains(colors, "black") then
      y = 0
    end
    if x > 0 or y > 0 then
      event:setCostData(skill, {x, y})
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    local data = event:getCostData(skill)
    local x, y = table.unpack(data)
    local color
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      color = Fk:getCardById(id).color
      if color == Card.Black then
        if x > 0 then
          x = x - 1
          table.insert(cards, id)
        end
      elseif color == Card.Red then
        if y > 0 then
          y = y - 1
          table.insert(cards, id)
        end
      end
      if x == 0 and y == 0 then break end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = pianchong.name,
        moveVisible = true,
      })
    end
  end,
}

pianchong:addRelatedSkill(pianchong_delay)

return pianchong
