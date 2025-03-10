local ty__zifu = fk.CreateSkill {
  name = "ty__zifu"
}

Fk:loadTranslationTable{
  ['ty__zifu'] = '自缚',
  ['ty__zifu_filter'] = '自缚',
  ['#ty__zifu-select'] = '自缚：选择每种牌名的牌各一张保留，弃置其余的牌',
  [':ty__zifu'] = '锁定技，出牌阶段开始时，你将手牌摸至体力上限（至多摸至5张）。若你因此摸牌，你保留手牌中每种牌名的牌各一张，弃置其余的牌。',
  ['$ty__zifu1'] = '今势穷，吾自缚于斯，请太傅发落。',
  ['$ty__zifu2'] = '凌有罪，公劳师而来，唯系首待斩。',
}

ty__zifu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty__zifu.name) and player.phase == Player.Play and
      player:getHandcardNum() < math.min(5, player.maxHp)
  end,
  on_use = function(self, event, target, player)
    player:drawCards(math.min(5, player.maxHp)-player:getHandcardNum(), ty__zifu.name)
    if player.dead then return false end
    local cards = {}
    local names = {}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      local name = card.trueName
      if table.contains(names, name) then
        if not player:prohibitDiscard(card) then
          table.insert(cards, id)
        end
      else
        table.insert(names, name)
      end
    end
    if #names == player:getHandcardNum() then return false end
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty__zifu_filter",
      prompt = "#ty__zifu-select",
      cancelable = false,
    })
    if success then
      cards = table.filter(player:getCardIds(Player.Hand), function (id)
        return not (table.contains(dat.cards, id) or player:prohibitDiscard(Fk:getCardById(id)))
      end)
    end
    if #cards > 0 then
      room:throwCard(cards, ty__zifu.name, player, player)
    end
  end,
})

return ty__zifu
