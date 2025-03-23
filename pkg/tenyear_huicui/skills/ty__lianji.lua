local ty__lianji = fk.CreateSkill {
  name = "ty__lianji"
}

Fk:loadTranslationTable{
  ['ty__lianji'] = '连计',
  ['#ty__lianji'] = '连计：弃置一张手牌，令一名角色使用牌堆中的一张武器牌并使用【杀】',
  ['#ty__lianji-slash'] = '连计：你需使用一张【杀】，否则 %src 视为对你使用【杀】',
  ['#ty__lianji-give'] = '连计：你需将武器交给其中一名目标角色',
  [':ty__lianji'] = '出牌阶段限一次，你可以弃置一张手牌并选择一名其他角色，令其使用牌堆中的一张武器牌。然后该角色选择一项：1.对除你以外的一名角色使用一张【杀】，并将武器牌交给其中一名目标角色；2.视为你对其使用一张【杀】，并将武器牌交给你。',
  ['$ty__lianji1'] = '连环相扣，周密不失。',
  ['$ty__lianji2'] = '切记，此计连不可断。',
}

ty__lianji:addEffect('active', {
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt= "#ty__lianji",
  can_use = function(self, player)
    return player:usedSkillTimes(ty__lianji.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select.id ~= player.id
  end,
  on_use = function(self, room, effect, event)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, ty__lianji.name, player, player)
    local cards = {}
    for i = 1, #room.draw_pile do
      local card = Fk:getCardById(room.draw_pile[i])
      if card.sub_type == Card.SubtypeWeapon then
        table.insertIfNeed(cards, room.draw_pile[i])
      end
    end
    if #cards > 0 then
      local card = Fk:getCardById(table.random(cards))
      if card.name == "qinggang_sword" then
        for _, id in ipairs(Fk:getAllCardIds()) do
          if Fk:getCardById(id).name == "seven_stars_sword" then
            card = Fk:getCardById(id)
            room:setCardMark(card, MarkEnum.DestructIntoDiscard, 1)
            break
          end
        end
      end
      if not target:isProhibited(target, card) then
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = card,
        })
      end
    end
    if target.dead then return end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local use = room:askToUseCard(target, {
      pattern = "slash",
      prompt = "#ty__lianji-slash:"..player.id,
      cancelable = true,
      extra_data = {exclusive_targets = targets},
    })
    if use then
      room:setPlayerMark(player, "ty__lianji1", 1)
      use.extraUse = true
      room:useCard(use)
      if not target.dead and target:getEquipment(Card.SubtypeWeapon) then
        local to = table.filter(TargetGroup:getRealTargets(use.tos), function(id) return not room:getPlayerById(id).dead end)
        if #to == 0 then return end
        if #to > 1 then
          to = room:askToChoosePlayers(target, {
            targets = to,
            min_num = 1,
            max_num = 1,
            prompt = "#ty__lianji-give",
            skill_name = ty__lianji.name,
          })
        end
        local toPlayer = room:getPlayerById(to[1])
        room:moveCardTo(Fk:getCardById(target:getEquipment(Card.SubtypeWeapon)),
          Card.PlayerHand, toPlayer, fk.ReasonGive, ty__lianji.name, nil, true, target.id)
      end
    else
      room:setPlayerMark(player, "ty__lianji2", 1)
      room:useVirtualCard("slash", nil, player, target, ty__lianji.name, true)
      if not player.dead and not target.dead and target:getEquipment(Card.SubtypeWeapon) then
        room:moveCardTo(Fk:getCardById(target:getEquipment(Card.SubtypeWeapon)),
          Card.PlayerHand, player, fk.ReasonGive, ty__lianji.name, nil, true, target.id)
      end
    end
  end,
})

return ty__lianji
