local ty__longgong = fk.CreateSkill {
  name = "ty__longgong"
}

Fk:loadTranslationTable{
  ['ty__longgong'] = '龙宫',
  ['#longgong-invoke'] = '龙宫：你可以防止你受到的伤害，令 %dest 随机获得一张装备牌。',
  [':ty__longgong'] = '每回合限一次，当你受到伤害时，你可以防止此伤害，改为令伤害来源随机获得牌堆中的一张装备牌。',
  ['$ty__longgong1'] = '停手，大哥！给东西能换条命不？',
  ['$ty__longgong2'] = '冤家宜解不宜结。',
  ['$ty__longgong3'] = '莫要伤了和气。',
}

ty__longgong:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__longgong.name) and data.from and not data.from.dead and
      player:usedSkillTimes(ty__longgong.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty__longgong.name,
      prompt = "#longgong-invoke::" .. data.from.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule(".|.|.|.|.|equip")
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = data.from.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = ty__longgong.name,
      })
    end
    return true
  end,
})

return ty__longgong
