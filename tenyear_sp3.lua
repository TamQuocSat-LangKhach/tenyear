local extension = Package("tenyear_sp3")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_sp3"] = "十周年专属3",
}

local dufuren = General(extension, "dufuren", "wei", 3, 3, General.Female)
local yise = fk.CreateTriggerSkill{
  name = "yise",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          self.yise_to = move.to
          for _, info in ipairs(move.moveInfo) do
            self.yise_color = Fk:getCardById(info.cardId).color
            if self.yise_color == Card.Red then
              return player.room:getPlayerById(move.to):isWounded()
            else
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if self.yise_color == Card.Red then
      return player.room:askForSkillInvoke(player, self.name, data, "#yise1-invoke::"..self.yise_to)
    elseif self.yise_color == Card.Black then
      return player.room:askForSkillInvoke(player, self.name, data, "#yise2-invoke::"..self.yise_to)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.yise_to)
    if self.yise_color == Card.Red then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    elseif self.yise_color == Card.Black then
      room:addPlayerMark(to, "yise_damage", 1)
    end
  end,
}
local yise_record = fk.CreateTriggerSkill{
  name = "#yise_record",
  anim_type = "offensive",

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("yise_damage") > 0 and data.card and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("yise_damage")
    player.room:setPlayerMark(player, "yise_damage", 0)
  end,
}
local shunshi = fk.CreateTriggerSkill{
  name = "shunshi",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and not player:isNude() then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if event == fk.EventPhaseStart or (event == fk.Damaged and p ~= data.from) then
        table.insert(targets, p.id)
      end
    end
    local tos, id = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".", "#shunshi-cost", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos[1], id}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(self.cost_data[1], self.cost_data[2], false, fk.ReasonGive)
    room:addPlayerMark(player, self.name, 1)
  end,

  refresh_events = {fk.DrawNCards, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if player:getMark(self.name) > 0 then
      if event == fk.DrawNCards then
        return true
      else
        return data.to == Player.NotActive
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + player:getMark("shunshi")
    else
      player.room:setPlayerMark(player, self.name, 0)
    end
  end,
}
local shunshi_targetmod = fk.CreateTargetModSkill{
  name = "#shunshi_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill("shunshi") and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("shunshi")
    end
  end,
}
local shunshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#shunshi_maxcards",
  correct_func = function(self, player)
    return player:getMark("shunshi")
  end,
}
yise:addRelatedSkill(yise_record)
shunshi:addRelatedSkill(shunshi_targetmod)
shunshi:addRelatedSkill(shunshi_maxcards)
dufuren:addSkill(yise)
dufuren:addSkill(shunshi)
Fk:loadTranslationTable{
  ["dufuren"] = "杜夫人",
  ["yise"] = "异色",
  [":yise"] = "当其他角色获得你的牌后，若此牌为：红色，你可以令其回复1点体力；黑色，其下次受到【杀】造成的伤害时，此伤害+1。",
  ["shunshi"] = "顺世",
  [":shunshi"] = "准备阶段或当你于回合外受到伤害后，你可以交给一名其他角色一张牌（伤害来源除外），然后直到你的回合结束，你：摸牌阶段多摸一张牌、出牌阶段使用的【杀】次数上限+1、手牌上限+1。",
  ["#yise1-invoke"] = "异色：你可以令 %dest 回复1点体力",
  ["#yise2-invoke"] = "异色：你可以令 %dest 下次受到【杀】的伤害+1",
  ["#shunshi-cost"] = "顺世：你可以交给一名其他角色一张牌，然后直到你的回合结束获得效果",

  ["$yise1"] = "明丽端庄，双瞳剪水。",
  ["$yise2"] = "姿色天然，貌若桃李。",
  ["$shunshi1"] = "顺应时运，得保安康。",
  ["$shunshi2"] = "随遇而安，宠辱不惊。",
  ["~dufuren"] = "往事云烟，去日苦多。",
}
--荀谌 张宁 万年公主 童渊 刘永2021.12.1
local xunchen = General(extension, "ty__xunchen", "qun", 3)
local ty__fenglve = fk.CreateActiveSkill{
  name = "ty__fenglve",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      local dummy = Fk:cloneCard("dilu")
      if #target:getCardIds{Player.Hand, Player.Equip, Player.Judge} < 3 then
        dummy:addSubcards(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      else
        local cards = room:askForCardsChosen(target, target, 2, 2, "hej", self.name)
        dummy:addSubcards(cards)
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, false, fk.ReasonGive)
      end
    elseif pindian.results[target.id].winner == target then
      if room:getCardArea(pindian.fromCard.id) == Card.DiscardPile then
        room:delay(1000)
        room:obtainCard(target, pindian.fromCard.id, true, fk.ReasonJustMove)
      end
    else
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    end
  end,
}
local anyong = fk.CreateTriggerSkill{
  name = "anyong",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.from and data.from.phase ~= Player.NotActive and data.to ~= data.from then
      if data.from:getMark("anyong-turn") == 0 then
        player.room:addPlayerMark(data.from, "anyong-turn", 1)
        return data.damage == 1 and not data.to.dead and not player:isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#anyong-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {data.to.id})
    player.room:damage{
      from = player,
      to = data.to,
      damage = 1,
      skillName = self.name,
    }
  end,
}
xunchen:addSkill(ty__fenglve)
xunchen:addSkill(anyong)
Fk:loadTranslationTable{
  ["ty__xunchen"] = "荀谌",
  ["ty__fenglve"] = "锋略",
  [":ty__fenglve"] = "出牌阶段限一次，你可以和一名其他角色拼点。若你赢，该角色交给你其区域内的两张牌；若点数相同，此技能视为未发动过；若你输，该角色获得你拼点的牌。",
  ["anyong"] = "暗涌",
  [":anyong"] = "当一名角色于其回合内第一次对另一名角色造成伤害后，若此伤害值为1，你可以弃置一张牌对受到伤害的角色造成1点伤害。",
  ["#anyong-invoke"] = "暗涌：你可以弃置一张牌，对 %dest 造成1点伤害",
}

