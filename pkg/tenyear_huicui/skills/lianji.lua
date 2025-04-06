local lianji = fk.CreateSkill {
  name = "ty__lianji",
}

Fk:loadTranslationTable{
  ["ty__lianji"] = "连计",
  [":ty__lianji"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名其他角色，令其使用牌堆中的一张武器牌。然后该角色选择一项："..
  "1.对除你以外的一名角色使用一张【杀】，并将武器牌交给其中一名目标角色；2.视为你对其使用一张【杀】，并将武器牌交给你。",

  ["#ty__lianji"] = "连计：弃置一张手牌，令一名角色使用牌堆中的一张武器牌并使用【杀】",
  ["#ty__lianji-slash"] = "连计：使用一张【杀】并将武器交给目标角色，否则 %src 视为对你使用【杀】获得你的武器",
  ["#ty__lianji-give"] = "连计：你需将武器交给其中一名目标角色",

  ["$ty__lianji1"] = "连环相扣，周密不失。",
  ["$ty__lianji2"] = "切记，此计连不可断。",
}

lianji:addEffect("active", {
  anim_type = "control",
  prompt= "#ty__lianji",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(lianji.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, lianji.name, player, player)
    if target.dead then return end
    local cards = table.filter(room.draw_pile, function(id)
      return Fk:getCardById(id).sub_type == Card.SubtypeWeapon and
        target:canUseTo(Fk:getCardById(id), target)
    end)
    if #cards > 0 then
      local card = Fk:getCardById(table.random(cards))
      if card.name == "qinggang_sword" then
        room:moveCardTo(card, Card.Void, nil, fk.ReasonJustMove, lianji.name)
        card = room:printCard("seven_stars_sword", Card.Spade, 6)
      end
      if target:canUseTo(card, target) then
        room:useCard{
          from = target,
          tos = {target},
          card = card,
        }
      end
    end
    if target.dead or player.dead then return end
    local use = room:askToUseCard(target, {
      skill_name = lianji.name,
      pattern = "slash",
      prompt = "#ty__lianji-slash:"..player.id,
      extra_data = {
        exclusive_targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        bypass_times = true,
      }
    })
    if use then
      room:setPlayerMark(player, "ty__lianji1", 1)
      use.extraUse = true
      room:useCard(use)
      if not target.dead and #target:getEquipments(Card.SubtypeWeapon) > 0 then
        local to = table.filter(use.tos, function(p)
          return not p.dead
        end)
        if #to == 0 then return end
        if #to > 1 then
          to = room:askToChoosePlayers(target, {
            targets = to,
            min_num = 1,
            max_num = 1,
            prompt = "#ty__lianji-give",
            skill_name = lianji.name,
            cancelable = false,
          })
        end
        room:obtainCard(to[1], target:getEquipments(Card.SubtypeWeapon), true, fk.ReasonGive, target, lianji.name)
      end
    else
      if player.dead then return end
      room:setPlayerMark(player, "ty__lianji2", 1)
      room:useVirtualCard("slash", nil, player, target, lianji.name, true)
      if not player.dead and not target.dead and #target:getEquipments(Card.SubtypeWeapon) > 0 then
        room:obtainCard(player, target:getEquipments(Card.SubtypeWeapon), true, fk.ReasonGive, target, lianji.name)
      end
    end
  end,
})

return lianji
