local jingyin = fk.CreateSkill {
  name = "jingyin"
}

Fk:loadTranslationTable{
  ['jingyin'] = '经音',
  ['#jingyin-card'] = '是否发动 经音，令一名角色获得%arg（其使用时无次数限制）',
  ['@@jingyin-inhand'] = '经音',
  [':jingyin'] = '每回合限一次，当一名角色于其回合外使用的【杀】移至弃牌堆后，你可以令其以外的一名角色获得此牌，以此法得到的牌被使用时无次数限制。',
  ['$jingyin1'] = '金柝越关山，唯送君于南。',
  ['$jingyin2'] = '燕燕于飞，寒江照孤影。',
}

jingyin:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, player, data)
    if not player:hasSkill(jingyin.name) or player:usedSkillTimes(jingyin.name) > 0 then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    if parent_event ~= nil and parent_event.event == GameEvent.UseCard then
      local parent_data = parent_event.data[1]
      if parent_data.from and parent_data.from ~= room.current.id and parent_data.card.trueName == "slash" then
        local card_ids = room:getSubcardsByRule(parent_data.card)
        if #card_ids == 0 then return false end
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonUse then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.Processing and room:getCardArea(info.cardId) == Card.DiscardPile then
                if not table.removeOne(card_ids, info.cardId) then
                  return false
                end
              end
            end
          end
        end
        if #card_ids == 0 then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, player, data)
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, false)
    if use_event == nil then return false end
    local targets = table.map(room.alive_players, Util.IdMapper)
    table.removeOne(targets, use_event.data[1].from)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = jingyin.name,
      cancelable = true
    }, "#jingyin-card:::"..use_event.data[1].card:toLogString())
    if #to > 0 then
      event:setCostData(skill, {to[1], room:getSubcardsByRule(use_event.data[1].card)})
      return true
    end
  end,
  on_use = function(self, event, player, data)
    local cost_data = event:getCostData(skill)
    player.room:moveCardTo(cost_data[2], Card.PlayerHand, cost_data[1], fk.ReasonGive, jingyin.name, "", true, player.id, "@@jingyin-inhand")
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and not data.card:isVirtual() and data.card:getMark("@@jingyin-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

local jingyin_targetmod = fk.CreateTargetModSkill{
  name = "#jingyin_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and card:getMark("@@jingyin-inhand") > 0
  end,
}

jingyin:addRelatedSkill(jingyin_targetmod)

return jingyin