Fk:loadTranslationTable{
  ["ty__zhangning"] = "张宁",
  ["tianze"] = "天则",
  [":tianze"] = "其他角色的出牌阶段限一次，其使用黑色手牌结算完毕后，你可以弃置一张黑色牌对其造成1点伤害；其他角色的黑色判定牌生效后，你摸一张牌。",
  ["difa"] = "地法",
  [":difa"] = "你的回合内限一次，当你从牌堆摸到红色牌后，你可以弃置此牌，然后选择一种锦囊牌的牌名，从牌堆或弃牌堆获得一张。",
}

local wanniangongzhu = General(extension, "wanniangongzhu", "qun", 3, 3, General.Female)
local zhenge = fk.CreateTriggerSkill{
  name = "zhenge",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local p = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id
    end), 1, 1, "#zhenge-choose", self.name)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if to:getMark("@zhenge") <5 then
      room:addPlayerMark(to, "@zhenge", 1)
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(to)) do
      if to:inMyAttackRange(p) and not to:isProhibited(p ,Fk:cloneCard("slash")) then
        if p ~= player then
          table.insert(targets, p.id)
        end
      else
        return
      end
    end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#zhenge-slash::"..to.id, self.name, true)
    if #tos > 0 then
      room:useVirtualCard("slash", nil, to, room:getPlayerById(tos[1]), self.name, true)
    end
  end,
}
local zhenge_attackrange = fk.CreateAttackRangeSkill{
  name = "#zhenge_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@zhenge")
  end,
}
local xinghan = fk.CreateTriggerSkill{
  name = "xinghan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not target.dead and target:getMark("@zhenge") > 0 and
      data.card and data.card.trueName == "slash" and data.card.extra_data and table.contains(data.card.extra_data, "xinghan")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p.player_cards[Player.Hand] > #player.player_cards[Player.Hand] then
        player:drawCards(math.min(target:getAttackRange(), 5), self.name)
        return
      end
    end
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return data.card.trueName == "slash" and player.room.current and player.room.current:getMark("xinghan-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room.current, "xinghan-turn", 1)
    if target == player.room.current then
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "xinghan")
    end
  end,
}
zhenge:addRelatedSkill(zhenge_attackrange)
wanniangongzhu:addSkill(zhenge)
wanniangongzhu:addSkill(xinghan)
Fk:loadTranslationTable{
  ["wanniangongzhu"] = "万年公主",
  ["zhenge"] = "枕戈",
  [":zhenge"] = "准备阶段，你可以令一名角色的攻击范围+1（加值至多为5），然后若其他角色都在其的攻击范围内，你可以令其视为对另一名你选择的角色使用一张【杀】。",
  ["xinghan"] = "兴汉",
  [":xinghan"] = "锁定技，当〖枕戈〗选择过的角色使用【杀】造成伤害后，若此【杀】是本回合的第一张【杀】，你摸一张牌。若你的手牌数不是全场唯一最多的，则改为摸X张牌（X为该角色的攻击范围且最多为5）。",
  ["@zhenge"] = "枕戈",
  ["#zhenge-choose"] = "枕戈：你可以令一名角色的攻击范围+1（至多+5）",
  ["#zhenge-slash"] = "枕戈：你可以选择另一名角色，视为 %dest 对此角色使用【杀】",

  ["$zhenge1"] = "常备不懈，严阵以待。",
  ["$zhenge2"] = "枕戈待旦，日夜警惕。",
  ["$xinghan1"] = "汉之兴旺，不敢松懈。",
  ["$xinghan2"] = "兴汉除贼，吾之所愿。",
  ["~wanniangongzhu"] = "兴汉的使命，还没有完成。",
}

Fk:loadTranslationTable{
  ["ty__tongyuan"] = "童渊",
  ["chaofeng"] = "朝凤",
  [":chaofeng"] = "出牌阶段限一次，当你使用牌造成伤害时，你可以弃置一张手牌，然后摸一张牌。若弃置的牌与造成伤害的牌：颜色相同，则多摸1张牌；类型相同，则此伤害+1。",
  ["chuanshu"] = "传术",
  [":chuanshu"] = "限定技，准备阶段若你已受伤，或当你死亡时，你可令一名其他角色获得〖朝凤〗，然后你获得〖龙胆〗、〖从谏〗、〖穿云〗。",
  ["chuanyun"] = "穿云",
  [":chuanyun"] = "当你使用【杀】指定目标后，你可令该角色随机弃置一张装备区里的牌。",
}

