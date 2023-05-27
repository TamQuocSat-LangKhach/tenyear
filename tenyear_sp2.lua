local extension = Package("tenyear_sp2")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_sp2"] = "十周年专属2",
}

local liuzan = General(extension, "ty__liuzan", "wu", 4)
local ty__fenyin = fk.CreateTriggerSkill{
  name = "ty__fenyin",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase ~= Player.NotActive then
      local room = player.room
      self.fenyin_draw = 0
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            room:addPlayerMark(player, "liji-turn", 1)  --move this to liji would be proper...
            local mark = "fenyin_"..Fk:getCardById(info.cardId):getSuitString().."-turn"
            if player:getMark(mark) == 0 then
              room:addPlayerMark(player, mark, 1)
              self.fenyin_draw = self.fenyin_draw + 1
            end
          end
        end
      end
      return self.fenyin_draw > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.fenyin_draw, self.name)
  end,
}
local liji = fk.CreateActiveSkill{
  name = "liji",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local n = 8
    if #Fk:currentRoom().alive_players < 5 then n = 4 end
    return player:getMark("liji-turn") >= n and player:usedSkillTimes(self.name, Player.HistoryPhase) < player:getMark("liji-turn")/n
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end,
}
liuzan:addSkill(ty__fenyin)
liuzan:addSkill(liji)
Fk:loadTranslationTable{
  ["ty__liuzan"] = "留赞",
  ["ty__fenyin"] = "奋音",
  [":ty__fenyin"] = "锁定技，你的回合内，每当有一种花色的牌进入弃牌堆后（每回合每种花色各限一次），你摸一张牌。",
  ["liji"] = "力激",
  [":liji"] = "出牌阶段限0次，你可以弃置一张牌然后对一名其他角色造成1点伤害。你的回合内，本回合进入弃牌堆的牌每次达到8的倍数张时（存活人数小于5时改为4的倍数），此技能使用次数+1。",

  ["$ty__fenyin1"] = "斗志高歌，士气昂扬！",
  ["$ty__fenyin2"] = "抗音而歌，左右应之！",
  ["$liji1"] = "破敌搴旗，未尝负败！",
  ["$liji2"] = "鸷猛壮烈，万人不敌！",
  ["~ty__liuzan"] = "若因病困此，命矣。",
}

local hejin = General(extension, "ty__hejin", "qun", 4)
local ty__mouzhu = fk.CreateActiveSkill{
  name = "ty__mouzhu",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= Self.id and (target:distanceTo(Self) == 1 or target.hp == Self.hp) and not target:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, p in ipairs(effect.tos) do
      local target = room:getPlayerById(p)
      if player.dead or target.dead then return end
      if not target:isKongcheng() then
        local card = room:askForCard(target, 1, 1, false, self.name, false, ".", "#mouzhu-give::"..player.id)
        room:obtainCard(player, card[1], false, fk.ReasonGive)
        if #player.player_cards[Player.Hand] > #target.player_cards[Player.Hand] then
          local choice = room:askForChoice(target, {"slash", "duel"}, self.name)
          room:useVirtualCard(choice, nil, target, player, self.name, true)
        end
      end
    end
  end,
}
local ty__yanhuo = fk.CreateTriggerSkill{
  name = "ty__yanhuo",
  anim_type = "offensive",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#yanhuo-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player.room:setTag("yanhuo", true)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room:getTag("yanhuo") and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
}
hejin:addSkill(ty__mouzhu)
hejin:addSkill(ty__yanhuo)
Fk:loadTranslationTable{
  ["ty__hejin"] = "何进",
  ["ty__mouzhu"] = "谋诛",
  [":ty__mouzhu"] = "出牌阶段限一次，你可以选择任意名与你距离为1或体力值与你相同的其他角色，依次将一张手牌交给你，然后若其手牌数小于你，其视为对你使用一张【杀】或【决斗】。",
  ["ty__yanhuo"] = "延祸",
  [":ty__yanhuo"] = "当你死亡时，你可以令本局接下来所有【杀】的伤害基数值+1。",
  ["#mouzhu-give"] = "谋诛：交给%dest一张手牌，然后若你手牌数小于其，视为你对其使用【杀】或【决斗】",
  ["#yanhuo-invoke"] = "延祸：你可以令本局接下来所有【杀】的伤害基数值+1！",
}

