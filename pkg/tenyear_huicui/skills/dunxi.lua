local dunxi = fk.CreateSkill {
  name = "dunxi"
}

Fk:loadTranslationTable{
  ['dunxi'] = '钝袭',
  ['#dunxi-choose'] = '钝袭：你可以令一名角色获得“钝”标记，其使用下一张牌目标改为随机角色',
  ['@bianxi_dun'] = '钝',
  ['#dunxi_delay'] = '钝袭',
  [':dunxi'] = '当你使用伤害牌时，你可令其中一个目标获得1个“钝”标记。有“钝”标记的角色使用基本牌或锦囊牌时，若目标数为1且没有处于濒死状态的角色，其移去一个“钝”，然后目标改为随机一名角色。若随机的目标与原本目标相同，则其于此牌结算结束后失去1点体力并结束出牌阶段。',
  ['$dunxi1'] = '看锤！',
  ['$dunxi2'] = '且吃我一锤！',
}

dunxi:addEffect(fk.CardUsing, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dunxi.name) and data.card.is_damage_card and data.tos
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      targets = TargetGroup:getRealTargets(data.tos),
      min_num = 1,
      max_num = 1,
      prompt = "#dunxi-choose",
      skill_name = dunxi.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cost_data = event:getCostData(self)
    player.room:addPlayerMark(player.room:getPlayerById(cost_data), "@bianxi_dun", 1)
  end,
})

dunxi:addEffect({fk.CardUsing, fk.CardUseFinished}, {
  name = "#dunxi_delay",
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then
      if player == target and player:getMark("@bianxi_dun") > 0 and 
        (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and #TargetGroup:getRealTargets(data.tos) == 1 then
        for _, p in ipairs(player.room.alive_players) do
          if p.dying then
            return false
          end
        end
        return true
      end
    elseif event == fk.CardUseFinished then
      return not player.dead and data.extra_data and data.extra_data.dunxi_record and 
        table.contains(data.extra_data.dunxi_record, player.id)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:removePlayerMark(player, "@bianxi_dun")
      local orig_to = data.tos[1]
      local targets = {}
      local c_pid
      for _, p in ipairs(room.alive_players) do
        if not player:isProhibited(p, data.card) and 
          (data.card.sub_type == Card.SubtypeDelayedTrick or data.card.skill:modTargetFilter(p.id, {}, player, data.card, true)) then
          local ho_spair_check = true
          if #orig_to > 1 then
            --target_filter check, for collateral, diversion...
            local ho_spair_target = {p.id}
            for i = 2, #orig_to, 1 do
              c_pid = orig_to[i]
              if not data.card.skill:modTargetFilter(c_pid, ho_spair_target, player, data.card, true) then
                ho_spair_check = false
                break
              end
              table.insert(ho_spair_target, c_pid)
            end
          end
          if ho_spair_check then
            table.insert(targets, p.id)
          end
        end
      end
      if #targets > 0 then
        local random_target = table.random(targets)
        for i = 1, 2, 1 do
          for _, p in ipairs(room:getAllPlayers()) do
            if table.contains(targets, p.id) then
              room:setEmotion(p, "./image/anim/selectable")
              room:notifyMoveFocus(p, dunxi.name)
              room:delay(300)
            end
          end
        end
        for _, p in ipairs(room:getAllPlayers()) do
          if table.contains(targets, p.id) then
            room:setEmotion(p, "./image/anim/selectable")
            room:delay(600)
            if p.id == random_target then
              room:doIndicate(data.from, {random_target})
              break
            end
          end
        end

        if random_target == orig_to[1] then
          data.extra_data = data.extra_data or {}
          local dunxi_record = data.extra_data.dunxi_record or {}
          table.insert(dunxi_record, player.id)
          data.extra_data.dunxi_record = dunxi_record
        else
          orig_to[1] = random_target
          data.tos = { orig_to }
        end
      else
        data.tos = {}
      end
    elseif event == fk.CardUseFinished then
      room:loseHp(player, 1, dunxi.name)
      if player.phase == Player.Play then
        player:endPlayPhase()
      end
    end
  end,
})

return dunxi
