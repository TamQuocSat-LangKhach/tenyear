local fazhu = fk.CreateSkill {
  name = "fazhu",
}

Fk:loadTranslationTable{
  ["fazhu"] = "筏铸",
  [":fazhu"] = "准备阶段，你可以重铸你区域内任意张非伤害牌，然后将因此获得的牌交给至多等量名角色各一张，以此法获得牌的角色可以依次"..
  "使用一张【杀】（无距离限制）。",

  ["#fazhu-invoke"] = "筏铸：你可以重铸任意张非伤害牌，将获得的牌分配给任意角色",
  ["#fazhu-give"] = "筏铸：你可以将这些牌分配给任意角色各一张，获得牌的角色可以使用一张无距离限制的【杀】",
  ["#fazhu-use"] = "筏铸：你可以使用一张【杀】（无距离限制）",

  ["$fazhu1"] = "击风雨于共济，逆流亦溯千帆。",
  ["$fazhu2"] = "泰山轻于大义，每思志士、何惧临渊。",
}

fazhu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fazhu.name) and player.phase == Player.Start and
      not player:isAllNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("hej"), function(id)
      return not Fk:getCardById(id).is_damage_card
    end)
    if #cards > 0 then
      cards = room:askToCards(player, {
        min_num = 1,
        max_num = 999,
        include_equip = true,
        skill_name = fazhu.name,
        pattern = tostring(Exppattern{ id = cards }),
        prompt = "#fazhu-invoke",
        cancelable = true,
        expand_pile = player:getCardIds("j"),
      })
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    else
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = fazhu.name,
        pattern = "false",
        prompt = "#fazhu-invoke",
        cancelable = true,
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    if #cards == 0 then return end
    local to_give = room:recastCard(cards, player, fazhu.name)
    if player.dead or player:isKongcheng() then return end
    to_give = table.filter(to_give, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
    if #to_give == 0 then return end
    local result = room:askToYiji(player, {
      cards = to_give,
      targets = room.alive_players,
      skill_name = fazhu.name,
      min_num = 0,
      max_num = #to_give,
      prompt = "#fazhu-give",
      single_max = 1,
    })
    local targets = {}
    if table.find(to_give, function (id)
      return table.contains(player:getCardIds("h"), id)
    end) then
      table.insert(targets, player)
    end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #result[p.id] > 0 then
        table.insert(targets, p)
      end
    end
    for _, p in ipairs(targets) do
      if not p.dead then
        local use = room:askToUseCard(p, {
          pattern = "slash",
          skill_name = "slash",
          prompt = "#fazhu-use",
          cancelable = true,
          extra_data = {
            bypass_distances = true,
            bypass_times = true,
          },
        })
        if use then
          use.extraUse = true
          room:useCard(use)
        end
      end
    end
  end,
})

return fazhu
