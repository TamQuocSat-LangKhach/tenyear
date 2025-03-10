local ty_ex__quanji = fk.CreateSkill {
  name = "ty_ex__quanji"
}

Fk:loadTranslationTable{
  ['ty_ex__quanji'] = '权计',
  [':ty_ex__quanji'] = '当你的牌被其他角色获得后或受到1点伤害后，你可以摸一张牌，然后将一张手牌置于武将牌上，称为“权”；每有一张“权”，你的手牌上限便+1。',
  ['$ty_ex__quanji1'] = '操权弄略，舍小利，而谋大计!',
  ['$ty_ex__quanji2'] = '大丈夫行事，岂较一兵一将之得失？',
}

ty_ex__quanji:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(ty_ex__quanji) then return false end
    for _, move in ipairs(data) do
      if move.from == player.id and move.to and move.to ~= player.id and move.moveReason == fk.ReasonPrey then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local x = 1
    skill.cancel_cost = false
    for _ = 1, x do
      if skill.cancel_cost or not player:hasSkill(ty_ex__quanji) then break end
      skill:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {skill_name = ty_ex__quanji.name}, data) then
      return true
    end  
    skill.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, ty_ex__quanji.name)
    if not player:isKongcheng() then
      local card = room:askToCards(player, {min_num = 1, max_num = 1, include_equip = false, skill_name = ty_ex__quanji.name})
      player:addToPile("zhonghui_quan", card[1], true, ty_ex__quanji.name)
    end
  end,
})

ty_ex__quanji:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(ty_ex__quanji) then return false end
    if target == player then
      return true
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local x = data.damage
    skill.cancel_cost = false
    for _ = 1, x do
      if skill.cancel_cost or not player:hasSkill(ty_ex__quanji) then break end
      skill:doCost(event, target, player, data)
    end
  end,
})

local ex__quanji_maxcards = fk.CreateMaxCardsSkill{
  name = "#ex__quanji_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(ty_ex__quanji) then
      return #player:getPile("zhonghui_quan")
    else
      return 0
    end
  end,
}

return ty_ex__quanji
