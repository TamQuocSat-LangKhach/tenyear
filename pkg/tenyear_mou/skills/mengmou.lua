local mengmou = fk.CreateSkill {
  name = "mengmou"
}

Fk:loadTranslationTable{
  ['mengmou'] = '盟谋',
  ['#mengmou-slash'] = '盟谋：你可以连续使用【杀】，造成伤害后你回复体力（第%arg张，共%arg2张）',
  ['#mengmou-ask'] = '盟谋：你需连续打出【杀】，每少打出一张你失去1点体力（第%arg张，共%arg2张）',
  ['#mengmou_switch'] = '盟谋',
  [':mengmou'] = '转换技，游戏开始时可自选阴阳状态，每回合各限一次，当你获得其他角色的手牌后，或当其他角色获得你的手牌后，你可以令该角色执行（其中X为你的体力上限）：<br>阳：使用X张【杀】，每造成1点伤害回复1点体力；<br>阴：打出X张【杀】，每少打出一张失去1点体力。',
  ['$mengmou1'] = '南北同仇，请皇叔移驾江东，共观花火。',
  ['$mengmou2'] = '孙刘一家，慕英雄之意，忾窃汉之敌。',
}

mengmou:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(mengmou.name) and player:getMark("mengmou_"..player:getSwitchSkillState(mengmou.name, false, true).."-turn") == 0 then
      local targets = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerHand then
          if move.from == player.id and move.to and move.to ~= player.id and not table.contains(targets, move.to) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                table.insert(targets, move.to)
                break
              end
            end
          elseif move.to == player.id and move.from and move.from ~= player.id and not table.contains(targets, move.from) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                table.insert(targets, move.from)
                break
              end
            end
          end
        end
      end
      local room = player.room
      targets = table.filter(targets, function (id)
        return not room:getPlayerById(id).dead
      end)
      if #targets > 0 then
        event:setCostData(self, targets)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.simpleClone(event:getCostData(self))
    local room = player.room
    local prompt = (player:getSwitchSkillState(mengmou.name, false) == fk.SwitchYang) and "#mengmou-yang" or "#mengmou-yin"
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = mengmou.name,
        prompt = prompt.."-invoke::"..targets[1]..":"..player.maxHp
      }) then
        room:doIndicate(player.id, targets)
        event:setCostData(self, targets[1])
        return true
      end
    else
      local chosen_targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = mengmou.name,
        prompt = prompt.."-choose::"..targets[1]..":"..player.maxHp,
      })
      if #chosen_targets > 0 then
        event:setCostData(self, chosen_targets[1].id)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "mengmou_"..player:getSwitchSkillState(mengmou.name, true, true).."-turn", 1)
    local to = room:getPlayerById(event:getCostData(self))
    room:doIndicate(player.id, {to.id})
    setTYMouSwitchSkillState(player, "lusu", mengmou.name)
    local n = player.maxHp
    if player:getSwitchSkillState(mengmou.name, true) == fk.SwitchYang then
      local count = 0
      for i = 1, n, 1 do
        if to.dead then return end
        local use = room:askToUseCard(to, {
          pattern = "slash",
          prompt = "#mengmou-slash:::"..i..":"..n,
          extra_data = { bypass_times = true },
          cancelable = true,
        })
        if use then
          use.extraUse = true
          room:useCard(use)
          if use.damageDealt then
            for _, p in ipairs(room.players) do
              if use.damageDealt[p.id] then
                count = count + use.damageDealt[p.id]
              end
            end
          end
        else
          break
        end
      end
      if not to.dead and to:isWounded() and count > 0 then
        room:recover({
          who = to,
          num = math.min(to:getLostHp(), count),
          recoverBy = player,
          skillName = mengmou.name,
        })
      end
    else
      local count = 0
      for i = 1, n, 1 do
        if to.dead then return end
        local cardResponded = room:askToResponse(to, {
          pattern = "slash",
          prompt = "#mengmou-ask:::"..i..":"..n,
          cancelable = true,
        })
        if cardResponded then
          count = i
          room:responseCard({
            from = to.id,
            card = cardResponded,
          })
        else
          break
        end
      end
      if not to.dead and n > count then
        room:loseHp(to, n - count, mengmou.name)
      end
    end
  end,
})

mengmou:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mengmou.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    setTYMouSwitchSkillState(player, "lusu", mengmou.name,
      room:askToChoice(player, {
        choices = { "tymou_switch:::mengmou:yang", "tymou_switch:::mengmou:yin" },
        skill_name = mengmou.name,
        prompt = "#tymou_switch-transer:::mengmou"
      }) == "tymou_switch:::mengmou:yin")
  end,
})

return mengmou
