local zifu = fk.CreateSkill {
  name = "ty__zifu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__zifu"] = "自缚",
  [":ty__zifu"] = "锁定技，出牌阶段开始时，你将手牌摸至体力上限（至多摸至5张）。若你因此摸牌，你保留手牌中每种牌名的牌各一张，弃置其余的牌。",

  ["#ty__zifu-ask"] = "自缚：选择每种牌名的牌各一张保留，弃置其余的牌",

  ["$ty__zifu1"] = "今势穷，吾自缚于斯，请太傅发落。",
  ["$ty__zifu2"] = "凌有罪，公劳师而来，唯系首待斩。",
}

zifu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zifu.name) and player.phase == Player.Play and
      player:getHandcardNum() < math.min(5, player.maxHp)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(math.min(5, player.maxHp) - player:getHandcardNum(), zifu.name)
    if player.dead then return false end
    local cards = {}
    local names = {}
    for _, id in ipairs(player:getCardIds("h")) do
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
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty__zifu_active",
      prompt = "#ty__zifu-ask",
      cancelable = false,
    })
    if success and dat then
      cards = table.filter(player:getCardIds("h"), function (id)
        return not (table.contains(dat.cards, id) or player:prohibitDiscard(id))
      end)
    end
    if #cards > 0 then
      room:throwCard(cards, zifu.name, player, player)
    end
  end,
})

return zifu