Fk:loadTranslationTable{
  ["caoxing"] = "曹性",
  ["liushi"] = "流矢",
  [":liushi"] = "出牌阶段，你可以将一张红桃牌置于牌堆顶，视为对一名角色使用一张【杀】（不计入次数且无距离限制）。若此【杀】造成伤害，该角色手牌上限-1。",
  ["zhanwan"] = "斩腕",
  [":zhanwan"] = "锁定技，受到〖流矢〗效果影响的角色若弃牌阶段有弃牌，你摸等量的牌，然后移除〖流矢〗的效果。",
}
local liubian = General(extension, "liubian", "qun", 3)
local shiyuan = fk.CreateTriggerSkill{
  name = "shiyuan",
  anim_type = "drawcard",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.from ~= player.id then
      local from = player.room:getPlayerById(data.from)
      local n = 1
      if player:hasSkill("yuwei") and player.room.current.kingdom == "qun" then
        n = 2
      end
      return (from.hp > player.hp and player:getMark("shiyuan1-turn") < n) or
      (from.hp == player.hp and player:getMark("shiyuan2-turn") < n) or
      (from.hp < player.hp and player:getMark("shiyuan3-turn") < n)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if from.hp > player.hp then
      player:drawCards(3, self.name)
      room:addPlayerMark(player, "shiyuan1-turn", 1)
    elseif from.hp == player.hp then
      player:drawCards(2, self.name)
      room:addPlayerMark(player, "shiyuan2-turn", 1)
    elseif from.hp < player.hp then
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "shiyuan3-turn", 1)
    end
  end,
}
local dushi = fk.CreateTriggerSkill{
  name = "dushi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying, fk.AfterDying, fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:addPlayerMark(p, self.name, 1)
      end
    elseif event == fk.AfterDying then
      for _, p in ipairs(room:getAllPlayers()) do  --FIXME: 错误的，这样插结中也不能使用桃
        room:setPlayerMark(p, self.name, 0)
      end
    elseif event == fk.Death then
      local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
        return not p:hasSkill(self.name) end), function (p) return p.id end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#dushi-choose", self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(targets)
      end
      room:handleAddLoseSkills(room:getPlayerById(to), self.name, nil, true, false)
    end
  end,
}
local dushi_prohibit = fk.CreateProhibitSkill{
  name = "#dushi_prohibit",
  frequency = Skill.Compulsory,
  prohibit_use = function(self, player, card)
    return card.name == "peach" and player:getMark("dushi") > 0
  end,
}
local yuwei = fk.CreateTriggerSkill{
  name = "yuwei$",
  frequency = Skill.Compulsory,
}
dushi:addRelatedSkill(dushi_prohibit)
liubian:addSkill(shiyuan)
liubian:addSkill(dushi)
liubian:addSkill(yuwei)
Fk:loadTranslationTable{
  ["liubian"] = "刘辩",
  ["shiyuan"] = "诗怨",
  [":shiyuan"] = "每回合每项限一次，当你成为其他角色使用牌的目标后：1.若其体力值比你多，你摸三张牌；2.若其体力值与你相同，你摸两张牌；3.若其体力值比你少，你摸一张牌。",
  ["dushi"] = "毒逝",
  [":dushi"] = "锁定技，你处于濒死状态时，其他角色不能对你使用【桃】。你死亡时，你选择一名其他角色获得〖毒逝〗。",
  ["yuwei"] = "余威",
  [":yuwei"] = "主公技，锁定技，其他群雄角色的回合内，〖诗怨〗改为“每回合每项限两次”。",
  ["#dushi-choose"] = "毒逝：令一名其他角色获得〖毒逝〗",
}
--刘宏 朱儁 韩遂 许劭 王荣 丁原 韩馥 2020.12.28
local zhujun = General(extension, "ty__zhujun", "qun", 4)
local gongjian = fk.CreateTriggerSkill{
  name = "gongjian",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.card.trueName == "slash" and data.firstTarget and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      return self.gongjian_to and #self.gongjian_to > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(self.gongjian_to, function(id) return not room:getPlayerById(id):isNude() end)
    local tos = room:askForChoosePlayers(player, targets, 1, 10, "#gongjian-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local cards = room:askForCardsChosen(player, room:getPlayerById(id), 1, 2, "he", self.name)
      local dummy = Fk:cloneCard("dilu")
      for i = #cards, 1, -1 do
        if Fk:getCardById(cards[i]).trueName == "slash" then
          dummy:addSubcard(cards[i])
          table.removeOne(cards, cards[i])
        end
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, false, fk.ReasonPrey)
      end
      if #cards > 0 then
        room:throwCard(cards, self.name, room:getPlayerById(id), player)
      end
    end
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card.trueName == "slash" and data.firstTarget
  end,
  on_refresh = function(self, event, target, player, data)
    self.gongjian_to = {}
    player.tag[self.name] = player.tag[self.name] or {}
    if #AimGroup:getAllTargets(data.tos) > 0 then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        if table.contains(player.tag[self.name], id) then
          table.insert(self.gongjian_to, id)
        end
      end
    end
    if #AimGroup:getAllTargets(data.tos) > 0 then
      player.tag[self.name] = AimGroup:getAllTargets(data.tos)
    else
      player.tag[self.name] = {}
    end
  end,
}
local kuimang = fk.CreateTriggerSkill{
  name = "kuimang",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.tag[self.name] and table.contains(player.tag[self.name], target.id)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.tag[self.name] = player.tag[self.name] or {}
    table.insertIfNeed(player.tag[self.name], data.to.id)
  end,
}
zhujun:addSkill(gongjian)
zhujun:addSkill(kuimang)
Fk:loadTranslationTable{
  ["ty__zhujun"] = "朱儁",
  ["gongjian"] = "攻坚",
  [":gongjian"] = "每回合限一次，当一名角色使用【杀】指定目标后，若此【杀】与上一张【杀】有相同的目标，则你可以弃置其中相同目标角色各至多两张牌，你获得其中的【杀】。",
  ["kuimang"] = "溃蟒",
  [":kuimang"] = "锁定技，当一名角色死亡时，若你对其造成过伤害，你摸两张牌。",
  ["#gongjian-choose"] = "攻坚：你可以选择其中相同的目标角色，弃置每名角色各至多两张牌，你获得其中的【杀】",
}

Fk:loadTranslationTable{
  ["ty__hansui"] = "韩遂",
  ["ty__niluan"] = "逆乱",
  [":ty__niluan"] = "出牌阶段，你可以将一张黑色牌当【杀】使用；你以此法使用的【杀】结算后，若此【杀】未造成伤害，其不计入使用次数限制。",
  ["weiwu"] = "违忤",
  [":weiwu"] = "出牌阶段限一次，你可以将一张红色牌当【顺手牵羊】对手牌数大于等于你的角色使用。",
}

Fk:loadTranslationTable{
  ["ty__wangrongh"] = "王荣",
  ["minsi"] = "敏思",
  [":minsi"] = "出牌阶段限一次，你可以弃置任意张点数之和为13的牌，并摸两倍的牌。本回合以此法获得的牌中，黑色牌无距离限制，红色牌不计入手牌上限。",
  ["jijing"] = "吉境",
  [":jijing"] = "当你受到伤害后，你可以判定，然后你可以弃置任意张点数之和等于判定结果的牌，若如此做，你回复1点体力",
  ["zhuide"] = "追德",
  [":zhuide"] = "当你死亡时，你可以令一名其他角色摸四张不同牌名的基本牌。",
}
--华歆 2021.2.3
Fk:loadTranslationTable{
  ["ty__huaxin"] = "华歆",
  ["wanggui"] = "望归",
  [":wanggui"] = "当你造成伤害后，你可以对与你势力不同的一名角色造成1点伤害（每回合限一次）；当你受到伤害后，你可令一名与你势力相同的角色摸一张牌，若不为你，你也摸一张牌。",
  ["xibing"] = "息兵",
  [":xibing"] = "每回合限一次，当一名其他角色在其出牌阶段内使用黑色【杀】或黑色普通锦囊牌指定唯一角色为目标后，你可令该角色将手牌摸至体力值（至多摸至五张），然后其本回合不能再使用牌。",
}

