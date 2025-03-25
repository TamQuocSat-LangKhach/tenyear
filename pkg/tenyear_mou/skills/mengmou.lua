local mengmou = fk.CreateSkill {
  name = "mengmou",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["mengmou"] = "盟谋",
  [":mengmou"] = "转换技，游戏开始时可自选阴阳状态。每回合各限一次，当你获得其他角色的手牌后，或当其他角色获得你的手牌后，你可以令该角色执行"..
  "（其中X为你的体力上限）：<br>阳：使用X张【杀】，每造成1点伤害回复1点体力；<br>阴：打出X张【杀】，每少打出一张失去1点体力。",

  ["#mengmou-yang-invoke"] = "盟谋：令 %dest 使用%arg张【杀】，造成伤害后其回复体力",
  ["#mengmou-yin-invoke"] = "盟谋：令 %dest 打出%arg张【杀】，每少打出一张其失去1点体力",
  ["#mengmou-yang-choose"] = "盟谋：令一名角色使用%arg张【杀】，造成伤害后其回复体力",
  ["#mengmou-yin-choose"] = "盟谋：令一名角色打出%arg张【杀】，每少打出一张其失去1点体力",
  ["#mengmou-slash"] = "盟谋：你可以连续使用【杀】，造成伤害后你回复体力（第%arg张，共%arg2张）",
  ["#mengmou-ask"] = "盟谋：你需连续打出【杀】，每少打出一张你失去1点体力（第%arg张，共%arg2张）",

  ["$mengmou1"] = "南北同仇，请皇叔移驾江东，共观花火。",
  ["$mengmou2"] = "孙刘一家，慕英雄之意，忾窃汉之敌。",
}

local U = require "packages/utility/utility"

mengmou:addEffect(fk.AfterCardsMove, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(mengmou.name) and
      player:getMark("mengmou_"..player:getSwitchSkillState(mengmou.name, false, true).."-turn") == 0 then
      local targets = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.PlayerHand then
          if move.from == player and move.to and move.to ~= player and not table.contains(targets, move.to) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                table.insert(targets, move.to)
                break
              end
            end
          elseif move.to == player and move.from and move.from ~= player and not table.contains(targets, move.from) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                table.insert(targets, move.from)
                break
              end
            end
          end
        end
      end
      targets = table.filter(targets, function (p)
        return not p.dead
      end)
      if #targets > 0 then
        event:setCostData(self, {extra_data = targets})
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(event:getCostData(self).extra_data)
    local prompt = "#mengmou-"..player:getSwitchSkillState(mengmou.name, false, true)
    if #targets == 1 then
      if room:askToSkillInvoke(player, {
        skill_name = mengmou.name,
        prompt = prompt.."-invoke::"..targets[1].id..":"..player.maxHp
      }) then
        event:setCostData(self, {tos = targets})
        return true
      end
    else
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = mengmou.name,
        prompt = prompt.."-choose::"..targets[1].id..":"..player.maxHp,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.SetSwitchSkillState(player, mengmou.name, player:getSwitchSkillState(mengmou.name, false))
    room:setPlayerMark(player, "mengmou_"..player:getSwitchSkillState(mengmou.name, true, true).."-turn", 1)
    local to = event:getCostData(self).tos[1]
    local n = player.maxHp
    if player:getSwitchSkillState(mengmou.name, true) == fk.SwitchYang then
      local count = 0
      for i = 1, n, 1 do
        if to.dead then return end
        local use = room:askToUseCard(to, {
          skill_name = mengmou.name,
          pattern = "slash",
          prompt = "#mengmou-slash:::"..i..":"..n,
          extra_data = {
            bypass_times = true,
            extraUse = true,
          },
          cancelable = true,
        })
        if use then
          room:useCard(use)
          if use.damageDealt then
            for _, p in ipairs(room.players) do
              if use.damageDealt[p] then
                count = count + use.damageDealt[p]
              end
            end
          end
        else
          break
        end
      end
      if not to.dead and to:isWounded() and count > 0 then
        room:recover{
          who = to,
          num = count,
          recoverBy = player,
          skillName = mengmou.name,
        }
      end
    else
      local count = 0
      for i = 1, n, 1 do
        if to.dead then return end
        local respond = room:askToResponse(to, {
          skill_name = mengmou.name,
          pattern = "slash",
          prompt = "#mengmou-ask:::"..i..":"..n,
          cancelable = true,
        })
        if respond then
          count = i
          room:responseCard(respond)
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
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mengmou.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "tymou_switch:::mengmou:yang", "tymou_switch:::mengmou:yin" },
      skill_name = mengmou.name,
      prompt = "#tymou_switch-choice:::mengmou",
    })
    choice = choice:endsWith("yang") and fk.SwitchYang or fk.SwitchYin
    U.SetSwitchSkillState(player, mengmou.name, choice)
  end,
})

return mengmou
