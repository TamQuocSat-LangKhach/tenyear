local zhifou = fk.CreateSkill {
  name = "zhifou"
}

Fk:loadTranslationTable{
  ['zhifou'] = '知否',
  ['lingxi_wing'] = '翼',
  ['#zhifou-invoke'] = '知否：你可以移去至少 %arg 张“翼”',
  ['zhifou_active'] = '知否',
  ['#zhifou-active'] = '知否：选择一名角色，令其执行一项',
  ['zhifou_put'] = '将一张牌置入“翼”',
  ['zhifou_discard'] = '弃置两张牌',
  ['zhifou_losehp'] = '失去1点体力',
  ['#zhifou-put'] = '知否：你须将一张牌置入“翼”中',
  [':zhifou'] = '当你使用牌结算结束后，你可以移去至少X张“翼”（X为你本回合发动此技能的次数），若如此做，你选择一名角色并选择一项（每回合每项限一次），令其执行之：1.将一张牌置入“翼”；2.弃置两张牌；3.失去1点体力。',
  ['$zhifou1'] = '满怀相思意，念君君可知？',
  ['$zhifou2'] = '世有人万万，相知无二三。',
}

zhifou:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhifou.name) and #player:getTableMark("zhifou-turn") < 3
      and #player:getPile("lingxi_wing") > player:usedSkillTimes(zhifou.name, Player.HistoryTurn)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = player:usedSkillTimes(zhifou.name, Player.HistoryTurn) + 1
    local cards = room:askToCards(player, {
      min_num = x,
      max_num = 9999,
      include_equip = false,
      pattern = ".|.|.|lingxi_wing",
      prompt = "#zhifou-invoke:::" .. x,
      skill_name = zhifou.name
    })
    if #cards >= x then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(self).cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, zhifou.name)
    if player.dead then return end
    local _, dat = room:askToUseActiveSkill(player, {
      skill_name = "zhifou_active",
      prompt = "#zhifou-active",
      cancelable = false
    })
    if not dat then
      dat = {targets = {table.random(room.alive_players).id}}
      local all_choices = {"zhifou_put", "zhifou_discard", "zhifou_losehp"}
      dat.interaction = table.find(all_choices, function(choice)
        return not table.contains(player:getTableMark("zhifou-turn"), choice)
      end)
    end
    local choice = dat.interaction
    local to = room:getPlayerById(dat.targets[1])
    room:addTableMark(player, "zhifou-turn", choice)
    if choice == "zhifou_put" then
      if player.dead or to:isNude() then return end
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        pattern = ".",
        prompt = "#zhifou-put",
        skill_name = zhifou.name
      })
      player:addToPile("lingxi_wing", card[1], true, zhifou.name)
    elseif choice == "zhifou_discard" then
      room:askToDiscard(to, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = zhifou.name,
        cancelable = false
      })
    else
      room:loseHp(to, 1, zhifou.name)
    end
  end,
})

return zhifou
