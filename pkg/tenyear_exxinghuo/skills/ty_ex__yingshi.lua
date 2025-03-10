local ty_ex__yingshi = fk.CreateSkill {
  name = "ty_ex__yingshi"
}

Fk:loadTranslationTable{
  ['ty_ex__yingshi'] = '应势',
  ['ty_ex__yingshi_active'] = '应势',
  ['#ty_ex__yingshi-invoke'] = '应势：展示一张手牌并选择两名角色，后者可以对前者使用一张【杀】',
  ['#ty_ex__yingshi-slash'] = '应势：你可以对 %dest 使用一张【杀】，然后获得展示牌',
  [':ty_ex__yingshi'] = '出牌阶段开始时，你可以展示一张手牌并选择一名其他角色，然后令另一名角色对其使用一张【杀】（无距离限制）。若其使用了【杀】，则其获得你展示的牌；若此【杀】造成了伤害，则其再获得牌堆中所有与展示牌花色点数均相同的牌。',
  ['$ty_ex__yingshi1'] = '大势如潮，可应之而不可逆之。',
  ['$ty_ex__yingshi2'] = '应大势伐贼者，当以重酬彰之。',
}

ty_ex__yingshi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty_ex__yingshi.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__yingshi_active",
      prompt = "#ty_ex__yingshi-invoke",
      cancelable = true
    })
    if success then
      event:setCostData(self, dat)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local target1 = room:getPlayerById(event:getCostData(self).targets[1])
    local target2 = room:getPlayerById(event:getCostData(self).targets[2])
    local id = event:getCostData(self).cards[1]
    local card_info = {Fk:getCardById(id):getSuitString(), Fk:getCardById(id).number}
    player:showCards({id})
    if target1.dead or target2.dead then return end
    local use = room:askToUseCard(target2, {
      skill_name = "ty_ex__yingshi",
      pattern = "slash",
      prompt = "#ty_ex__yingshi-slash::" .. target1.id,
      cancelable = true,
      extra_data = {must_targets = {target1.id}, bypass_distances = true, bypass_times = true}
    })
    if use then
      use.extraUse = true
      room:useCard(use)
      if not target2.dead and (table.contains(player:getCardIds("he"), id) or room:getCardArea(id) == Card.DiscardPile) then
        room:moveCardTo(Fk:getCardById(id), Card.PlayerHand, target2, fk.ReasonPrey, ty_ex__yingshi.name, nil, true, target2.id)
      end
      if not target2.dead and use.damageDealt and card_info[1] ~= "nosuit" then
        local cards = room:getCardsFromPileByRule(".|" .. card_info[2] .. "|" .. card_info[1], 999)
        if #cards > 0 then
          room:moveCards({
            ids = cards,
            to = target2.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonPrey,
            proposer = target2.id,
            skillName = ty_ex__yingshi.name,
          })
        end
      end
    end
  end,
})

return ty_ex__yingshi
