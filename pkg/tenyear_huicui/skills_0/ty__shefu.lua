local ty__shefu = fk.CreateSkill {
  name = "ty__shefu"
}

Fk:loadTranslationTable{
  ['ty__shefu'] = '设伏',
  ['#ty__shefu_ambush'] = '设伏',
  ['@[ty__shefu]'] = '伏兵',
  ['ty__shefu_active'] = '设伏',
  ['#ty__shefu-cost'] = '设伏：你可以将一张牌扣置为“伏兵”',
  ['#ty__shefu-invoke'] = '设伏：可以令 %dest 使用的 %arg 无效',
  ['#CardNullifiedBySkill'] = '由于 %arg 的效果，%from 使用的 %arg2 无效',
  ['@@ty__shefu-turn'] = '设伏封技',
  [':ty__shefu'] = '①结束阶段，你可以记录一个未被记录的基本牌或锦囊牌的牌名并扣置一张牌，称为“伏兵”；<br>②当其他角色于你回合外使用手牌时，你可以移去一张记录牌名相同的“伏兵”，令此牌无效（若此牌有目标角色则改为取消所有目标），然后若此时是该角色的回合内，其本回合所有技能失效。',
  ['$ty__shefu1'] = '吾已埋下伏兵，敌兵一来，管教他瓮中捉鳖。',
  ['$ty__shefu2'] = '我已设下重重圈套，就等敌军入彀矣。',
}

-- Effect for EventPhaseStart and CardUsing
ty__shefu:addEffect({fk.EventPhaseStart, fk.CardUsing}, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty__shefu) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and not player:isNude()
      else
        return target ~= player and player.phase == Player.NotActive and
          table.find(player:getTableMark("@[ty__shefu]"), function (shefu_pair)
            return shefu_pair[2] == data.card.trueName
          end) and U.IsUsingHandcard(target, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "ty__shefu_active",
        prompt = "#ty__shefu-cost",
        cancelable = true,
      })
      if success then
        event:setCostData(skill, dat)
        return true
      end
    else
      if room:askToSkillInvoke(player, {
        skill_name = ty__shefu.name,
        prompt = "#ty__shefu-invoke::"..target.id..":"..data.card:toLogString(),
      }) then
        room:doIndicate(player.id, {target.id})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local cid = event:getCostData(skill).cards[1]
      local name = event:getCostData(skill).interaction
      player:addToPile("#ty__shefu_ambush", cid, true, ty__shefu.name)
      if table.contains(player:getPile("#ty__shefu_ambush"), cid) then
        local mark = player:getTableMark("@[ty__shefu]")
        table.insert(mark, {cid, name})
        room:setPlayerMark(player, "@[ty__shefu]", mark)
      end
    else
      local mark = player:getTableMark("@[ty__shefu]")
      for i = 1, #mark, 1 do
        if mark[i][2] == data.card.trueName then
          local cid = mark[i][1]
          table.remove(mark, i)
          room:setPlayerMark(player, "@[ty__shefu]", #mark > 0 and mark or 0)
          if table.contains(player:getPile("#ty__shefu_ambush"), cid) then
            room:moveCardTo(cid, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, ty__shefu.name, nil, true, player.id)
          end
          break
        end
      end
      data.tos = {}
      room:sendLog{ type = "#CardNullifiedBySkill", from = target.id, arg = ty__shefu.name, arg2 = data.card:toLogString() }
      if not target.dead and target.phase ~= Player.NotActive then
        room:setPlayerMark(target, "@@ty__shefu-turn", 1)
      end
    end
  end,
})

-- Effect for EventLoseSkill
ty__shefu:addEffect(fk.EventLoseSkill, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return player == target and data == ty__shefu and player:getMark("@[ty__shefu]") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[ty__shefu]", 0)
  end,
})

-- Invalidity Skill Effect
local ty__shefu_invalidity = fk.CreateSkill {
  name = "#ty__shefu_invalidity"
}

ty__shefu_invalidity:addEffect("invalidity", {
  invalidity_func = function(self, from, skill_to_check)
    return from:getMark("@@ty__shefu-turn") > 0 and skill_to_check:isPlayerSkill(from)
  end
})

return ty__shefu