--嵇康 曹不兴2021.12.3
--陈登2021.12.15
--曹金玉 滕公主2022.1.22
local caojinyu = General(extension, "caojinyu", "wei", 3, 3, General.Female)
local yuqi = fk.CreateTriggerSkill{
  name = "yuqi",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player.dead and not target.dead and
    (target == player or player:distanceTo(target) <= player:getMark("yuqi1")) and player:getMark("yuqi-turn") < 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "yuqi-turn", 1)
    --local card_ids = room:getNCards(player:getMark("yuqi2"))

    --FIXME: askForCardsChosen? or yiji?
    local n1, n2 = 0, 0
    if player:getMark("yuqi2") >= player:getMark("yuqi4") then
      n2 = player:getMark("yuqi4")
      n1 = math.min(player:getMark("yuqi3"), player:getMark("yuqi2") - player:getMark("yuqi4"))
    else
      n2 = player:getMark("yuqi2")
    end
    target:drawCards(n1)
    player:drawCards(n2)
  end,

  refresh_events = {fk.GameStart},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "yuqi2", 3)
    room:setPlayerMark(player, "yuqi3", 1)
    room:setPlayerMark(player, "yuqi4", 1)
    room:setPlayerMark(player, "@" .. self.name, string.format("%d-%d-%d-%d", 0, 3, 1, 1))
  end,
}
local function AddYuqi(player, skillName, num)
  local room = player.room
  local choices = {}
  for i = 1, 4, 1 do
    if player:getMark("yuqi" .. tostring(i)) < 5 then
      table.insert(choices, "yuqi" .. tostring(i))
    end
  end
  if #choices > 0 then
    local choice = room:askForChoice(player, choices, skillName)
    local x = player:getMark(choice)
    if x + num < 6 then
      x = x + num
    else
      x = 5
    end
    room:setPlayerMark(player, choice, x)
    room:setPlayerMark(player, "@yuqi", string.format("%d-%d-%d-%d",
    player:getMark("yuqi1"),
    player:getMark("yuqi2"),
    player:getMark("yuqi3"),
    player:getMark("yuqi4")))
  end
