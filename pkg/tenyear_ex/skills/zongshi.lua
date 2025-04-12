local zongshi = fk.CreateSkill {
  name = "ty_ex__zongshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty_ex__zongshi"] = "宗室",
  [":ty_ex__zongshi"] = "锁定技，你的手牌上限+X（X为全场势力数）。你的回合外，若你的手牌数不小于手牌上限，延时锦囊牌和无色牌对你无效。",

  ["$ty_ex__zongshi1"] = "汉室江山，气数未尽！",
  ["$ty_ex__zongshi2"] = "我刘氏一族，皆海内之俊杰也！",
}

zongshi:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zongshi.name) and player.room.current ~= player and
      (data.card.color == Card.NoColor or data.card.sub_type == Card.SubtypeDelayedTrick) and
      player:getHandcardNum() >= player:getMaxCards()
  end,
  on_use = function(self, event, target, player, data)
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)
  end
})

zongshi:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(zongshi.name) then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms
    end
  end,
})

return zongshi
