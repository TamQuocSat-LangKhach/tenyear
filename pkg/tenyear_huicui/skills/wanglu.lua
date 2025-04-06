local wanglu = fk.CreateSkill {
  name = "wanglu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["wanglu"] = "望橹",
  [":wanglu"] = "锁定技，准备阶段，你将<a href=':siege_engine'>【大攻车】</a>置入你的装备区，若你的装备区内已有【大攻车】，"..
  "则改为执行一个额外的出牌阶段。",

  ["$wanglu1"] = "大攻车前，坚城弗当。",
  ["$wanglu2"] = "大攻既作，天下可望！",
}

local U = require "packages/utility/utility"

wanglu:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wanglu.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id)
      return Fk:getCardById(id).name == "siege_engine"
    end) then
      player:gainAnExtraPhase(Player.Play, wanglu.name)
    else
      local id = table.find(U.prepareDeriveCards(room, {{ "siege_engine", Card.Spade, 9 }}, wanglu.name), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if id then
        room:setCardMark(Fk:getCardById(id), MarkEnum.DestructOutEquip, 1)
        room:moveCardIntoEquip(player, id, wanglu.name, true, player)
      end
    end
  end,
})

return wanglu
