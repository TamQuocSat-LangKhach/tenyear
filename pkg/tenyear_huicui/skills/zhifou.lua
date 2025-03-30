local zhifou = fk.CreateSkill {
  name = "zhifou",
}

Fk:loadTranslationTable{
  ["zhifou"] = "知否",
  [":zhifou"] = "当你使用牌结算结束后，你可以移去至少X张“翼”（X为你本回合发动此技能的次数）并令一名角色执行一项（每回合每项限一次）："..
  "1.将一张牌置入“翼”；2.弃置两张牌；3.失去1点体力。",

  ["#zhifou-invoke"] = "知否：你可以移去至少 %arg 张“翼”，然后令一名角色执行一项",
  ["#zhifou-choose"] = "知否：选择一名角色，令其执行一项",
  ["zhifou_put"] = "将一张牌置入“翼”",
  ["zhifou_discard"] = "弃置两张牌",
  ["loseHp"] = "失去1点体力",
  ["#zhifou-ask"] = "知否：你须将一张牌置为 %src 的“翼”",

  ["$zhifou1"] = "满怀相思意，念君君可知？",
  ["$zhifou2"] = "世有人万万，相知无二三。",
}

zhifou:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhifou.name) and
      #player:getTableMark("zhifou-turn") < 3 and
      #player:getPile("lingxi_wing") > player:usedSkillTimes(zhifou.name, Player.HistoryTurn)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = player:usedSkillTimes(zhifou.name, Player.HistoryTurn) + 1
    local cards = room:askToCards(player, {
      min_num = x,
      max_num = 999,
      include_equip = false,
      pattern = ".|.|.|lingxi_wing",
      prompt = "#zhifou-invoke:::" .. x,
      skill_name = zhifou.name,
      cancelable = true,
      expand_pile = "lingxi_wing",
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
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "zhifou_active",
      prompt = "#zhifou-choose",
      cancelable = false,
      no_indicate = false,
    })
    if not (success and dat) then
      dat = {targets = table.random(room.alive_players, 1)}
      local all_choices = {"zhifou_put", "zhifou_discard", "loseHp"}
      dat.interaction = table.find(all_choices, function(choice)
        return not table.contains(player:getTableMark("zhifou-turn"), choice)
      end)
    end
    local to = dat.targets[1]
    local choice = dat.interaction
    room:addTableMark(player, "zhifou-turn", choice)
    if choice == "zhifou_put" then
      if player.dead or to:isNude() then return end
      local card = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        prompt = "#zhifou-ask:"..player.id,
        skill_name = zhifou.name,
        cancelable = false,
      })
      player:addToPile("lingxi_wing", card, true, zhifou.name)
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
