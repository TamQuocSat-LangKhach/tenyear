local xiaojun = fk.CreateSkill {
  name = "xiaojun"
}

Fk:loadTranslationTable{
  ['xiaojun'] = '骁隽',
  ['#xiaojun-invoke'] = '骁隽：你可以弃置 %dest 一半手牌（%arg张），若其中有%arg2牌，你弃置一张手牌',
  [':xiaojun'] = '你使用牌指定其他角色为唯一目标后，你可以弃置其一半手牌（向下取整）。若其中有与你指定其为目标的牌花色相同的牌，你弃置一张手牌。',
  ['$xiaojun1'] = '骁锐敢斗，威震江夏！',
  ['$xiaojun2'] = '得隽为雄，气贯大江！',
}

xiaojun:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xiaojun.name) and data.to ~= player.id then
      local to = player.room:getPlayerById(data.to)
      return not to.dead and to:getHandcardNum() > 1 and U.isOnlyTarget(to, data, event)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    return room:askToSkillInvoke(player, {
      skill_name = xiaojun.name,
      prompt = "#xiaojun-invoke::"..data.to..":"..tostring(to:getHandcardNum() // 2)..":"..data.card:getSuitString()
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local n = to:getHandcardNum() // 2
    local cards = room:askToChooseCards(player, {
      min = n,
      max = n,
      flag = "h",
      skill_name = xiaojun.name,
      target = to
    })
    room:throwCard(cards, xiaojun.name, to, player)
    if not player:isKongcheng() and data.card ~= Card.NoSuit and table.find(cards, function(id)
      return Fk:getCardById(id).suit == data.card.suit end) then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = xiaojun.name,
        cancelable = false
      })
    end
  end,
})

return xiaojun