end
local shanshen = fk.CreateTriggerSkill{
  name = "shanshen",
  anim_type = "control",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    AddYuqi(player, self.name, 2)
    if target:getMark(self.name) == 0 and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = self.name,
      }
    end
  end,
  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    return target == player and target:hasSkill(self.name) and data.to:getMark(self.name) == 0
  end,
  on_refresh = function(self, event, target, player, data)
      player.room:setPlayerMark(data.to, self.name, 1)
  end,
}
local xianjing = fk.CreateTriggerSkill{
  name = "xianjing",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Start then
      for i = 1, 4, 1 do
        if player:getMark("yuqi" .. tostring(i)) < 5 then
          return true
        end
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    AddYuqi(player, self.name, 1)
    if not player:isWounded() then
      AddYuqi(player, self.name, 1)
    end
  end,
}
caojinyu:addSkill(yuqi)
caojinyu:addSkill(shanshen)
caojinyu:addSkill(xianjing)
Fk:loadTranslationTable{
  ["caojinyu"] = "曹金玉",
  ["yuqi"] = "隅泣",
  [":yuqi"] = "当有角色受到伤害后，若你与其距离0或者更少，你可以观看牌堆顶的三张牌，将其中至多一张交给受伤角色，至多一张自己获得，剩余的牌放回牌堆顶。（每回合限触发2次）",
  ["shanshen"] = "善身",
  [":shanshen"] = "当有角色死亡时，你可令“隅泣”中的一个数字+2（单项不能超过5）。然后若你没有对死亡角色造成过伤害，你回复1点体力。",
  ["xianjing"] = "娴静",
  [":xianjing"] = "准备阶段，你可令“隅泣”中的一个数字+1（单项不能超过5）。若你满体力值，则再令“隅泣”中的一个数字+1。",
  ["@yuqi"] = "隅泣",
  ["yuqi1"] = "距离",
  ["yuqi2"] = "观看牌数",
  ["yuqi3"] = "交给受伤角色牌数",
  ["yuqi4"] = "自己获得牌数",

  ["$yuqi1"] = "孤影独泣，困于隅角。",
  ["$yuqi2"] = "向隅而泣，黯然伤感。",
  ["$shanshen1"] = "好善为德，坚守本心。",
  ["$shanshen2"] = "洁身自爱，独善其身。",
  ["$xianjing1"] = "文静娴丽，举止柔美。",
  ["$xianjing2"] = "娴静淡雅，温婉穆穆。",
  ["~caojinyu"] = "平叔之情，吾岂不明。",
}
Fk:loadTranslationTable{
  ["tenggongzhu"] = "滕公主",
  ["xingchong"] = "幸宠",
  [":xingchong"] = "每轮游戏开始时，你可以摸任意张牌并展示任意张牌（摸牌和展示牌的总数不能超过你的体力上限）。若如此做，本轮内当你失去一张以此法展示的手牌后，你摸两张牌。",
  ["xingchng"] = "幸宠",
  [":xingcong"] = "锁定技，牌堆第一次洗牌后，你于当前回合结束时加1点体力上限。牌堆第二次洗牌后，你于当前回合结束时回复1点体力，然后本局游戏手牌上限+10。",
}
--王桃 王悦 庞德公2022.2.28
--吴范 李采薇 祢衡2022.3.5
Fk:loadTranslationTable{
  ["wufan"] = "吴范",
  ["tianyun"] = "天运",
  [":tianyun"] = "获得起始手牌后，你再从牌堆中随机获得手牌中没有的花色各一张牌。<br>"..
  "一名角色的回合开始时，若其座次等于游戏轮数，你可以观看牌堆顶的X张牌，然后以任意顺序置于牌堆顶或牌堆底，若你将所有牌均置于牌堆底，则你可以令一名角色摸X张牌（X为你手牌中的花色数），若如此做，你失去1点体力。",
  ["yuyan"] = "预言",
  [":yuyan"] = "每轮游戏开始时，你选择一名角色，若其是本轮第一个进入濒死状态的角色，则你获得技能“奋音”直到你的回合结束。若其是本轮第一个造成伤害的角色，则你摸两张牌。",
}
Fk:loadTranslationTable{
  ["licaiwei"] = "李采薇",
  ["yijiao"] = "异教",
  [":yijiao"] = "出牌阶段限1次，你可以选择1名其他角色并在1~4之间选择1个数字，该角色获得此数字十倍的“异”标记；有“异”标记的角色结束阶段，若其本回合使用牌的点数之和：<br>"..
  "1.小于“异”标记数，其随机弃置1张手牌；<br>"..
  "2.等于“异”标记数，该角色本回合结束后进行1个额外的回合；<br>"..
  "3.大于“异”标记数，你摸2张牌。",
  ["qibie"] = "泣别",
  [":qibie"] = "一名角色阵亡后，你可以弃置所有手牌，然后回复1点体力值并摸X+1张牌（X为你以此法弃置牌数）。",
}
--孙翊2022.3.24
--赵嫣
--严夫人 郝萌 马日磾2022.4.25
--冯妤 蔡瑁张允 高览 朱灵2022.5.20
local fengyu = General(extension, "ty__fengfangnv", "qun", 3, 3, General.Female)
local tiqi = fk.CreateTriggerSkill{
  name = "tiqi",
  anim_type = "drawcard",
  events = {fk.AfterDrawNCards},  --tenyear's strange event. change it
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and data.n ~= 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#tiqi-invoke:::"..tostring(math.abs(data.n - 2)))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.abs(data.n - 2)
    player:drawCards(n, self.name)
    local choice = room:askForChoice(player, {"tiqi_add", "tiqi_minus"}, self.name)
    if choice == "tiqi_add" then
      room:addPlayerMark(target, "AddMaxCards-turn", n)
    else
      room:addPlayerMark(target, "MinusMaxCards-turn", n)
    end
  end,
}
local baoshu = fk.CreateTriggerSkill{
  name = "baoshu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function(p)
      return p.id
    end), 1, player.maxHp, "#baoshu-choose", self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      room:addPlayerMark(p, "@fengyu_shu", player.maxHp - #self.cost_data + 1)
      if not p.faceup then
        p:turnOver()
      end
      if p.chained then
        p:setChainState(false)
      end
    end
  end,

  refresh_events = {fk.DrawNCards},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@fengyu_shu") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@fengyu_shu")
    player.room:setPlayerMark(player, "@fengyu_shu", 0)
  end
}
fengyu:addSkill(tiqi)
fengyu:addSkill(baoshu)
Fk:loadTranslationTable{
  ["ty__fengfangnv"] = "冯妤",
  ["tiqi"] = "涕泣",
  [":tiqi"] = "其他角色摸牌阶段摸牌后，若其摸牌数不等于2，则你摸超出或少于2的牌，然后令该角色本回合手牌上限增加或减少同样的数值。",
  ["baoshu"] = "宝梳",
  [":baoshu"] = "准备阶段，你可以选择至多X名角色（X为你的体力上限），这些角色各获得一个“梳”标记并重置武将牌（有“梳”标记的角色摸牌阶段多摸与其“梳”等量的牌，然后移去其所有“梳”），你每少选一名角色，每名目标角色便多获得一个“梳”。",
  ["#tiqi-invoke"] = "涕泣：你可以摸%arg张牌，并令其本回合手牌上限+X或-X",
  ["tiqi_add"] = "增加手牌上限",
  ["tiqi_minus"] = "减少手牌上限",
  ["#baoshu-choose"] = "宝梳：你可以令若干名角色获得“梳”标记，重置其武将牌且其摸牌阶段多摸牌",
  ["@fengyu_shu"] = "梳",
}

local caimaozhangyun = General(extension, "caimaozhangyun", "wei", 4)
local lianzhou = fk.CreateTriggerSkill{
  name = "lianzhou",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.chained then
      player:setChainState(true)
    end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.hp == player.hp and not p.chained end), function(p) return p.id end)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 999, "#lianzhou-choose", self.name, true)
    if #tos > 0 then
      table.every(tos, function(p) room:getPlayerById(p):setChainState(true) end)
    end
  end,
}
local jinglan = fk.CreateTriggerSkill{
  name = "jinglan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player.player_cards[Player.Hand] > player.hp then
      if #player.player_cards[Player.Hand] < 4 then
        player:throwAllCards("h")
      else
        room:askForDiscard(player, 3, 3, false, self.name, false)
      end
    elseif #player.player_cards[Player.Hand] == player.hp then
      if #player.player_cards[Player.Hand] < 2 then
        player:throwAllCards("h")
      else
        room:askForDiscard(player, 1, 1, false, self.name, false)
      end
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    elseif #player.player_cards[Player.Hand] < player.hp then
      room:damage{
        to = player,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = self.name,
      }
      if not player.dead then
        player:drawCards(4, self.name)
      end
    end
  end,
}
caimaozhangyun:addSkill(lianzhou)
caimaozhangyun:addSkill(jinglan)
Fk:loadTranslationTable{
  ["caimaozhangyun"] = "蔡瑁张允",
  ["lianzhou"] = "连舟",
  [":lianzhou"] = "锁定技，准备阶段，将你的武将牌横置，然后横置任意名体力值等于你的角色。",
  ["jinglan"] = "惊澜",
  [":jinglan"] = "锁定技，当你造成伤害后，若你的手牌数：大于体力值，你弃三张手牌；等于体力值，你弃一张手牌并回复1点体力；小于体力值，你受到1点火焰伤害并摸四张牌。",
  ["#lianzhou-choose"] = "连舟：你可以横置任意名体力值等于你的角色",
}

