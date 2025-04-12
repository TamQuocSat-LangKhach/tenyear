local quanji = fk.CreateSkill {
  name = "ty_ex__quanji",
}

Fk:loadTranslationTable{
  ["ty_ex__quanji"] = "权计",
  [":ty_ex__quanji"] = "当你的牌被其他角色获得后或受到1点伤害后，你可以摸一张牌，然后将一张手牌置于武将牌上，称为“权”；每有一张“权”，"..
  "你的手牌上限便+1。",

  ["zhonghui_quan"] = "权",
  ["#quanji-ask"] = "权计：将一张手牌置为“权”",

  ["$ty_ex__quanji1"] = "操权弄略，舍小利，而谋大计！",
  ["$ty_ex__quanji2"] = "大丈夫行事，岂较一兵一将之得失？",
}

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, quanji.name)
    if player:isKongcheng() or player.dead then return end
    local card = room:askToCards(player, {
      skill_name = quanji.name,
      include_equip = false,
      min_num = 1,
      max_num = 1,
      prompt = "#quanji-ask",
      cancelable = false,
    })
    player:addToPile("zhonghui_quan", card, true, quanji.name)
  end,
}

quanji:addEffect(fk.AfterCardsMove, {
  derived_piles = "zhonghui_quan",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(quanji.name) then
      for _, move in ipairs(data) do
        if move.from == player and move.to and move.to ~= player and move.moveReason == fk.ReasonPrey then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = spec.on_use,
})

quanji:addEffect(fk.Damaged, {
  anim_type = "masochism",
  trigger_times = function(self, event, target, player, data)
    return data.damage
  end,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(quanji.name)
  end,
  on_use = spec.on_use,
})

quanji:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(quanji.name) then
      return #player:getPile("zhonghui_quan")
    end
  end,
})

return quanji
