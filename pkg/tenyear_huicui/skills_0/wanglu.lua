local wanglu = fk.CreateSkill {
  name = "wanglu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['wanglu'] = '望橹',
  ['xianzhu'] = '陷筑',
  [':wanglu'] = '锁定技，准备阶段，你将【大攻车】置入你的装备区，若你的装备区内已有【大攻车】，则你执行一个额外的出牌阶段。<br><font color=>【大攻车】<br>♠9 装备牌·宝物<br /><b>装备技能</b>：出牌阶段开始时，你可以视为使用一张【杀】，当此【杀】对目标角色造成伤害后，你弃置其一张牌。若此牌未升级，则防止此牌被弃置。此牌离开装备区时销毁。',
  ['$wanglu1'] = '大攻车前，坚城弗当。',
  ['$wanglu2'] = '大攻既作，天下可望！',
}

wanglu:addEffect(fk.EventPhaseStart, {
  
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wanglu.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "siege_engine" end) then
      player:gainAnExtraPhase(Player.Play)
    else
      local engine = table.find(U.prepareDeriveCards(room, wanglu_engine, "wanglu_engine"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if engine and U.canMoveCardIntoEquip(player, engine) then
        for i = 1, 3, 1 do
          room:setPlayerMark(player, "xianzhu"..tostring(i), 0)
        end
        room:moveCardIntoEquip(player, engine, wanglu.name, true, player)
      end
    end
  end,
})

return wanglu
