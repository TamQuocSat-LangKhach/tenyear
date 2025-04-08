local mingluan = fk.CreateSkill {
  name = "mingluan",
}

Fk:loadTranslationTable{
  ["mingluan"] = "鸣鸾",
  [":mingluan"] = "其他角色的结束阶段，若本回合有角色回复过体力，你可以弃置任意张牌，然后摸等同于当前回合角色手牌数的牌（最多摸至五张）。",

  ["#mingluan-invoke"] = "鸣鸾：弃置任意张牌（可以不弃），然后摸 %dest 手牌数的牌，最多摸至五张",

  ["$mingluan1"] = "鸾笺寄情，笙歌动心。",
  ["$mingluan2"] = "鸾鸣轻歌，声声悦耳。",
}

mingluan:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(mingluan.name) and target.phase == Player.Finish and
      #player.room.logic:getEventsOfScope(GameEvent.Recover, 1, Util.TrueFunc, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "discard_skill",
      prompt = "#mingluan-invoke::" .. target.id,
      cancelable = true,
      extra_data = {
        num = 999,
        min_num = 0,
        include_equip = false,
        pattern = ".",
        skillName = mingluan.name,
      }
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #event:getCostData(self).cards > 0 then
      room:throwCard(event:getCostData(self).cards, mingluan.name, player, player)
    end
    if player.dead or target:isKongcheng() or player:getHandcardNum() > 4 then return end
    local n = math.min(5 - player:getHandcardNum(), target:getHandcardNum())
    player:drawCards(n, mingluan.name)
  end,
})

return mingluan
