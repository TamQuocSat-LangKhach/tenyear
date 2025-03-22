local duwang = fk.CreateSkill {
  name = "duwang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["duwang"] = "独往",
  [":duwang"] = "锁定技，游戏开始时，你将牌堆顶五张不为【杀】的牌置于武将牌上，称为“刺”。若你有“刺”，你与其他角色互相计算距离均+1。",

  ["hanlong_ci"] = "刺",

  ["$duwang1"] = "此去，欲诛敌莽、杀单于。",
  ["$duwang2"] = "风萧萧兮易水寒，壮士一去兮不复还！",
}

duwang:addEffect(fk.AfterDrawInitialCards, {
  anim_type = "special",
  derived_piles = "hanlong_ci",
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local n = 0
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id).trueName ~= "slash" then
        table.insert(cards, id)
        n = n + 1
      end
      if n >= 5 then break end
    end
    player:addToPile("hanlong_ci", cards, true, duwang.name)
  end,
})

duwang:addEffect("distance", {
  correct_func = function(self, from, to)
    if #from:getPile("hanlong_ci") > 0 or #to:getPile("hanlong_ci") > 0 then
      return 1
    end
  end,
})

return duwang