local gaolan = General(extension, "ty__gaolan", "qun", 4)
local xizhen = fk.CreateTriggerSkill{
  name = "xizhen",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not (player:isProhibited(p, Fk:cloneCard("slash")) and player:isProhibited(p, Fk:cloneCard("duel"))) then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xizhen-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {}
    for _, name in ipairs({"slash", "duel"}) do
      if not player:isProhibited(to, Fk:cloneCard(name)) then
        table.insert(choices, name)
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#xizhen-choice::"..to.id)
    room:useVirtualCard(choice, nil, player, to, self.name, true)
    room:setPlayerMark(player, "xizhen-phase", to.id)
  end,

  refresh_events = {fk.CardUsing, fk.CardResponding},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 and
      data.responseToEvent and data.responseToEvent.from == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("xizhen-phase"))
    if not to.dead then
      if to:isWounded() then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
        player:drawCards(1, self.name)
      else
        player:drawCards(2, self.name)
      end
    end
  end,
}
gaolan:addSkill(xizhen)
Fk:loadTranslationTable{
  ["ty__gaolan"] = "高览",
  ["xizhen"] = "袭阵",
  [":xizhen"] = "出牌阶段开始时，你可选择一名其他角色，视为对其使用【杀】或【决斗】，然后本阶段你的牌每次被使用或打出牌响应时，该角色回复1点体力，你摸一张牌（若其未受伤，改为两张）。",
  ["#xizhen-choose"] = "袭阵：你可视为对一名角色使用【杀】或【决斗】；<br>本阶段你的牌被响应时其回复1点体力，你摸一张牌（若其未受伤则改为摸两张）",
  ["#xizhen-choice"] = "袭阵：选择视为对 %dest 使用的牌",

  ["$xizhen1"] = "今我为刀俎，尔等皆为鱼肉。",
  ["$xizhen2"] = "先发可制人，后发制于人。",
  ["~ty__gaolan"] = "郭公则害我！",
}

