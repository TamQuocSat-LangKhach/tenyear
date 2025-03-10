local jijun = fk.CreateSkill {
  name = "jijun"
}

Fk:loadTranslationTable{
  ['jijun'] = '集军',
  ['zhangliang_fang'] = '方',
  ['#jijun_delay'] = '集军',
  ['#jijun-push'] = '集军：是否%arg置于武将牌上（称为“方”）',
  [':jijun'] = '当你于出牌阶段内使用武器或非装备牌指定你为目标后，你可以判定。当此次判定的判定牌移至弃牌堆后，你可以将此判定牌置于你的武将牌上（称为“方”）。',
  ['$jijun1'] = '集民力万千，亦可为军！',
  ['$jijun2'] = '集万千义军，定天下大局！',
}

-- jijun触发效果
jijun:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  derived_piles = "zhangliang_fang",
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(jijun.name) and
      player.phase == Player.Play and player.id == data.to and
      (data.card.sub_type == Card.SubtypeWeapon or
      data.card.type ~= Card.TypeEquip)
  end,
  on_use = function(self, _, _, player, _)
    local room = player.room
    local judge = {
      who = player,
      reason = jijun.name,
    }
    room:judge(judge)
  end,
})

-- jijun_delay触发效果
jijun:addEffect(fk.AfterCardsMove, {
  name = "#jijun_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    local ids = {}
    local room = player.room
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonJudge then
        local judge_event = room.logic:getCurrentEvent():findParent(GameEvent.Judge)
        if judge_event and judge_event.data[1].who == player and judge_event.data[1].reason == jijun.name then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.Processing and room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end
    ids = U.moveCardsHoldingAreaCheck(room, ids)
    if #ids > 0 then
      event:setCostData(self, ids)
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local ids = table.simpleClone(event:getCostData(self)) --理论上来讲只有一张
    if player.room:askToSkillInvoke(player, {
      skill_name = jijun.name,
      prompt = "#jijun-push:::" .. Fk:getCardById(ids[1]):toLogString()
    }) then
      player:addToPile("zhangliang_fang", ids, true, jijun.name)
    end
  end,
})

return jijun
