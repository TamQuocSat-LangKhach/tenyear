local heqia = fk.CreateSkill {
  name = "heqia",
}

Fk:loadTranslationTable{
  ["heqia"] = "和洽",
  [":heqia"] = "出牌阶段开始时，你可以选择一项：1.你交给一名其他角色至少一张牌；2.令一名有手牌的其他角色交给你至少一张牌。然后获得牌的角色"..
  "可以将一张手牌当任意基本牌使用（无距离限制），且此牌目标上限改为X（X为其本次获得的牌数）。",

  ["#heqia-invoke"] = "和洽：交给一名其他角色至少一张牌，或选择一名角色将至少一张牌交给你",
  ["#heqia-give"] = "和洽：交给 %src 至少一张牌",
  ["#heqia-use"] = "和洽：你可以将一张手牌当任意基本牌使用，可以指定%arg个目标",

  ["$heqia1"] = "和洽不基，贵贱无司。",
  ["$heqia2"] = "教化大行，天下和洽。",
}

heqia:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(heqia.name) and player.phase == Player.Play and
      (not player:isNude() or
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "heqia_active",
      prompt = "#heqia-invoke",
      cancelable = true,
      no_indicate = false,
    })
    if success and dat then
      event:setCostData(self, {tos = dat.targets, cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from, to, cards = player, event:getCostData(self).tos[1], event:getCostData(self).cards
    if #cards == 0 then
      from, to = event:getCostData(self).tos[1], player
      cards = room:askToCards(from, {
        min_num = 1,
        max_num = 999,
        include_equip = true,
        skill_name = heqia.name,
        cancelable = false,
        prompt = "#heqia-give:"..player.id,
      })
    end
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, heqia.name, nil, false, from)
    if to.dead or to:isKongcheng() then return end
    local success, dat = room:askToUseActiveSkill(to, {
      skill_name = "heqia_viewas",
      prompt = "#heqia-use:::"..#cards,
      cancelable = true,
      extra_data = {
        heqia_num = #cards,
      }
    })
    if success and dat then
      local card = Fk:cloneCard(dat.interaction)
      card:addSubcards(dat.cards)
      room:useCard{
        from = to,
        tos = dat.targets,
        card = card,
        extraUse = true,
      }
    end
  end,
})

return heqia