Fk:loadTranslationTable{
  ["ty__zhuling"] = "朱灵",
  ["ty__zhanyi"] = "战意",
  [":ty__zhanyi"] = "出牌阶段开始时，你可以弃置一种类别的所有牌，另外两种类别的牌本回合获得以下效果：<br>"..
  "基本牌：你使用基本牌无距离限制且造成的伤害和回复值+1；<br>"..
  "锦囊牌：你使用锦囊牌时摸一张牌且锦囊牌不计入手牌上限；<br>"..
  "装备牌：你使用装备牌时可以弃置一名其他角色的一张牌。",
}
--曹髦 吉平 阎柔 来莺儿 神姜维2022.6.11
local caomao = General(extension, "caomao", "wei", 3, 4)
local qianlong = fk.CreateTriggerSkill{
  name = "qianlong",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card_ids = room:getNCards(3)
    local get = {}
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
    })
    table.forEach(room.players, function(p)
      room:fillAG(p, card_ids)
    end)
    while #get < player:getLostHp() do
      local card_id = room:askForAG(player, card_ids, true, self.name)
      if card_id == nil then break end
      room:takeAG(player, card_id, room.players)
      table.insert(get, card_id)
      table.removeOne(card_ids, card_id)
      if #card_ids == 0 then break end
    end
    table.forEach(room.players, function(p)
      room:closeAG(p)
    end)
    if #get > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    if #card_ids > 0 then
      if #card_ids == 1 then
        room:moveCards({
          ids = card_ids,
          fromArea = Card.Processing,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
        })
      else
        room:askForGuanxing(player, card_ids, {0, 0}, nil)
      end
    end
  end,
}
local fensi = fk.CreateTriggerSkill{
  name = "fensi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
      return p.hp >= player.hp end), function(p) return p.id end), 1, 1, "#fensi-choose", self.name, false)[1]
    if to then
      to = room:getPlayerById(to)
    else
      to = player
    end
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = self.name,
    }
    if not to.dead and to ~= player then
      room:useVirtualCard("slash", nil, to, player, self.name, true)
    end
  end,
}
local juetao = fk.CreateTriggerSkill{  --FIXME: not target filter!
  name = "juetao",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player.hp == 1 and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id
    end), 1, 1, "#juetao-choose", self.name, false)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    while true do
      if player.dead or to.dead then return end
      local id = room:getNCards(1, "bottom")[1]
      room:moveCards({
        ids = {id},
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
      local card = Fk:getCardById(id, true)
      local tos
      if (card.trueName == "slash") or
        ((table.contains({"dismantlement", "snatch", "chasing_near"}, card.name)) and not to:isAllNude()) or
        (table.contains({"fire_attack", "unexpectation"}, card.name) and not to:isKongcheng()) or
        (table.contains({"duel", "savage_assault", "archery_attack", "iron_chain"}, card.name)) or
        (table.contains({"indulgence", "supply_shortage"}, card.name) and not to:hasDelayedTrick(card.name)) then
        tos = {{to.id}}
      elseif (table.contains({"amazing_grace", "god_salvation"}, card.name)) then
        tos = {{player.id}, {to.id}}
      elseif (card.name == "collateral" and to:getEquipment(Card.SubtypeWeapon)) then
        tos = {{to.id}, {player.id}}
      elseif (card.type == Card.TypeEquip) or
        (card.name == "peach" and player:isWounded()) or 
        (card.name == "analeptic") or
        (table.contains({"ex_nihilo", "foresight"}, card.name)) or
        (card.name == "fire_attack" and not player:isKongcheng()) or
        (card.name == "lightning" and not player:hasDelayedTrick("lightning")) then
        tos = {{player.id}}
      end
      if tos and room:askForSkillInvoke(player, self.name, data, "#juetao-use:::"..card:toLogString()) then
        room:useCard({
          card = card,
          from = player.id,
          tos = tos,
          skillName = self.name,
          extraUse = true,
        })
      else
        room:delay(800)
        room:moveCards({
          ids = {id},
          fromArea = Card.Processing,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
        })
        return
      end
    end
  end,
}
local zhushi = fk.CreateTriggerSkill{
  name = "zhushi$",
  anim_type = "drawcard",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase ~= Player.NotActive and target.kingdom == "wei" and player:usedSkillTimes(self.name) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(target, {"zhushi_draw", "Cancel"}, self.name, "#zhushi-invoke:"..player.id)
    if choice == "zhushi_draw" then
      player:drawCards(1)
    end
  end,
}
caomao:addSkill(qianlong)
caomao:addSkill(fensi)
caomao:addSkill(juetao)
caomao:addSkill(zhushi)
Fk:loadTranslationTable{
  ["caomao"] = "曹髦",
  ["qianlong"] = "潜龙",
  [":qianlong"] = "当你受到伤害后，你可以展示牌堆顶的三张牌并获得其中至多X张牌（X为你已损失的体力值），然后将剩余的牌置于牌堆底。",
  ["fensi"] = "忿肆",
  [":fensi"] = "锁定技，准备阶段，你对一名体力值不小于你的角色造成1点伤害；若受伤角色不为你，则其视为对你使用一张【杀】。",
  ["juetao"] = "决讨",
  [":juetao"] = "限定技，出牌阶段开始时，若你的体力值为1，你可以选择一名角色并依次使用牌堆底的牌直到你无法使用，这些牌不能指定除你和该角色以外的角色为目标。",
  ["zhushi"] = "助势",
  [":zhushi"] = "主公技，其他魏势力角色每回合限一次，该角色回复体力时，你可以令其选择是否令你摸一张牌。",
  ["#fensi-choose"] = "忿肆：你须对一名体力值不小于你的角色造成1点伤害，若不为你，视为其对你使用【杀】",
  ["#juetao-choose"] = "决讨：你可以指定一名角色，连续对其使用牌堆底牌直到不能使用！",
  ["#juetao-use"] = "决讨：是否使用%arg！",
  ["#zhushi-invoke"] = "助势：你可以令 %src 摸一张牌",
  ["zhushi_draw"] = "其摸一张牌",
}

local yanrou = General(extension, "yanrou", "wei", 4)
local choutao = fk.CreateTriggerSkill{
  name = "choutao",
  anim_type = "offensive",
  events ={fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and data.firstTarget and
      not player.room:getPlayerById(data.from):isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#choutao-invoke::"..data.from)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local id = room:askForCardChosen(player, from, "he", self.name)
    room:throwCard({id}, self.name, from, player)
    data.disresponsive = true
    if data.from == player.id then
      player:addCardUseHistory(data.card.trueName, -1)
    end
  end,
}
local xiangshu = fk.CreateTriggerSkill{
  name = "xiangshu",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and player:getMark("xiangshu-turn") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return p:isWounded() end), function (p) return p.id end)
    if #targets == 0 then return end
    local n = math.min(player:getMark("xiangshu-turn"), 5)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#xiangshu-invoke:::"..n..":"..n, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local n = math.min(player:getMark("xiangshu-turn"), 5)
    room:recover({
      who = to,
      num = math.min(n, to:getLostHp()),
      recoverBy = player,
      skillName = self.name
    })
    to:drawCards(n, self.name)
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "xiangshu-turn", data.damage)
  end,
}
yanrou:addSkill(choutao)
yanrou:addSkill(xiangshu)
Fk:loadTranslationTable{
  ["yanrou"] = "阎柔",
  ["choutao"] = "仇讨",
  [":choutao"] = "当你使用【杀】指定目标后或成为【杀】的目标后，你可以弃置使用者一张牌，令此【杀】不能被响应；若你是使用者，则此【杀】不计入次数限制。",
  ["xiangshu"] = "襄戍",
  [":xiangshu"] = "限定技，结束阶段，若你本回合造成过伤害，你可令一名已受伤角色回复X点体力并摸X张牌（X为你本回合造成的伤害值且最多为5）。",
  ["#choutao-invoke"] = "仇讨：你可以弃置 %dest 一张牌令此【杀】不能被响应；若为你则此【杀】不计次",
  ["#xiangshu-invoke"] = "襄戍：你可令一名已受伤角色回复%arg点体力并摸%arg2张牌",
}
--local godjiangwei = General(extension, "godjiangwei", "god", 4)
local tianren = fk.CreateTriggerSkill {
  name = "tianren",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      self.tianren_num = 0
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then  --TODO: REASON!!!
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card.type == Card.TypeBasic or (card.type == Card.TypeTrick and card.sub_type ~= Card.SubtypeDelayedTrick) then
              self.tianren_num = self.tianren_num + 1
            end
          end
        end
      end
      return self.tianren_num > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for i = 1, self.tianren_num, 1 do
      room:addPlayerMark(player, "@tianren", 1)
      if player:getMark("@tianren") >= player.maxHp then
        room:removePlayerMark(player, "@tianren", player.maxHp)
        room:changeMaxHp(player, 1)
        player:drawCards(2)
      end
    end
  end,
}
--godjiangwei:addSkill(tianren)
Fk:loadTranslationTable{
  ["godjiangwei"] = "神姜维",
  ["tianren"] = "天任",
  [":tianren"] = "锁定技，当一张基本牌或普通锦囊牌不是因使用而置入弃牌堆后，你获得1个“天任”标记，然后若“天任”标记数不小于X，你移去X个“天任”标记，加1点体力上限并摸两张牌（X为你的体力上限）。",
  ["jiufa"] = "九伐",
  [":jiufa"] = "当你每累计使用或打出九张不同牌名的牌后，你可以亮出牌堆顶的九张牌，然后若其中有点数相同的牌，你选择并获得其中每个重复点数的牌各一张。",
  ["pingxiang"] = "平襄",
  [":pingxiang"] = "限定技，出牌阶段，若你的体力上限大于9，你可以减9点体力上限，然后你视为使用至多九张火【杀】。若如此做，你失去技能〖九伐〗且本局游戏内你的手牌上限等于体力上限。",
  ["@tianren"] = "天任",
}
--骆统 张媱 张勋 滕胤 神马超 黄承彦2022.6.15
local zhangxun = General(extension, "zhangxun", "qun", 4)
local suizheng = fk.CreateTriggerSkill{
  name = "suizheng",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish
      else
        return target:getMark("@@suizheng-turn") > 0 and target.phase == Player.Play and player.tag[self.name] and #player.tag[self.name] > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets, prompt
    if player.phase == Player.Finish then
      targets = table.map(room:getAlivePlayers(), function (p) return p.id end)
      prompt = "#suizheng-choose"
    else
      room:setPlayerMark(player, "@@suizheng-turn", 1)
      targets = table.filter(player.tag[self.name], function(id) return not room:getPlayerById(id).dead end)
      player.tag[self.name] = {}
      if #targets == 0 then return end
      prompt = "#suizheng-slash"
    end
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if player.phase == Player.Finish then
      room:setPlayerMark(to, "@@suizheng", 1)
    else
      room:useVirtualCard("slash", nil, player, to, self.name, true)
    end
  end,

  refresh_events = {fk.EventPhaseStart, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:getMark("@@suizheng") > 0 and player.phase == Player.Play
    else
      return player:hasSkill(self.name, true) and target:getMark("@@suizheng-turn") > 0 and data.to ~= player and not data.to.dead
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      room:setPlayerMark(player, "@@suizheng", 0)
      room:setPlayerMark(player, "@@suizheng-turn", 1)
    else
      player.tag[self.name] = player.tag[self.name] or {}
      table.insert(player.tag[self.name], data.to.id)
    end
  end,
}
local suizheng_targetmod = fk.CreateTargetModSkill{
  name = "#suizheng_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@suizheng-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
  distance_limit_func =  function(self, player, skill)
    if skill.trueName == "slash_skill" and player:getMark("@@suizheng-turn") > 0 then
      return 999
    end
  end,
}
suizheng:addRelatedSkill(suizheng_targetmod)
zhangxun:addSkill(suizheng)
Fk:loadTranslationTable{
  ["zhangxun"] = "张勋",
  ["suizheng"] = "随征",
  [":suizheng"] = "结束阶段，你可以选择一名角色，该角色下个回合的出牌阶段使用【杀】无距离限制且可以多使用一张【杀】。然后其出牌阶段结束时，你可以视为对其本阶段造成过伤害的一名其他角色使用一张【杀】。",
  ["@@suizheng"] = "随征",
  ["@@suizheng-turn"] = "随征",
  ["#suizheng-choose"] = "随征：令一名角色下回合出牌阶段使用【杀】无距离限制且次数+1",
  ["#suizheng-slash"] = "随征：你可以视为对其中一名角色使用【杀】",
}

local guanning = General(extension, "guanning", "qun", 3, 7)
local dunshi = fk.CreateViewAsSkill{
  name = "dunshi",
  pattern = "slash,jink,peach,analeptic",
  interaction = function()
    local names = {"slash", "jink", "peach", "analeptic"}
    local mark = Self:getMark("dunshi")
    if mark ~= 0 then
      for _, name in ipairs(mark) do
        table.removeOne(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    Fk:currentRoom():setPlayerMark(player, "dunshi_name-turn", use.card.trueName)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and (player:getMark(self.name) == 0 or #player:getMark(self.name) < 4)
  end,
  enabled_at_response = function(self, player, response)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and (player:getMark(self.name) == 0 or #player:getMark(self.name) < 4)
  end,
}
local dunshi_record = fk.CreateTriggerSkill{
  name = "#dunshi_record",
  anim_type = "special",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target.phase ~= Player.NotActive and player:usedSkillTimes("dunshi", Player.HistoryTurn) > 0 then
      if target:getMark("dunshi-turn") == 0 then
        player.room:addPlayerMark(target, "dunshi-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"dunshi1", "dunshi2", "dunshi3"}
    for i = 1, 2, 1 do
      local choice = room:askForChoice(player, choices, self.name)
      table.removeOne(choices, choice)
      if choice == "dunshi1" then
        local skills = {}
        for _, general in ipairs(Fk:getAllGenerals()) do
          for _, skill in ipairs(general.skills) do
            local str = Fk:translate(skill.name)
            if not target:hasSkill(skill) and
              (string.find(str, "仁") or string.find(str, "义") or string.find(str, "礼") or string.find(str, "智") or string.find(str, "信")) then
              table.insertIfNeed(skills, skill.name)
            end
          end
        end
        if #skills > 0 then
          local skill = room:askForChoice(player, table.random(skills, math.min(3, #skills)), self.name, "#dunshi-chooseskill::"..target.id)
          room:handleAddLoseSkills(target, skill, nil, true, false)
        end
      elseif choice == "dunshi2" then
        room:changeMaxHp(player, -1)
        if not player.dead and player:getMark("dunshi") ~= 0 then
          player:drawCards(#player:getMark("dunshi"), "dunshi")
        end
      elseif choice == "dunshi3" then
        local mark = player:getMark("dunshi")
        if mark == 0 then
          mark = {}
        end
        table.insert(mark, player:getMark("dunshi_name-turn"))
        room:setPlayerMark(player, "dunshi", mark)
      end
    end
    if not table.contains(choices, "dunshi1") then
      return true
    end
  end,
}
dunshi:addRelatedSkill(dunshi_record)
guanning:addSkill(dunshi)
Fk:loadTranslationTable{
  ["guanning"] = "管宁",
  ["dunshi"] = "遁世",
  [":dunshi"] = "每回合限一次，你可视为使用或打出一张【杀】，【闪】，【桃】或【酒】。然后当前回合角色本回合下次造成伤害时，你选择两项：<br>"..
  "1.防止此伤害，选择1个包含“仁义礼智信”的技能令其获得；<br>"..
  "2.减1点体力上限并摸X张牌（X为你选择3的次数）；<br>"..
  "3.删除你本次视为使用的牌名。",
  ["#dunshi_record"] = "遁世",
  ["dunshi1"] = "防止此伤害，选择1个“仁义礼智信”的技能令其获得",
  ["dunshi2"] = "减1点体力上限并摸X张牌",
  ["dunshi3"] = "删除你本次视为使用的牌名",
  ["#dunshi-chooseskill"] = "遁世：选择令%dest获得的技能",

  ["$dunshi1"] = "失路青山隐，藏名白水游。",
  ["$dunshi2"] = "隐居青松畔，遁走孤竹丘。",
  ["~guanning"] = "高节始终，无憾矣。",
}
--刘虞 曹华2022.7.18
--local liuyu = General(extension, "ty__liuyu", "qun", 3)
local suifu = fk.CreateTriggerSkill{
  name = "suifu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Finish and player:getMark("suifu-turn") > 1 and
      not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#suifu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = target.player_cards[Player.Hand]
    room:moveCards({
      ids = cards,
      from = target.id,
      fromArea = Player.Hand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    for i = 1, #cards, 1 do
      table.insert(room.draw_pile, 1, cards[i])
      table.remove(room.draw_pile, #room.draw_pile)  --FIXME: ？？？
    end
    room:useVirtualCard("amazing_grace", nil, player, table.filter(room:getAlivePlayers(), function (p)
      return not player:isProhibited(p, Fk:cloneCard("amazing_grace")) end), self.name, false)
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and (target == player or target.seat == 1)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "suifu-turn", data.damage)
  end,
}
local pijing = fk.CreateTriggerSkill{
  name = "pijing",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function (p)
      return p.id end), 1, 10, "#pijing-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill("zimu", true) then
        room:handleAddLoseSkills(p, "-zimu", nil, true, false)
      end
    end
    if not table.contains(self.cost_data, player.id) then
      table.insert(self.cost_data, 1, player.id)
    end
    for _, id in ipairs(self.cost_data) do
      room:handleAddLoseSkills(room:getPlayerById(id), "zimu", nil, true, false)
    end
  end,
}
local zimu = fk.CreateTriggerSkill{
  name = "zimu",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:hasSkill("zimu", true) then
        p:drawCards(1, self.name)
      end
    end
    room:handleAddLoseSkills(player, "-zimu", nil, true, false)
  end,
}
--liuyu:addSkill(suifu)
--liuyu:addSkill(pijing)
--liuyu:addRelatedSkill(zimu)
Fk:loadTranslationTable{
  ["ty__liuyu"] = "刘虞",
  ["suifu"] = "绥抚",
  [":suifu"] = "其他角色的结束阶段，若本回合你和一号位共计至少受到两点伤害，你可将当前回合角色的所有手牌置于牌堆顶，视为使用一张【五谷丰登】。",
  ["pijing"] = "辟境",
  [":pijing"] = "结束阶段，你可选择包含你的任意名角色，这些角色获得〖自牧〗直到下次发动〖辟境〗。",
  ["zimu"] = "自牧",
  [":zimu"] = "锁定技，当你受到伤害后，其他有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗。",
  ["#suifu-invoke"] = "绥抚：你可以将 %dest 所有手牌置于牌堆顶，你视为使用【五谷丰登】",
  ["#pijing-choose"] = "辟境：你可以令包括你的任意名角色获得技能〖自牧〗直到下次发动〖辟境〗<br>（锁定技，当你受到伤害后，其他有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗）",
}

return extension