local guozhao = General(extension, "guozhao", "wei", 3, 3, General.Female)
local pianchong = fk.CreateTriggerSkill{
  name = "pianchong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    table.insertTable(cards, room:getCardsFromPileByRule(".|.|heart,diamond"))
    table.insertTable(cards, room:getCardsFromPileByRule(".|.|spade,club"))
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
    local choice = room:askForChoice(player, {"red", "black"}, self.name)
    room:setPlayerMark(player, "@pianchong", choice)
    return true
  end,

  refresh_events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) and not player.dead and player:getMark("@pianchong") ~= 0 then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      else
        local times = 0
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                local color = player:getMark("@pianchong")
                if Fk:getCardById(info.cardId):getColorString() == color then
                  times = times + 1
                end
              end
            end
          end
        end
        if times > 0 then
          player.room:setPlayerMark(player, self.name, times)
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(player, "@pianchong", 0)
    else
      local pattern
      local color = player:getMark("@pianchong")
      if color == "red" then
        pattern = ".|.|spade,club"
      else
        pattern = ".|.|heart,diamond"
      end
      local n = player:getMark(self.name)
      room:setPlayerMark(player, self.name, 0)
      local cards = room:getCardsFromPileByRule(pattern, n)
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,
}
local zunwei = fk.CreateActiveSkill{
  name = "zunwei",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name) == 0 then
      for i = 1, 3, 1 do
        if player:getMark(self.name .. tostring(i)) == 0 then
          return true
        end
      end
    end
    return false
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      local player = Fk:currentRoom():getPlayerById(Self.id)
      return (player:getMark("zunwei1") == 0 and #player.player_cards[Player.Hand] < #target.player_cards[Player.Hand]) or
       (player:getMark("zunwei2") == 0 and #player.player_cards[Player.Equip] < #target.player_cards[Player.Equip]) or
       (player:getMark("zunwei3") == 0 and player:isWounded() and player.hp < target.hp)
    end
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choices = {}
    if player:getMark("zunwei1") == 0 and #player.player_cards[Player.Hand] < #target.player_cards[Player.Hand] then
      table.insert(choices, "zunwei1")
    end
    if player:getMark("zunwei2") == 0 and #player.player_cards[Player.Equip] < #target.player_cards[Player.Equip] then
      table.insert(choices, "zunwei2")
    end
    if player:getMark("zunwei3") == 0 and player:isWounded() and player.hp < target.hp then
      table.insert(choices, "zunwei3")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "zunwei1" then
      player:drawCards(math.min(#target.player_cards[Player.Hand] - #player.player_cards[Player.Hand], 5), self.name)
    elseif choice == "zunwei2" then
      local n = #target.player_cards[Player.Equip] - #player.player_cards[Player.Equip]
      for i = 1, n, 1 do
        local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
        local cards = {}
        for i = 1, #room.draw_pile, 1 do
          local card = Fk:getCardById(room.draw_pile[i])
          for _, type in ipairs(types) do
            if card.sub_type == type and player:getEquipment(type) == nil then
              table.insertIfNeed(cards, room.draw_pile[i])
            end
          end
        end
        if #cards > 0 then
          room:useCard({
            from = player.id,
            tos = {{player.id}},
            card = Fk:getCardById(table.random(cards)),
          })
        end
      end
    elseif choice == "zunwei3" then
      room:recover{
        who = player,
        num = math.min(player:getLostHp(), target.hp - player.hp),
        recoverBy = player,
        skillName = self.name}
    end
    room:setPlayerMark(player, choice, 1)
  end,
}
guozhao:addSkill(pianchong)
guozhao:addSkill(zunwei)
Fk:loadTranslationTable{
  ["guozhao"] = "郭照",
  ["pianchong"] = "偏宠",
  [":pianchong"] = "摸牌阶段，你可以改为从牌堆获得红牌和黑牌各一张，然后选择一项直到你的下回合开始：1.你每失去一张红色牌时摸一张黑色牌，2.你每失去一张黑色牌时摸一张红色牌。",
  ["zunwei"] = "尊位",
  [":zunwei"] = "出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一项，然后移除该选项：1.将手牌数摸至与该角色相同（最多摸五张）；2.随机使用牌堆中的装备牌至与该角色相同；3.将体力回复至与该角色相同。",
  ["@pianchong"] = "偏宠",
  ["zunwei1"] = "将手牌摸至与其相同（最多摸五张）",
  ["zunwei2"] = "使用装备至与其相同",
  ["zunwei3"] = "回复体力至与其相同",

  ["$pianchong1"] = "得陛下怜爱，恩宠不衰。",
  ["$pianchong2"] = "谬蒙圣恩，光授殊宠。",
  ["$zunwei1"] = "处尊居显，位极椒房。",
  ["$zunwei2"] = "自在东宫，及即尊位。",
  ["~guozhao"] = "我的出身，不配为后？",
}

--陆郁生 2021.3.20
--樊玉凤 2021.4.16
--赵忠 曹嵩 宗预2021.4.28
local zhaozhong = General(extension, "zhaozhong", "qun", 6)
local yangzhong = fk.CreateTriggerSkill{
  name = "yangzhong",
  anim_type = "offensive",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not data.from.dead and not data.to.dead and
      #data.from:getCardIds{Player.Hand, Player.Equip} > 1
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(data.from, 2, 2, true, self.name, true, ".", "#yangzhong-invoke::"..data.to.id) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(data.to, 1, self.name)
  end
}
local huangkong = fk.CreateTriggerSkill{
  name = "huangkong",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:isKongcheng() and player.phase == Player.NotActive and
      (data.card.type == Card.TypeTrick or data.card.trueName == "slash")
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
zhaozhong:addSkill(yangzhong)
zhaozhong:addSkill(huangkong)
Fk:loadTranslationTable{
  ["zhaozhong"] = "赵忠",
  ["yangzhong"] = "殃众",
  [":yangzhong"] = "当你造成或受到伤害后，伤害来源可以弃置两张牌，令受到伤害的角色失去1点体力。",
  ["huangkong"] = "惶恐",
  [":huangkong"] = "锁定技，你的回合外，当你成为【杀】或普通锦囊牌的目标后，若你没有手牌，你摸两张牌。",
  ["#yangzhong-invoke"] = "殃众：你可以弃置两张牌，令 %dest 失去1点体力",
}
--local caosong = General(extension, "caosong", "wei", 4)
Fk:loadTranslationTable{
  ["caosong"] = "曹嵩",
  ["lihui"] = "礼贿",
  [":lihui"] = "摸牌阶段，你可以放弃摸牌，改为将手牌摸至体力上限（最多摸至5张），并将至少一张手牌交给一名其他角色；若你交出的牌数大于上次以此法交出的牌数，你增加1点体力上限并回复1点体力。",
  ["yizheng"] = "翊正",
  [":yizheng"] = "结束阶段，你可以选择1名其他角色。直到你的下回合开始，当该角色造成伤害或回复体力时，若其体力上限小于你，你减1点体力上限，然后此伤害或回复值+1。",
}
Fk:loadTranslationTable{
  ["ty__zongyu"] = "宗预",
  ["qiao"] = "气傲",
  [":qiao"] = "每回合限两次，当你成为其他角色使用牌的目标后，你可以弃置其一张牌，然后你弃置一张牌。",
  ["chengshang"] = "承赏",
  [":chengshang"] = "出牌阶段内限一次，你使用指定其他角色为目标的牌结算后，若此牌没有造成伤害，你可以获得牌堆中所有与此牌花色点数均相同的牌。若你没有因此获得牌，此技能视为未发动过。",
}
--夏侯杰 阮瑀 张邈 唐姬 梁兴
local liangxing = General(extension, "liangxing", "qun", 4)
local lulve = fk.CreateTriggerSkill{
  name = "lulve",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
      not table.every(player.room:getOtherPlayers(player), function(p)
        return (#p.player_cards[Player.Hand] >= #player.player_cards[Player.Hand] or p:isKongcheng()) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (#p.player_cards[Player.Hand] < #player.player_cards[Player.Hand] and not p:isKongcheng()) end),
      function(p) return p.id end),
      1, 1, "#lulve-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choice = room:askForChoice(to, {"lulve_give", "lulve_slash"}, self.name)
    if choice == "lulve_give" then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(to:getCardIds(Player.Hand))
      room:obtainCard(player.id, dummy, false, fk.ReasonGive)
      player:turnOver()
    else
      to:turnOver()
      local slash = Fk:cloneCard("slash")
      slash.skillName = self.name
        room:useCard({
          card = slash,
          from = to.id,
          tos = {{player.id}},
        })
    end
  end,
}
local zhuixi = fk.CreateTriggerSkill{
  name = "zhuixi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and data.to and ((data.from.faceup and not data.to.faceup) or (not data.from.faceup and data.to.faceup))
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
liangxing:addSkill(lulve)
liangxing:addSkill(zhuixi)
Fk:loadTranslationTable{
  ["liangxing"] = "梁兴",
  ["lulve"] = "掳掠",
  [":lulve"] = "出牌阶段开始时，你可以令一名有手牌且手牌数小于你的其他角色选择一项：1.将所有手牌交给你，然后你翻面；2.翻面，然后视为对你使用一张【杀】。",
  ["zhuixi"] = "追袭",
  [":zhuixi"] = "锁定技，当你对其他角色造成伤害时，或当你受到其他角色造成的伤害时，若你与其翻面状态不同，此伤害+1。",
  ["#lulve-choose"] = "掳掠：你可以令一名有手牌且手牌数小于你的其他角色选择一项",
  ["lulve_give"] = "将所有手牌交给其，其翻面",
  ["lulve_slash"] = "你翻面，视为对其使用【杀】",

  ["$lulve1"] = "趁火打劫，乘危掳掠。",
  ["$lulve2"] = "天下大乱，掳掠以自保。",
  ["$zhuixi1"] = "得势追击，胜望在握！",
  ["$zhuixi2"] = "诸将得令，追而袭之！",
  ["~liangxing"] = "夏侯渊，你竟敢！",
}

local niujin = General(extension, "ty__niujin", "wei", 4)
local cuirui = fk.CreateActiveSkill{
  name = "cuirui",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    return Self.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected < Self.hp and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      local card = room:askForCardChosen(player, p, "h", self.name)
      room:obtainCard(player, card, false, fk.ReasonPrey)
    end
  end,
}
local ty__liewei = fk.CreateTriggerSkill{
  name = "ty__liewei",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player.phase ~= Player.NotActive
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
niujin:addSkill(cuirui)
niujin:addSkill(ty__liewei)
Fk:loadTranslationTable{
  ["ty__niujin"] = "牛金",
  ["cuirui"] = "摧锐",
  [":cuirui"] = "限定技，出牌阶段，你可以选择至多X名其他角色（X为你的体力值），你获得这些角色各1张手牌。",
  ["ty__liewei"] = "裂围",
  [":ty__liewei"] = "你的回合内，有角色进入濒死状态时，你可以摸1张牌。",
}

local zhangheng = General(extension, "zhangheng", "qun", 8)
local liangjue = fk.CreateTriggerSkill{
  name = "liangjue",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.hp > 1 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black and (info.fromArea == Card.PlayerJudge or info.fromArea == Card.PlayerEquip) then
              return true
            end
          end
        end
        if move.to == player.id and (move.toArea == Card.PlayerJudge or move.toArea == Card.PlayerEquip) then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
    player:drawCards(2, self.name)
  end,
}
local dangzai = fk.CreateTriggerSkill{
  name = "dangzai",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play then
      self.dangzai_tos = {}
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if #p.player_cards[Player.Judge] > 0 then
          for _, j in ipairs(p.player_cards[Player.Judge]) do
            if not player:hasDelayedTrick(Fk:getCardById(j).name) then
              table.insertIfNeed(self.dangzai_tos, p.id)
              break
            end
          end
        end
      end
      return #self.dangzai_tos > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, self.dangzai_tos, 1, 1, "#dangzai-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local ids = {}
    for _, j in ipairs(to.player_cards[Player.Judge]) do
      if not player:hasDelayedTrick(Fk:getCardById(j).name) then
        table.insert(ids, j)
      end
    end
    room:fillAG(player, ids)
    local id = room:askForAG(player, ids, true, self.name)
    room:closeAG(player)
    room:moveCards({
      from = to.id,
      ids = {id},
      to = player.id,
      toArea = Card.PlayerJudge,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
  end,
}
zhangheng:addSkill(liangjue)
zhangheng:addSkill(dangzai)
Fk:loadTranslationTable{
  ["zhangheng"] = "张横",
  ["liangjue"] = "粮绝",
  [":liangjue"] = "锁定技，当有黑色牌进入或者离开你的判定区或装备区时，若你的体力值大于1，你失去1点体力，然后摸两张牌。",
  ["dangzai"] = "挡灾",
  [":dangzai"] = "出牌阶段开始时，你可以将一名其他角色判定区里的一张牌移至你的判定区。",
  ["#dangzai-choose"] = "挡灾：你可以将一名其他角色判定区里的一张牌移至你的判定区",

  ["$liangjue1"] = "行军者，切不可无粮！",
  ["$liangjue2"] = "粮尽援绝，须另谋出路。",
  ["$dangzai1"] = "此处有我，休得放肆！",
  ["$dangzai2"] = "退后，让我来！",
  ["~zhangheng"] = "军粮匮乏。",
}

local yangwan = General(extension, "ty__yangwan", "shu", 3, 3, General.Female)
local youyan = fk.CreateTriggerSkill{
  name = "youyan",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and (player.phase == Player.Play or player.phase == Player.Discard) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          local suits = {"spade", "club", "heart", "diamond"}
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
          end
          if #suits > 0 then
            self.youyan_suits = suits
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = self.youyan_suits
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      table.removeOne(suits, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local zhuihuan = fk.CreateTriggerSkill{
  name = "zhuihuan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, "#zhuihuan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), self.name, 1)
  end,

  refresh_events = {fk.Damaged, fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:getMark(self.name) > 0 then
      if event == fk.Damaged then
        return data.from and not data.from.dead
      else
        return player.phase == Player.Start
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      player.tag["zhuihuan"] = player.tag["zhuihuan"] or {}
      table.insertIfNeed(player.tag["zhuihuan"], data.from.id)
    else
      room:setPlayerMark(player, self.name, 0)
      player.tag["zhuihuan"] = player.tag["zhuihuan"] or {}
      local tos = player.tag["zhuihuan"]
      if #tos > 0 then
        for _, id in ipairs(tos) do
          local to = room:getPlayerById(id)
          if not to.dead then
            if to.hp > player.hp then
              room:damage{
                from = player,
                to = to,
                damage = 2,
                skillName = self.name,
              }
            elseif to.hp < player.hp then
              if #to.player_cards[Player.Hand] < 2 then
                to:throwAllCards("h")
              else
                room:throwCard(table.random(to.player_cards[Player.Hand], 2), self.name, to, to)
              end
            end
          end
        end
      end
    end
  end,
}
yangwan:addSkill(youyan)
yangwan:addSkill(zhuihuan)
Fk:loadTranslationTable{
  ["ty__yangwan"] = "杨婉",
  ["youyan"] = "诱言",
  [":youyan"] = "你的回合内，当你的牌因弃置进入弃牌堆后，你可以从牌堆中获得本次弃牌中没有的花色的牌各一张（出牌阶段、弃牌阶段各限一次）。",
  ["zhuihuan"] = "追还",
  [":zhuihuan"] = "结束阶段，你可以秘密选择一名角色。直到该角色的下个准备阶段，此期间内对其造成过伤害的角色："..
  "若体力值大于该角色，则受到其造成的2点伤害；若体力值小于等于该角色，则随机弃置两张手牌。",
  ["#zhuihuan-choose"] = "追还：选择一名角色，直到其准备阶段，对此期间对其造成过伤害的角色造成伤害或弃牌",
}
--董承 胡车儿 2021.9.19
local dongcheng = General(extension, "ty__dongcheng", "qun", 4)
local xuezhao = fk.CreateActiveSkill{
  name = "xuezhao",
  anim_type = "offensive",
  card_num = 1,
  min_target_num = 1,
  max_target_num = function()
    return Self.maxHp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected < Self.maxHp and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    for _, to in ipairs(effect.tos) do
      local p = room:getPlayerById(to)
      if p:isNude() then
        room:addPlayerMark(p, "xuezhao-phase", 1)
      else
        local card = room:askForCard(p, 1, 1, true, self.name, true, ".", "#xuezhao-give:"..player.id)
        if #card > 0 then
          room:obtainCard(player, Fk:getCardById(card[1]), false, fk.ReasonGive)
          p:drawCards(1, self.name)
          room:addPlayerMark(player, "xuezhao_add-turn", 1)
        else
          room:addPlayerMark(p, "xuezhao-phase", 1)
        end
      end
    end
  end,
}
local xuezhao_targetmod = fk.CreateTargetModSkill{
  name = "#xuezhao_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:getMark("xuezhao_add-turn") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("xuezhao_add-turn")
    end
  end,
}
local xuezhao_record = fk.CreateTriggerSkill{
  name = "#xuezhao_record",

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes("xuezhao", Player.HistoryPhase) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return p:getMark("xuezhao-phase") > 0 end)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(targets) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
}
xuezhao:addRelatedSkill(xuezhao_targetmod)
xuezhao:addRelatedSkill(xuezhao_record)
dongcheng:addSkill(xuezhao)
Fk:loadTranslationTable{
  ["ty__dongcheng"] = "董承",
  ["xuezhao"] = "血诏",
  [":xuezhao"] = "出牌阶段限一次，你可以弃置一张手牌并选择至多X名其他角色（X为你的体力上限），然后令这些角色依次选择是否交给你一张牌，"..
  "若选择是，该角色摸一张牌且你本阶段使用【杀】的次数上限+1；若选择否，该角色本阶段不能响应你使用的牌。",
  ["#xuezhao-give"] = "血诏：交出一张牌并摸一张牌使 %src 使用【杀】次数上限+1；或本阶段不能响应其使用的牌",

  ["$xuezhao1"] = "奉旨行事，莫敢不从？",
  ["$xuezhao2"] = "衣带密诏，当诛曹公！",
  ["~ty__dongcheng"] = "是谁走漏了风声？",
}
--邹氏 2021.9.23
Fk:loadTranslationTable{
  ["zoushi"] = "邹氏",
  ["huoshui"] = "祸水",
  [":huoshui"] = "准备阶段，你可以令至多X名角色（X为你已损失的体力值，至少为1且至多为3）按你选择的顺序依次执行一项：1.本回合所有非锁定技失效；2.交给你一张手牌；3.弃置装备区里的所有牌。",
  ["qingcheng"] = "倾城",
  [":qingcheng"] = "出牌阶段限一次，你可以与一名手牌数不大于你的男性角色交换手牌。",
}
--曹安民 张虎 冯熙 丘力居 何晏 糜芳傅士仁2021.9.24
local fengxi = General(extension, "fengxiw", "wu", 3)
local yusui = fk.CreateTriggerSkill{
  name = "yusui",
  anim_type = "offensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from ~= player.id and data.card.color == Card.Black and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.from)
    room:loseHp(player, 1, self.name)
    if player.dead then return end
    local choices = {}
    if #to.player_cards[Player.Hand] > #player.player_cards[Player.Hand] then
      table.insert(choices, "yusui_discard")
    end
    if to.hp > player.hp then
      table.insert(choices, "yusui_loseHp")
    end
    if #choices > 0 then
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "yusui_discard" then
        if player:isKongcheng() then
          to:throwAllCards("h")
        else
          local n = #to.player_cards[Player.Hand] - #player.player_cards[Player.Hand]
          room:askForDiscard(to, n, n, false, self.name, false)
        end
      else
        room:loseHp(to, to.hp - player.hp, self.name)
      end
    end
  end,
}
local boyan = fk.CreateActiveSkill{
  name = "boyan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= Self.id and #target.player_cards[Player.Hand] < math.min(target.maxHp, 5)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(math.min(target.maxHp, 5) - #target.player_cards[Player.Hand], self.name)
    room:addPlayerMark(target, "boyan-turn", 1)
  end,
}
local boyan_prohibit = fk.CreateProhibitSkill{
  name = "#boyan_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("boyan-turn") > 0
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("boyan-turn") > 0
  end,
}
boyan:addRelatedSkill(boyan_prohibit)
fengxi:addSkill(yusui)
fengxi:addSkill(boyan)
Fk:loadTranslationTable{
  ["fengxiw"] = "冯熙",
  ["yusui"] = "玉碎",
  [":yusui"] = "每回合限一次，当你成为其他角色使用黑色牌的目标后，你可以失去1点体力，然后选择一项：1.令其弃置手牌至与你相同；2.令其失去体力值至与你相同。",
  ["boyan"] = "驳言",
  [":boyan"] = "出牌阶段限一次，你可以选择一名其他角色，该角色将手牌摸至体力上限（最多摸至5张），然后本回合不能使用或打出手牌。",
  ["yusui_discard"] = "令其弃置手牌至与你相同",
  ["yusui_loseHp"] = "令其失去体力值至与你相同",
}

Fk:loadTranslationTable{
  ["qiuliju"] = "丘力居",
  ["koulve"] = "寇略",
  [":koulve"] = "出牌阶段，当你对其他角色造成伤害后，你可以展示其X张手牌（X为其已损失体力值），你获得其中的伤害牌，然后若展示牌中有红色牌，你减1点体力上限（若你没有受伤改为失去1点体力）并摸两张牌。",
  ["suirenq"] = "随认",
  [":suirenq"] = "你死亡时，可以将手牌中伤害牌交给一名其他角色。",
}

Fk:loadTranslationTable{
  ["heyan"] = "何晏",
  ["koulve"] = "崖柴",
  [":koulve"] = "当你受到伤害后，你可令伤害来源选择一项：1.弃置一半手牌（向上取整）；2.其本回合不能再使用手牌，你摸两张牌；3.展示所有手牌，然后交给你一种花色的所有手牌。",
  ["suirenq"] = "清谈",
  [":suirenq"] = "出牌阶段限一次，你可令所有有手牌的角色同时选择一张手牌并展示。你可以获得其中一种花色的牌，然后展示此花色牌的角色各摸一张牌，弃置其它牌。",
}

Fk:loadTranslationTable{
  ["ty__mifangfushiren"] = "糜芳傅士仁",
  ["ty__fengshi"] = "锋势",
  [":ty__fengshi"] = "你使用基本牌或锦囊牌指定其他角色为唯一目标后，若其手牌数小于你，你可以弃置你与其各一张牌，然后此牌伤害+1；<br>"..
  "当你成为其他角色使用基本牌或锦囊牌的唯一目标后，若你手牌数小于其，你可以弃置你与其各一张牌，然后此牌伤害+1。",
}

Fk:loadTranslationTable{
  ["ty__panshu"] = "潘淑",
  ["zhiren"] = "织纴",
  [":zhiren"] = "你的回合内，当你使用本回合的第一张非转化牌时，若X：不小于1，你观看牌堆顶X张牌并以任意顺序放回牌堆顶或牌堆底；不小于2，你至多可以弃置场上的一张装备牌和一张延时锦囊牌；不小于3，你回复1点体力；不小于4，你摸三张牌（X为此牌名称字数）。",
  ["yaner"] = "燕尔",
  [":yaner"] = "每回合限一次，当其他角色于其出牌阶段内失去最后的手牌时，你可以与其各摸两张牌，然后若因此摸到相同类型的两张牌的角色为：你，〖织纴〗改为回合外也可以发动直到你的下个回合开始；其，其回复1点体力。",
}

Fk:loadTranslationTable{
  ["ty__nanhualaoxian"] = "南华老仙",
  ["gongxiu"] = "共修",
  [":gongxiu"] = "结束阶段，若你本回合发动过“经合”，你可以选择一项：1.令所有本回合因“经合”获得过技能的角色摸一张牌；2.令所有本回合未因“经合”获得过技能的其他角色弃置一张手牌。",
  ["jinghe"] = "经合",
  [":jinghe"] = "每回合限一次，出牌阶段，你可展示至多四张牌名各不同的手牌，选择等量的角色，从“写满技能的天书”随机展示四个技能，这些角色依次选择并获得其中一个，直到你下回合开始。",
  ["yinbingn"] = "阴兵",
  [":yinbingn"] = "锁定技，你使用【杀】即将造成的伤害视为失去体力。当其他角色失去体力后，你摸一张牌。",
  ["huoqi"] = "活气",
  [":huoqi"] = "出牌阶段限一次，你可以弃置一张牌，然后令一名体力最少的角色回复1点体力并摸一张牌。",
  ["guizhu"] = "鬼助",
  [":guizhu"] = "每回合限一次，当一名角色进入濒死状态时，你可以摸两张牌。",
  ["xianshou"] = "仙授",
  [":xianshou"] = "出牌阶段限一次，你可以令一名角色摸一张牌。若其未受伤，则多摸一张牌。",
  ["lundao"] = "论道",
  [":lundao"] = "当你受到伤害后，若伤害来源的手牌多于你，你可以弃置其一张牌；若伤害来源的手牌数少于你，你摸一张牌。",
  ["guanyue"] = "观月",
  [":guanyue"] = "结束阶段，你可以观看牌堆顶的两张牌，然后获得其中一张，将另一张置于牌堆顶。",
  ["yanzhengn"] = "言政",
  [":yanzhengn"] = "准备阶段，若你的手牌数大于1，你可以选择一张手牌并弃置其余的牌，然后对至多等于弃置牌数的角色各造成1点伤害。",
}

local zhouyi = General(extension, "zhouyi", "wu", 3, 3, General.Female)
local zhukou = fk.CreateTriggerSkill{
  name = "zhukou",
  anim_type = "offensive",
  events = {fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target == player then
      if event == fk.Damage then
        return player.room.current.phase == Player.Play and player:usedSkillTimes(self.name) == 0
      else
        return player.phase == Player.Finish and player:getMark("zhukou-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      return room:askForSkillInvoke(player, self.name)
    else
      local targets = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
        return p.id end), 2, 2, "#zhukou-choose", self.name, true)
      if #targets == 2 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      player:drawCards(player:getMark("@zhukou-turn"), self.name)
      room:addPlayerMark(player, "zhukou-turn", 1)
      room:setPlayerMark(player, "@zhukou-turn", 0)
    else
      for _, p in ipairs(self.cost_data) do
        room:damage{
          from = player,
          to = room:getPlayerById(p),
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("zhukou-turn") == 0 and player.phase < Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@zhukou-turn", 1)
  end,
}
local mengqing = fk.CreateTriggerSkill{
  name = "mengqing",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 3)
    room:recover({
      who = player,
      num = 3,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "-zhukou|yuyun", nil)
  end,
}
local yuyun = fk.CreateTriggerSkill{
  name = "yuyun",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local chs = {"loseHp"}
    if player.maxHp > 1 then table.insert(chs, "loseMaxHp") end
    local chc = room:askForChoice(player, chs, self.name)
    if chc == "loseMaxHp" then
      room:changeMaxHp(player, -1)
    else
      room:loseHp(player, 1, self.name)
    end
    local choices = {"Cancel", "yuyun1", "yuyun2", "yuyun3"}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isNude() or #p.player_cards[Player.Hand] < p.maxHp then
        if not p:isNude() then
          table.insertIfNeed(choices, "yuyun4")
        end
        if #p.player_cards[Player.Hand] < p.maxHp then
          table.insertIfNeed(choices, "yuyun5")
        end
        break
      end
    end
    local n = 1 + player:getLostHp()
    for i = 1, n, 1 do
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "Cancel" then return end
      table.removeOne(choices, choice)
      if choice == "yuyun1" then
        player:drawCards(2, self.name)
      elseif choice == "yuyun2" then
        local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
          return p.id end), 1, 1, "#yuyun2-choose", self.name)[1]
        room:damage{
          from = player,
          to = room:getPlayerById(to),
          damage = 1,
          skillName = self.name,
        }
        room:addPlayerMark(room:getPlayerById(to), "yuyun2-turn", 1)
      elseif choice == "yuyun3" then
        room:addPlayerMark(player, "yuyun3-turn", 1)
      elseif choice == "yuyun4" then
        local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not p:isAllNude() end), function(p) return p.id end), 1, 1, "#yuyun4-choose", self.name)[1]
        local id = room:askForCardChosen(player, room:getPlayerById(to), "hej", self.name)
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
      elseif choice == "yuyun5" then
        local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
          return #p.player_cards[Player.Hand] < math.min(p.maxHp, 5) end), function(p) return p.id end), 1, 1, "#yuyun5-choose", self.name)[1]
        local p = room:getPlayerById(to)
        p:drawCards(math.min(p.maxHp, 5) - #p.player_cards[Player.Hand], self.name)
      end
    end
  end,

  refresh_events = {fk.TargetSpecifying},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card.trueName == "slash" then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        if player.room:getPlayerById(id):getMark("yuyun2-turn") > 0 then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player:addCardUseHistory(data.card.trueName, -1)
  end
}
local yuyun_distance = fk.CreateDistanceSkill{
  name = "#yuyun_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      if to:getMark("yuyun2-turn") > 0 then
        from:setFixedDistance(to, 1)
      else
        from:removeFixedDistance(to)
      end
    end
    return 0
  end,
}
local yuyun_maxcards = fk.CreateMaxCardsSkill{
  name = "#yuyun_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self.name) and player:getMark("yuyun3-turn") > 0 then
      return 999
    end
    return 0
  end,
}
yuyun:addRelatedSkill(yuyun_distance)
yuyun:addRelatedSkill(yuyun_maxcards)
zhouyi:addSkill(zhukou)
zhouyi:addSkill(mengqing)
zhouyi:addRelatedSkill(yuyun)
Fk:loadTranslationTable{
  ["zhouyi"] = "周夷",
  ["zhukou"] = "逐寇",
  [":zhukou"] = "当你于每回合的出牌阶段第一次造成伤害后，你可以摸X张牌（X为本回合你已使用的牌数）。结束阶段，若你本回合未造成过伤害，你可以对两名其他角色各造成1点伤害。",
  ["mengqing"] = "氓情",
  [":mengqing"] = "觉醒技，准备阶段，若已受伤的角色数大于你的体力值，你加3点体力上限并回复3点体力，失去〖逐寇〗，获得〖玉殒〗。",
  ["yuyun"] = "玉陨",
  [":yuyun"] = "锁定技，出牌阶段开始时，你失去1点体力或体力上限（你的体力上限不能以此法被减至1以下），然后选择X+1项（X为你已损失的体力值）：<br>"..
  "1.摸两张牌；<br>"..
  "2.对一名其他角色造成1点伤害，然后本回合对其使用【杀】无距离和次数限制；<br>"..
  "3.本回合没有手牌上限；<br>"..
  "4.获得一名其他角色区域内的一张牌；<br>"..
  "5.令一名其他角色将手牌摸至体力上限（最多摸至5）。",
  ["@zhukou-turn"] = "逐寇",
  ["#zhukou-choose"] = "逐寇：你可以对两名其他角色各造成1点伤害",
  ["yuyun1"] = "摸两张牌",
  ["yuyun2"] = "对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制",
  ["yuyun3"] = "本回合没有手牌上限",
  ["yuyun4"] = "获得一名其他角色区域内的一张牌",
  ["yuyun5"] = "令一名其他角色将手牌摸至体力上限（最多摸至5）",
  ["#yuyun2-choose"] = "玉陨：对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制",
  ["#yuyun4-choose"] = "玉陨：获得一名其他角色区域内的一张牌",
  ["#yuyun5-choose"] = "玉陨：令一名其他角色将手牌摸至体力上限（最多摸至5）",

  ["$zhukou1"] = "草莽贼寇，不过如此。",
  ["$zhukou2"] = "轻装上阵，利剑出鞘。",
  ["$mengqing1"] = "女之耽兮，不可说也。",
  ["$mengqing2"] = "淇水汤汤，渐车帷裳。",
  ["$yuyun1"] = "春依旧，人消瘦。",
  ["$yuyun2"] = "泪沾青衫，玉殒香消。",
  ["~zhouyi"] = "江水寒，萧瑟起。",
}

local lvlingqi = General(extension, "lvlingqi", "qun", 4, 4, General.Female)
local guowu = fk.CreateTriggerSkill{
  name = "guowu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local types = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    local card = room:getCardsFromPileByRule("slash", 1, "allPiles")
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
    if #types > 1 then
      room:addPlayerMark(player, "guowu2-phase", 1)
    end
    if #types > 2 then
      room:addPlayerMark(player, "guowu3-phase", 1)
    end
  end,

  refresh_events = {fk.TargetSpecifying},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("guowu3-phase") > 0 and data.firstTarget and
      data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not table.contains(AimGroup:getAllTargets(data.tos), p.id) then  --TODO: target filter
        table.insertIfNeed(targets, p.id)
      end
    end
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, targets, 1, 2, "#guowu-choose", self.name, true)
      if #tos > 0 then
        TargetGroup:pushTargets(data.targetGroup, tos)  --TODO: sort by action order
        room:sortPlayersByAction(data.targetGroup)
      end
    end
  end,
}
local guowu_targetmod = fk.CreateTargetModSkill{
  name = "#guowu_targetmod",
  distance_limit_func =  function(self, player, skill)
    if player:hasSkill(self.name) and player:getMark("guowu2-phase") > 0 then
      return 999
    end
  end,
  extra_target_func = function(self, player, skill)
    if player:hasSkill(self.name) and player:getMark("guowu3-phase") > 0 and skill.trueName == "slash_skill" then
      --(card.type == Card.TypeTrick and card.sub_type ~= Card.SubtypeDelayedTrick)  FIXME: fire_attack!
      return 2
    end
  end,
}
local zhuangrong = fk.CreateTriggerSkill{
  name = "zhuangrong",
  frequency = Skill.Wake,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player.player_cards[Player.Hand] == 1 or player.hp == 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = self.name
      })
    end
    local n = player.maxHp - #player.player_cards[Player.Hand]
    if n > 0 then
      player:drawCards(n, self.name)
    end
    room:handleAddLoseSkills(player, "shenwei|wushuang", nil)
  end,
}
local shenwei = fk.CreateTriggerSkill{  --TODO: move this!
  name = "shenwei",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
}
local shenwei_maxcards = fk.CreateMaxCardsSkill{
  name = "#shenwei_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self.name) then
      return 2
    end
  end,
}
guowu:addRelatedSkill(guowu_targetmod)
shenwei:addRelatedSkill(shenwei_maxcards)
lvlingqi:addSkill(guowu)
lvlingqi:addSkill(zhuangrong)
lvlingqi:addRelatedSkill(shenwei)
lvlingqi:addRelatedSkill("wushuang")
Fk:loadTranslationTable{
  ["lvlingqi"] = "吕玲绮",
  ["guowu"] = "帼武",
  [":guowu"] = "出牌阶段开始时，你可以展示所有手牌，若包含的类别数：不小于1，你从弃牌堆中获得一张【杀】；不小于2，你本阶段使用牌无距离限制；不小于3，你本阶段使用【杀】或普通锦囊牌可以多指定两个目标。",
  ["zhuangrong"] = "妆戎",
  [":zhuangrong"] = "觉醒技，一名角色的回合结束时，若你的手牌数或体力值为1，你减1点体力上限并将体力值回复至体力上限，然后将手牌摸至体力上限。若如此做，你获得技能〖神威〗和〖无双〗。",
  ["shenwei"] = "神威",
  [":shenwei"] = "锁定技，摸牌阶段，你额外摸两张牌；你的手牌上限+2。",  --TODO: this should be moved to SP!
  ["#guowu-choose"] = "帼武：可以多指定两个目标",

  ["$guowu1"] = "方天映黛眉，赤兔牵红妆。",
  ["$guowu2"] = "武姬青丝利，巾帼女儿红。",
  ["$zhuangrong1"] = "锋镝鸣手中，锐戟映秋霜。",
  ["$zhuangrong2"] = "红妆非我愿，学武觅封侯。",
  ["$shenwei1"] = "继父神威，无坚不摧！",
  ["$shenwei2"] = "我乃温侯吕奉先之女！",
  ["~lvlingqi"] = "父亲，女儿好累。",
}

return extension
