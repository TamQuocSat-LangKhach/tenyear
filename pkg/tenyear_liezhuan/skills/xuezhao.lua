local xuezhao = fk.CreateSkill {
  name = "xuezhao"
}

Fk:loadTranslationTable{
  ['xuezhao'] = '血诏',
  ['#xuezhao'] = '血诏：弃一张手牌，令任意角色选择交给你一张牌或其本阶段不能响应你使用的牌',
  ['#xuezhao-give'] = '血诏：交出一张牌并摸一张牌使 %src 使用【杀】次数上限+1；或本阶段不能响应其使用的牌',
  [':xuezhao'] = '出牌阶段限一次，你可以弃置一张手牌并选择至多X名其他角色（X为你的体力上限），然后令这些角色依次选择是否交给你一张牌，若选择是，该角色摸一张牌且你本阶段使用【杀】的次数上限+1；若选择否，该角色本阶段不能响应你使用的牌。若没有角色交给你牌，你将手牌摸至体力上限。',
  ['$xuezhao1'] = '奉旨行事，莫敢不从？',
  ['$xuezhao2'] = '衣带密诏，当诛曹公！',
}

xuezhao:addEffect('active', {
  anim_type = "offensive",
  card_num = 1,
  min_target_num = 1,
  max_target_num = function(player)
    return player.maxHp
  end,
  prompt = "#xuezhao",
  can_use = function(self, player)
    return player:usedSkillTimes(xuezhao.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player.player_cards[Player.Hand], to_select)
      and not self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected < player.maxHp and to_select ~= player.id and #cards == 1
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    room:throwCard(effect.cards, xuezhao.name, player, player)
    local yes = true
    for _, to in ipairs(effect.tos) do
      if player.dead then return end
      local p = room:getPlayerById(to)
      if not p.dead then
        local cards = {}
        if not p:isNude() then
          cards = room:askToCards(p, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = xuezhao.name,
            cancelable = true,
            prompt = "#xuezhao-give:"..player.id
          })
        end
        if #cards > 0 then
          yes = false
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, xuezhao.name, "", false, p.id)
          if not p.dead then
            p:drawCards(1, xuezhao.name)
          end
          room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", 1)
        else
          room:addTableMark(player, "xuezhao-phase", p.id)
        end
      end
    end
    if yes and player:getHandcardNum() < player.maxHp and not player.dead then
      player:drawCards(player.maxHp - player:getHandcardNum(), xuezhao.name)
    end
  end,
})

xuezhao:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and #player:getTableMark("xuezhao-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertTableIfNeed(data.disresponsiveList, player:getTableMark("xuezhao-phase"))
  end,
})

return xuezhao
