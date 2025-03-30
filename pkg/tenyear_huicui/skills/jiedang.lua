local jiedang = fk.CreateSkill {
  name = "jiedang",
}

Fk:loadTranslationTable{
  ["jiedang"] = "结党",
  [":jiedang"] = "回合开始时，你可以令所有角色将任意张牌置于你的武将牌上，因此失去牌的角色摸一张牌。你在以下时机须移去武将牌上一种类别的牌并"..
  "摸等量的牌：1.进入濒死状态时；2.出牌阶段开始时；3.结束阶段。",

  ["#jiedang-ask"] = "结党：你可以将任意张牌置于 %src 武将牌上，摸一张牌",
  ["jiedang_basic"] = "基本牌（%arg张）",
  ["jiedang_trick"] = "锦囊牌（%arg张）",
  ["jiedang_equip"] = "装备牌（%arg张）",
  ["#jiedang-choice"] = "结党：请移去一种类别的“结党”牌，摸等量的牌",

  ["$jiedang1"] = "我固君子，亦群亦党。",
  ["$jiedang2"] = "众卿拥立，霸当仁不让。",
}

jiedang:addEffect(fk.TurnStart, {
  derived_piles = "jiedang",
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiedang.name) and
      table.find(player.room.alive_players, function (p)
        return not p:isNude()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, room.alive_players)
    for _, p in ipairs(room:getAlivePlayers()) do
      if not player:hasSkill(jiedang.name, true) then return end
      if not p.dead and not p:isNude() then
        local cards = room:askToCards(p, {
          min_num = 1,
          max_num = 999,
          include_equip = true,
          skill_name = jiedang.name,
          cancelable = true,
          prompt = "#jiedang-ask:"..player.id,
        })
        if #cards > 0 then
          player:addToPile(jiedang.name, cards, true, jiedang.name, p)
          if not p.dead then
            p:drawCards(1, jiedang.name)
          end
        end
      end
    end
  end,
})

local spec = {
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.map({Card.TypeBasic, Card.TypeTrick, Card.TypeEquip}, function (t)
      return table.filter(player:getPile("jiedang"), function (id)
        return t == Fk:getCardById(id).type
      end)
    end)
    local all_choices = {
      "jiedang_basic:::"..#cards[1],
      "jiedang_trick:::"..#cards[2],
      "jiedang_equip:::"..#cards[3],
    }
    local choices = {}
    if #cards[1] > 0 then
      table.insert(choices, "jiedang_basic:::"..#cards[1])
    end
    if #cards[2] > 0 then
      table.insert(choices, "jiedang_trick:::"..#cards[2])
    end
    if #cards[3] > 0 then
      table.insert(choices, "jiedang_equip:::"..#cards[3])
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = jiedang.name,
      prompt = "#jiedang-choice"
    })
    local ids = cards[table.indexOf(all_choices, choice)]
    room:moveCardTo(ids, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, jiedang.name, nil, true, player)
    if not player.dead then
      player:drawCards(#ids, jiedang.name)
    end
  end,
}

jiedang:addEffect(fk.EnterDying, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiedang.name) and #player:getPile("jiedang") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = spec.on_use,
})

jiedang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiedang.name) and #player:getPile("jiedang") > 0 and
      (player.phase == Player.Play or player.phase == Player.Finish)
  end,
  on_cost = Util.TrueFunc,
  on_use = spec.on_use,
})

return jiedang
