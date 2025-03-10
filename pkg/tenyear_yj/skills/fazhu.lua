local fazhu = fk.CreateSkill {
  name = "fazhu"
}

Fk:loadTranslationTable{
  ['fazhu'] = '筏铸',
  ['fazhu_active'] = '筏铸',
  ['#fazhu-invoke'] = '筏铸：你可以重铸任意张非伤害牌，将获得的牌分配给任意角色',
  ['#fazhu-give'] = '筏铸：你可以将这些牌分配给任意角色各一张，获得牌的角色可以使用一张无距离限制的【杀】',
  ['#fazhu-use'] = '筏铸：你可以使用一张【杀】（无距离限制）',
  [':fazhu'] = '准备阶段，你可以重铸你区域内任意张非伤害牌，然后将因此获得的牌交给至多等量名角色各一张，以此法获得牌的角色可以依次使用一张【杀】（无距离限制）。',
  ['$fazhu1'] = '击风雨于共济，逆流亦溯千帆。',
  ['$fazhu2'] = '泰山轻于大义，每思志士、何惧临渊。',
}

fazhu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawCard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(fazhu) and player.phase == Player.Start and
      table.find(player:getCardIds("hej"), function(id)
        return not Fk:getCardById(id).is_damage_card
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "fazhu_cards", player:getCardIds("j"))
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "fazhu_active",
      prompt = "#fazhu-invoke",
      cancelable = true,
    })
    if success then
      event:setCostData(self, dat)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = event:getCostData(self).cards
    if #cards == 0 then return end
    local to_give = room:recastCard(cards, player, fazhu.name)
    to_give = table.filter(to_give, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
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
          extra_data = {bypass_distances = true, bypass_times = true},
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
