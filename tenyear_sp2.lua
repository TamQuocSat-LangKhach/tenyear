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
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
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
  [":ty__mouzhu"] = "出牌阶段限一次，你可以选择任意名与你距离为1或体力值与你相同的其他角色，依次将一张手牌交给你，然后若其手牌数小于你，"..
  "其视为对你使用一张【杀】或【决斗】。",
  ["ty__yanhuo"] = "延祸",
  [":ty__yanhuo"] = "当你死亡时，你可以令本局接下来所有【杀】的伤害基数值+1。",
  ["#mouzhu-give"] = "谋诛：交给%dest一张手牌，然后若你手牌数小于其，视为你对其使用【杀】或【决斗】",
  ["#yanhuo-invoke"] = "延祸：你可以令本局接下来所有【杀】的伤害基数值+1！",
}

local caoxing = General(extension, "caoxing", "qun", 4)
local liushi = fk.CreateActiveSkill{
  name = "liushi",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Heart
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), Fk:cloneCard("slash"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    local use = {
      from = player.id,
      tos = {{target.id}},
      card = Fk:cloneCard("slash"),
      skillName = self.name,
      extraUse = true,
    }
    room:useCard(use)
    if use.damageDealt then
      for _, p in ipairs(room.alive_players) do
        if use.damageDealt[p.id] then
          room:addPlayerMark(target, "@@liushi", 1)
        end
      end
    end
  end,
}
local liushi_maxcards = fk.CreateMaxCardsSkill{
  name = "#liushi_maxcards",
  correct_func = function(self, player)
    if player:getMark("@@liushi") > 0 then
      return -1
    end
    return 0
  end,
}
local zhanwan = fk.CreateTriggerSkill{
  name = "zhanwan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Discard and target:getMark("zhanwan-phase") > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(target:getMark("zhanwan-phase"), self.name)
    player.room:setPlayerMark(target, "@@liushi", 0)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@@liushi") > 0 and player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        player.room:addPlayerMark(player, "zhanwan-phase", #move.moveInfo)
      end
    end
  end,
}
liushi:addRelatedSkill(liushi_maxcards)
caoxing:addSkill(liushi)
caoxing:addSkill(zhanwan)
Fk:loadTranslationTable{
  ["caoxing"] = "曹性",
  ["liushi"] = "流矢",
  [":liushi"] = "出牌阶段，你可以将一张<font color='red'>♥</font>牌置于牌堆顶，视为对一名角色使用一张【杀】（不计入次数且无距离限制）。"..
  "受到此【杀】伤害的角色手牌上限-1。",
  ["zhanwan"] = "斩腕",
  [":zhanwan"] = "锁定技，受到〖流矢〗效果影响的角色弃牌阶段结束时，若其于此阶段内弃置过牌，你摸等量的牌，然后移除其〖流矢〗的效果。",
  ["@@liushi"] = "流矢",
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
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
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
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:broadcastSkillInvoke(self.name)
    player.room:notifySkillInvoked(player, self.name)
  end,
}
local dushi_prohibit = fk.CreateProhibitSkill{
  name = "#dushi_prohibit",
  prohibit_use = function(self, player, card)
    if card.name == "peach" and not player.dying then
      return table.find(Fk:currentRoom().alive_players, function(p) return p.dying and p:hasSkill("dushi") and p ~= player end)
    end
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
  [":shiyuan"] = "每回合每项限一次，当你成为其他角色使用牌的目标后：1.若其体力值比你多，你摸三张牌；2.若其体力值与你相同，你摸两张牌；"..
  "3.若其体力值比你少，你摸一张牌。",
  ["dushi"] = "毒逝",
  [":dushi"] = "锁定技，你处于濒死状态时，其他角色不能对你使用【桃】。你死亡时，你选择一名其他角色获得〖毒逝〗。",
  ["yuwei"] = "余威",
  [":yuwei"] = "主公技，锁定技，其他群雄角色的回合内，〖诗怨〗改为“每回合每项限两次”。",
  ["#dushi-choose"] = "毒逝：令一名其他角色获得〖毒逝〗",
}

local huaxin = General(extension, "ty__huaxin", "wei", 3)
local wanggui = fk.CreateTriggerSkill{
  name = "wanggui",
  mute = true,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      return (event == fk.Damage and player:getMark("wanggui-turn") == 0) or event == fk.Damaged
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets, prompt = {}, ""
    if event == fk.Damage then
      targets = table.map(table.filter(room.alive_players, function(p)
        return p.kingdom ~= player.kingdom end), function(p) return p.id end)
      prompt = "#wanggui1-choose"
    else
      targets = table.map(table.filter(room.alive_players, function(p)
        return p.kingdom == player.kingdom end), function(p) return p.id end)
      prompt = "#wanggui2-choose"
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if event == fk.Damage then
      room:setPlayerMark(player, "wanggui-turn", 1)
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
    else
      to:drawCards(1, self.name)
      if to ~= player then
        player:drawCards(1, self.name)
      end
    end
  end,
}
local xibing = fk.CreateTriggerSkill{
  name = "xibing",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Play and data.firstTarget and
      data.card.color == Card.Black and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      target:getHandcardNum() < math.min(target.hp, 5) and #AimGroup:getAllTargets(data.tos) == 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xibing-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(math.min(target.hp, 5) - target:getHandcardNum())
    player.room:setPlayerMark(target, "xibing-turn", 1)
  end,
}
local xibing_prohibit = fk.CreateProhibitSkill{
  name = "#xibing_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("xibing-turn") > 0
  end,
}
xibing:addRelatedSkill(xibing_prohibit)
huaxin:addSkill(wanggui)
huaxin:addSkill(xibing)
Fk:loadTranslationTable{
  ["ty__huaxin"] = "华歆",
  ["wanggui"] = "望归",
  [":wanggui"] = "当你造成伤害后，你可以对与你势力不同的一名角色造成1点伤害（每回合限一次）；当你受到伤害后，你可令一名与你势力相同的角色摸一张牌，"..
  "若不为你，你也摸一张牌。",
  ["xibing"] = "息兵",
  [":xibing"] = "每回合限一次，当一名其他角色在其出牌阶段内使用黑色【杀】或黑色普通锦囊牌指定唯一角色为目标后，你可令该角色将手牌摸至体力值"..
  "（至多摸至五张），然后其本回合不能再使用牌。",
  ["#wanggui1-choose"] = "望归：你可以对一名势力与你不同的角色造成1点伤害",
  ["#wanggui2-choose"] = "望归：你可以令一名势力与你相同的角色摸一张牌，若不为你，你也摸一张牌",
  ["#xibing-invoke"] = "息兵：你可以令 %dest 将手牌摸至体力值（至多五张），然后其本回合不能使用牌",
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
  [":pianchong"] = "摸牌阶段，你可以改为从牌堆获得红牌和黑牌各一张，然后选择一项直到你的下回合开始：1.你每失去一张红色牌时摸一张黑色牌，"..
  "2.你每失去一张黑色牌时摸一张红色牌。",
  ["zunwei"] = "尊位",
  [":zunwei"] = "出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一项，然后移除该选项：1.将手牌数摸至与该角色相同（最多摸五张）；"..
  "2.随机使用牌堆中的装备牌至与该角色相同；3.将体力回复至与该角色相同。",
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
local fanyufeng = General(extension, "fanyufeng", "qun", 3, 3, General.Female)
local bazhan = fk.CreateActiveSkill{
  name = "bazhan",
  anim_type = "switch",
  switch_skill_name = "bazhan",
  target_num = 1,
  max_card_num = function ()
    return (Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 2 or 0
  end,
  min_card_num = function ()
    return (Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 1 or 0
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function(self, to_select, selected)
    return #selected < self:getMaxCardNum() and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected_cards >= self:getMinCardNum() and #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local isYang = player:getSwitchSkillState(self.name, true) == fk.SwitchYang

    local to_cheak = {}
    if isYang and #effect.cards > 0 then
      table.insertTable(to_cheak, effect.cards) 
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(to_cheak)
      room:obtainCard(target.id, dummy, false, fk.ReasonGive)
    elseif not isYang and not target:isKongcheng() then
      to_cheak = room:askForCardsChosen(player, target, 1, 2, "h", self.name)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(to_cheak)
      room:obtainCard(player, dummy, false, fk.ReasonPrey)
      target = player
    end
    if not player.dead and not target.dead and table.find(to_cheak, function (id)
    return Fk:getCardById(id).name == "analeptic" or Fk:getCardById(id).suit == Card.Heart end) then
      local choices = {"cancel"}
      if not target.faceup or target.chained then
        table.insert(choices, 1, "bazhan_reset")
      end
      if target:isWounded() then
        table.insert(choices, 1, "recover")
      end
      if #choices > 1 then
        local choice = room:askForChoice(player, choices, self.name, "#bazhan-support::" .. target.id)
        if choice == "recover" then
          room:recover{ who = target, num = 1, recoverBy = player, skillName = self.name }
        elseif choice == "bazhan_reset" then
          if not target.faceup then
            target:turnOver()
          end
          if target.chained then
            target:setChainState(false)
          end
        end
      end
    end
  end,
}
local jiaoying = fk.CreateTriggerSkill{
  name = "jiaoying",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local to = room:getPlayerById(move.to)
        local jiaoying_colors = type(to:getMark("jiaoying_colors-turn")) == "table" and to:getMark("jiaoying_colors-turn") or {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            local color = Fk:getCardById(info.cardId).color
            if color ~= Card.NoColor then
              table.insertIfNeed(jiaoying_colors, color)
              table.insertIfNeed(jiaoying_targets, to.id)
            end
          end
        end
        room:setPlayerMark(to, "jiaoying_colors-turn", jiaoying_colors)
      end
    end
    room:setPlayerMark(player, "jiaoying_targets-turn", jiaoying_targets)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    return table.contains(jiaoying_targets, target.id) and not table.contains(jiaoying_ignores, target.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    table.insert(jiaoying_ignores, target.id)
    player.room:setPlayerMark(player, "jiaoying_ignores-turn", jiaoying_ignores)
  end,
}
local jiaoying_delay = fk.CreateTriggerSkill{
  name = "#jiaoying_delay",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Finish then
      local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
      local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
      self.cost_data = #jiaoying_targets - #jiaoying_ignores
      if self.cost_data > 0 then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    local targets = player.room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function (p)
      return p:getHandcardNum() < 5 end), function (p)
      return p.id end), 1, x, "#jiaoying-choose:::" .. x, self.name, true)
    if #targets > 0 then
      room:sortPlayersByAction(targets)
      for _, pid in ipairs(targets) do
        local to = room:getPlayerById(pid)
        if not to.dead and to:getHandcardNum() < 5 then
          to:drawCards(5-to:getHandcardNum(), self.name)
        end
      end
    end
  end,
}
local jiaoying_prohibit = fk.CreateProhibitSkill{
  name = "#jiaoying_prohibit",
  prohibit_use = function(self, player, card)
    local jiaoying_colors = player:getMark("jiaoying_colors-turn")
    return type(jiaoying_colors) == "table" and table.contains(jiaoying_colors, card.color)
  end,
}
jiaoying:addRelatedSkill(jiaoying_delay)
jiaoying:addRelatedSkill(jiaoying_prohibit)
fanyufeng:addSkill(bazhan)
fanyufeng:addSkill(jiaoying)
Fk:loadTranslationTable{
  ["fanyufeng"] = "樊玉凤",
  ["bazhan"] = "把盏",
  [":bazhan"] = "转换技，出牌阶段限一次，阳：你可以交给一名其他角色至多两张手牌；阴：你可以获得一名其他角色至多两张手牌。"..
  "然后若这些牌里包括【酒】或<font color='red'>♥</font>牌，你可令获得此牌的角色回复1点体力或复原武将牌。",
  ["jiaoying"] = "醮影",
  ["#jiaoying_delay"] = "醮影",
  [":jiaoying"] = "锁定技，其他角色获得你的手牌后，该角色本回合不能使用或打出与此牌颜色相同的牌。然后此回合结束阶段，"..
  "若其本回合没有再使用牌，你令一名角色将手牌摸至五张（每有一名符合条件的角色便可以选择一个目标）。",
  ["#bazhan-support"] = "把盏：可以选择令 %dest 回复1点体力或复原武将牌",
  ["#jiaoying-choose"] = "醮影：可选择至多%arg名角色将手牌补至5张",

  ["$bazhan1"] = "此酒，当配将军。",
  ["$bazhan2"] = "这杯酒，敬于将军。",
  ["$jiaoying1"] = "独酌清醮，霓裳自舞。",
  ["$jiaoying2"] = "醮影倩丽，何人爱怜。",
  ["~fanyufeng"] = "醮妇再遇良人难……",
}

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

local zongyu = General(extension, "ty__zongyu", "shu", 3)
local qiao = fk.CreateTriggerSkill{
  name = "qiao",
  anim_type = "control",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.from ~= player.id and
      not player.room:getPlayerById(data.from):isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qiao-invoke::"..data.from)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local id = room:askForCardChosen(player, from, "he", self.name)
    room:throwCard(id, self.name, from, player)
    if not player:isNude() then
      room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,
}
local chengshang = fk.CreateTriggerSkill{
  name = "chengshang",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.tos and
      table.find(TargetGroup:getRealTargets(data.tos), function(id) return id ~= player.id end) and not data.damageDealt and
      data.card.suit ~= Card.NoSuit and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil,
      "#chengshang-invoke:::"..data.card:getSuitString()..":"..tostring(data.card.number))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getCardsFromPileByRule(".|"..tostring(data.card.number).."|"..data.card:getSuitString())
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    else
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    end
  end,
}
zongyu:addSkill(qiao)
zongyu:addSkill(chengshang)
Fk:loadTranslationTable{
  ["ty__zongyu"] = "宗预",
  ["qiao"] = "气傲",
  [":qiao"] = "每回合限两次，当你成为其他角色使用牌的目标后，你可以弃置其一张牌，然后你弃置一张牌。",
  ["chengshang"] = "承赏",
  [":chengshang"] = "出牌阶段内限一次，你使用指定其他角色为目标的牌结算后，若此牌没有造成伤害，你可以获得牌堆中所有与此牌花色点数均相同的牌。"..
  "若你没有因此获得牌，此技能视为未发动过。",
  ["#qiao-invoke"] = "气傲：你可以弃置 %dest 一张牌，然后你弃置一张牌",
  ["#chengshang-invoke"] = "承赏：你可以获得牌堆中所有的%arg%arg2牌",
}

local xiahoujie = General(extension, "xiahoujie", "wei", 5)
local liedan = fk.CreateTriggerSkill{
  name = "liedan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Start and player:getMark("@@zhuangdan") == 0 and
      (target ~= player or (target == player and player:getMark("@liedan")) > 4)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target ~= player then
      local n = 0
      if player:getHandcardNum() > target:getHandcardNum() then
        n = n + 1
      end
      if player.hp > target.hp then
        n = n + 1
      end
      if #player.player_cards[Player.Equip] > #target.player_cards[Player.Equip] then
        n = n + 1
      end
      if n > 0 then
        player:drawCards(n, self.name)
        if n == 3 and player.maxHp < 8 then
          room:changeMaxHp(player, 1)
        end
      else
        room:loseHp(player, 1, self.name)
        if not player.dead then
          room:addPlayerMark(player, "@liedan", 1)
        end
      end
    else
      room:killPlayer({who = player.id,})
    end
  end,
}
local zhuangdan = fk.CreateTriggerSkill{
  name = "zhuangdan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and player:getMark("@@zhuangdan") == 0 and
      table.every(player.room:getOtherPlayers(player), function(p) return player:getHandcardNum() > p:getHandcardNum() end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhuangdan", 1)
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@zhuangdan") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhuangdan", 0)
  end,
}
xiahoujie:addSkill(liedan)
xiahoujie:addSkill(zhuangdan)
Fk:loadTranslationTable{
  ["xiahoujie"] = "夏侯杰",
  ["liedan"] = "裂胆",
  [":liedan"] = "锁定技，其他角色的准备阶段，你的手牌数、体力值和装备区里的牌数每有一项大于该角色，便摸一张牌。"..
  "若均大于其，你加1点体力上限（至多加至8）；若均不大于其，你失去1点体力并获得1枚“裂胆”标记。准备阶段，若“裂胆”标记不小于5，你死亡。",
  ["zhuangdan"] = "壮胆",
  [":zhuangdan"] = "锁定技，其他角色的回合结束时，若你的手牌数为全场唯一最大，〖裂胆〗失效直到你的回合结束。",
  ["@liedan"] = "裂胆",
  ["@@zhuangdan"] = "裂胆失效",

  ["$liedan1"] = "声若洪钟，震胆发聩！",
  ["$liedan2"] = "阴雷滚滚，肝胆俱颤！",
  ["$zhuangdan1"] = "我家丞相在此，哪个有胆敢动我？",
  ["$zhuangdan2"] = "假丞相虎威，壮豪将龙胆。",
  ["~xiahoujie"] = "你吼那么大声干嘛……",
}

local ruanyu = General(extension, "ruanyu", "wei", 3)
local xingzuo = fk.CreateTriggerSkill{
  name = "xingzuo",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (player.phase == Player.Play or
    (player.phase == Player.Finish and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Play then
      return room:askForSkillInvoke(player, self.name, nil, "#xingzuo-invoke")
    else
      local targets = table.map(table.filter(room.alive_players, function(p)
        return not p:isKongcheng() end), function (p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xingzuo-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.phase == Player.Play then
      local piles = room:askForExchange(player, {room:getNCards(3, "bottom"), player.player_cards[Player.Hand]}, {"Bottom", "$Hand"}, self.name)
      local cards1, cards2 = {}, {}
      for _, id in ipairs(piles[1]) do
        if room:getCardArea(id) == Player.Hand then
          table.insert(cards1, id)
        end
      end
      for _, id in ipairs(piles[2]) do
        if room:getCardArea(id) ~= Player.Hand then
          table.insert(cards2, id)
        end
      end
      local move1 = {
        ids = cards1,
        from = player.id,
        fromArea = Player.Hand,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = -1,
      }
      local move2 = {
        ids = cards2,
        to = player.id,
        toArea = Player.Hand,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      room:moveCards(move1, move2)
    else
      local to = room:getPlayerById(self.cost_data)
      local n = to:getHandcardNum()
      local move1 = {
        ids = to.player_cards[Player.Hand],
        from = to.id,
        fromArea = Player.Hand,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = -1,
      }
      local move2 = {
        ids = room:getNCards(3, "bottom"),
        to = to.id,
        toArea = Player.Hand,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      room:moveCards(move1, move2)
      if n > 3 and not player.dead then
        room:loseHp(player, 1, self.name)
      end
    end
  end,
}
local miaoxian = fk.CreateViewAsSkill{
  name = "miaoxian",
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#miaoxian",
  interaction = function()
    local names = {}
    local blackcards = table.filter(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return false end
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived then
        local to_use = Fk:cloneCard(card.name)
        to_use:addSubcard(blackcards[1])
        if ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, to_use) and not Self:prohibitUse(to_use)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names }
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return nil end
    local blackcards = table.filter(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(blackcards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
}
local miaoxian_trigger = fk.CreateTriggerSkill{
  name = "#miaoxian_trigger",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and table.every(player.player_cards[Player.Hand], function(id)
      return Fk:getCardById(id).color ~= Card.Red end) and data.card.color == Card.Red and
      not (data.card:isVirtual() and #data.card.subcards ~= 1)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, miaoxian.name, self.anim_type)
    player.room:broadcastSkillInvoke(miaoxian.name)
    player:drawCards(1, "miaoxian")
  end,
}
miaoxian:addRelatedSkill(miaoxian_trigger)
ruanyu:addSkill(xingzuo)
ruanyu:addSkill(miaoxian)
Fk:loadTranslationTable{
  ["ruanyu"] = "阮瑀",
  ["xingzuo"] = "兴作",
  [":xingzuo"] = "出牌阶段开始时，你可观看牌堆底的三张牌并用任意张手牌替换其中等量的牌。若如此做，结束阶段，"..
  "你可以令一名有手牌的角色用所有手牌替换牌堆底的三张牌，然后若交换前该角色的手牌数大于3，你失去1点体力。",
  ["miaoxian"] = "妙弦",
  [":miaoxian"] = "每回合限一次，你可以将手牌中的唯一黑色牌当任意一张普通锦囊牌使用；当你使用手牌中的唯一红色牌时，你摸一张牌。",
  ["#xingzuo-invoke"] = "兴作：你可观看牌堆底的三张牌，并用任意张手牌替换其中等量的牌",
  ["#xingzuo-choose"] = "兴作：你可以令一名角色用所有手牌替换牌堆底的三张牌，若交换前其手牌数大于3，你失去1点体力",
  ["#miaoxian_trigger"] = "妙弦",
  ["#miaoxian"] = "妙弦：将手牌中的黑色牌当任意锦囊牌使用",

  ["$xingzuo1"] = "顺人之情，时之势，兴作可成。",
  ["$xingzuo2"] = "兴作从心，相继不绝。",
  ["$miaoxian1"] = "女为悦者容，士为知己死。",
  ["$miaoxian2"] = "与君高歌，请君侧耳。",
  ["~ruanyu"] = "良时忽过，身为土灰。",
}

--唐姬

local liangxing = General(extension, "liangxing", "qun", 4)
local lulve = fk.CreateTriggerSkill{
  name = "lulve",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (p:getHandcardNum() < #player.player_cards[Player.Hand] and not p:isKongcheng()) end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#lulve-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choice = room:askForChoice(to, {"lulve_give", "lulve_slash"}, self.name, "#lulve-choice:"..player.id)
    if choice == "lulve_give" then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(to:getCardIds(Player.Hand))
      room:obtainCard(player.id, dummy, false, fk.ReasonGive)
      player:turnOver()
    else
      to:turnOver()
      room:useVirtualCard("slash", nil, to, player, self.name, true)
    end
  end,
}
local zhuixi = fk.CreateTriggerSkill{
  name = "zhuixi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and data.to and
      ((data.from.faceup and not data.to.faceup) or (not data.from.faceup and data.to.faceup))
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
  ["#lulve-choice"] = "掳掠：选择对 %src 执行的一项",

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
  [":cuirui"] = "限定技，出牌阶段，你可以选择至多X名其他角色（X为你的体力值），你获得这些角色各一张手牌。",
  ["ty__liewei"] = "裂围",
  [":ty__liewei"] = "你的回合内，有角色进入濒死状态时，你可以摸一张牌。",
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
    if player:hasSkill(self.name) and (player.phase == Player.Play or player.phase == Player.Discard) and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
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
      return p.id end), 1, 1, "#zhuihuan-choose", self.name, true, true)
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
  
  ["$youyan1"] = "诱言者，为人所不齿。",
  ["$youyan2"] = "诱言之弊，不可不慎。",
  ["$zhuihuan1"] = "伤人者，追而还之！",
  ["$zhuihuan2"] = "追而还击，皆为因果。",
  ["~ty__yangwan"] = "遇人不淑……",
}

--张虎 冯熙 何晏 糜芳傅士仁2021.9.24
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
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local n = math.min(target.maxHp, 5) - target:getHandcardNum()
    if n > 0 then
      target:drawCards(n, self.name)
    end
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
  [":boyan"] = "出牌阶段限一次，你可以选择一名其他角色，该角色将手牌摸至体力上限（最多摸至5张），其本回合不能使用或打出手牌。",
  ["yusui_discard"] = "令其弃置手牌至与你相同",
  ["yusui_loseHp"] = "令其失去体力值至与你相同",
}

Fk:loadTranslationTable{
  ["heyan"] = "何晏",
  ["yachai"] = "崖柴",
  [":yachai"] = "当你受到伤害后，你可令伤害来源选择一项：1.弃置一半手牌（向上取整）；2.其本回合不能再使用手牌，你摸两张牌；"..
  "3.展示所有手牌，然后交给你一种花色的所有手牌。",
  ["qingtan"] = "清谈",
  [":qingtan"] = "出牌阶段限一次，你可令所有角色同时选择一张手牌并展示。你可以获得其中一种花色的牌，然后展示此花色牌的角色各摸一张牌。弃置其余的牌。",
}

local panshu = General(extension, "ty__panshu", "wu", 3, 3, General.Female)
local zhiren = fk.CreateTriggerSkill{
  name = "zhiren",
  anim_type = "control",
  events = {fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and not data.card:isVirtual() and
      (player.phase ~= Player.NotActive or player:getMark("@@yaner") > 0) then
      if player:getMark("zhiren-turn") == 0 then
        player.room:setPlayerMark(player, "zhiren-turn", 1)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #Fk:translate(data.card.trueName) / 3
    room:askForGuanxing(player, room:getNCards(n), nil, nil, "", false)
    if n > 1 then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Equip] > 0 end), function(p) return p.id end)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiren1-choose", self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "e", self.name)
          room:throwCard({id}, self.name, to, player)
        end
      end
      targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Judge] > 0 end), function(p) return p.id end)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiren2-choose", self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "j", self.name)
          room:throwCard({id}, self.name, to, player)
        end
      end
    end
    if n > 2 then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    end
    if n > 3 then
      player:drawCards(3, self.name)
    end
  end,
}
local yaner = fk.CreateTriggerSkill{
  name = "yaner",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              local to = player.room:getPlayerById(move.from)
              if to:isKongcheng() and to.phase == Player.Play then
                self.cost_data = move.from
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yaner-invoke::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards1 = player:drawCards(2, self.name)
    local cards2 = to:drawCards(2, self.name)
    if Fk:getCardById(cards1[1]).type == Fk:getCardById(cards1[2]).type then
      room:setPlayerMark(player, "@@yaner", 1)
    end
    if to:isWounded() and Fk:getCardById(cards2[1]).type == Fk:getCardById(cards2[2]).type then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yaner") > 0 and data.from == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yaner", 0)
  end,
}
panshu:addSkill(zhiren)
panshu:addSkill(yaner)
Fk:loadTranslationTable{
  ["ty__panshu"] = "潘淑",
  ["zhiren"] = "织纴",
  [":zhiren"] = "你的回合内，当你使用本回合的第一张非转化牌时，若X：不小于1，你观看牌堆顶X张牌并以任意顺序放回牌堆顶或牌堆底；"..
  "不小于2，你可以弃置场上一张装备牌和一张延时锦囊牌；不小于3，你回复1点体力；不小于4，你摸三张牌（X为此牌名称字数）。",
  ["yaner"] = "燕尔",
  [":yaner"] = "每回合限一次，当其他角色于其出牌阶段内失去最后的手牌时，你可以与其各摸两张牌，然后若因此摸到相同类型的两张牌的角色为："..
  "你，〖织纴〗改为回合外也可以发动直到你的下个回合开始；其，其回复1点体力。",
  ["#zhiren1-choose"] = "织纴：你可以弃置场上一张装备牌",
  ["#zhiren2-choose"] = "织纴：你可以弃置场上一张延时锦囊牌",
  ["#yaner-invoke"] = "燕尔：你可以与 %dest 各摸两张牌，若摸到的牌类型形同则获得额外效果",
  ["@@yaner"] = "燕尔",
  
  ["$zhiren1"] = "穿针引线，栩栩如生。",
  ["$zhiren2"] = "纺绩织纴，布帛可成。",
  ["$yaner1"] = "如胶似漆，白首相随。",
  ["$yaner2"] = "新婚燕尔，亲睦和美。",
  ["~ty__panshu"] = "有喜必忧，以为深戒！",
}

local jinghe_skills = {"ol_ex__leiji", "yinbingn", "huoqi", "guizhu", "xianshou", "lundao", "guanyue", "yanzhengn",
"ex__biyue", "ex__tuxi","mingce", "zhiyan"}
Fk:loadTranslationTable{
  ["ty__nanhualaoxian"] = "南华老仙",
  ["gongxiu"] = "共修",
  [":gongxiu"] = "结束阶段，若你本回合发动过〖经合〗，你可以选择一项：1.令所有本回合因〖经合〗获得过技能的角色摸一张牌；"..
  "2.令所有本回合未因〖经合〗获得过技能的其他角色弃置一张手牌。",
  ["jinghe"] = "经合",
  [":jinghe"] = "出牌阶段限一次，你可展示至多四张牌名各不同的手牌，选择等量的角色，从“写满技能的天书”随机展示四个技能，"..
  "这些角色依次选择并获得其中一个，直到你下回合开始。",
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
    if target == player and player:hasSkill(self.name) then
      if event == fk.Damage then
        local room = player.room
        if room.current and room.current.phase == Player.Play and player:getMark("zhukou-turn") == 0 then
          room:addPlayerMark(player, "zhukou-turn", 1)
          if player:getMark("@zhukou-turn") > 0 then
            return true
          end
        end
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
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      if #targets < 2 then return end
      local tos = room:askForChoosePlayers(player, targets, 2, 2, "#zhukou-choose", self.name, true)
      if #tos == 2 then
        self.cost_data = tos
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      player:drawCards(player:getMark("@zhukou-turn"), self.name)
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

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true) and player:getMark("zhukou-turn") == 0 and player.phase < Player.Discard
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
    if table.find(room:getOtherPlayers(player), function(p) return not p:isNude() end) then
      table.insert(choices, "yuyun4")
    end
    if table.find(room:getOtherPlayers(player), function(p) return p:getHandcardNum() < p.maxHp end) then
      table.insert(choices, "yuyun5")
    end
    local n = 1 + player:getLostHp()
    for i = 1, n, 1 do
      if player.dead then return end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "Cancel" then return end
      table.removeOne(choices, choice)
      if choice == "yuyun1" then
        player:drawCards(2, self.name)
      elseif choice == "yuyun2" then
        local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun2-choose", self.name, false)
        if #to > 0 then
          to = to[1]
        else
          to = table.random(targets)
        end
        room:damage{
          from = player,
          to = room:getPlayerById(to),
          damage = 1,
          skillName = self.name,
        }
        room:addPlayerMark(room:getPlayerById(to), "@@yuyun-turn")
        local targetRecorded = type(player:getMark("yuyun2-turn")) == "table" and player:getMark("yuyun2-turn") or {}
        table.insertIfNeed(targetRecorded, to)
        room:setPlayerMark(player, "yuyun2-turn", targetRecorded)
      elseif choice == "yuyun3" then
        room:addPlayerMark(player, "@@yuyun-turn")
        room:addPlayerMark(player, "yuyun3-turn", 1)
      elseif choice == "yuyun4" then
        local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not p:isAllNude() end), function(p) return p.id end)
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun4-choose", self.name, false)
        if #to > 0 then
          to = to[1]
        else
          to = table.random(targets)
        end
        local id = room:askForCardChosen(player, room:getPlayerById(to), "hej", self.name)
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
      elseif choice == "yuyun5" then
        local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return p:getHandcardNum() < math.min(p.maxHp, 5) end), function(p) return p.id end)
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun5-choose", self.name)
        if #to > 0 then
          to = to[1]
        else
          to = table.random(targets)
        end
        local p = room:getPlayerById(to)
        p:drawCards(math.min(p.maxHp, 5) - p:getHandcardNum(), self.name)
      end
    end
  end,
}
local yuyun_targetmod = fk.CreateTargetModSkill{
  name = "#yuyun_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    local targetRecorded = player:getMark("yuyun2-turn")
    return type(targetRecorded) == "table" and to and table.contains(targetRecorded, to.id)
  end,
  bypass_distances =  function(self, player, skill, card, to)
    local targetRecorded = player:getMark("yuyun2-turn")
    return type(targetRecorded) == "table" and to and table.contains(targetRecorded, to.id)
  end,
}
local yuyun_maxcards = fk.CreateMaxCardsSkill{
  name = "#yuyun_maxcards",
  correct_func = function(self, player)
    if player:getMark("yuyun3-turn") > 0 then
      return 999
    end
    return 0
  end,
}
yuyun:addRelatedSkill(yuyun_targetmod)
yuyun:addRelatedSkill(yuyun_maxcards)
zhouyi:addSkill(zhukou)
zhouyi:addSkill(mengqing)
zhouyi:addRelatedSkill(yuyun)
Fk:loadTranslationTable{
  ["zhouyi"] = "周夷",
  ["zhukou"] = "逐寇",
  [":zhukou"] = "当你于每回合的出牌阶段第一次造成伤害后，你可以摸X张牌（X为本回合你已使用的牌数）。结束阶段，若你本回合未造成过伤害，"..
  "你可以对两名其他角色各造成1点伤害。",
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
  ["@@yuyun-turn"] = "玉陨",

  ["$zhukou1"] = "草莽贼寇，不过如此。",
  ["$zhukou2"] = "轻装上阵，利剑出鞘。",
  ["$mengqing1"] = "女之耽兮，不可说也。",
  ["$mengqing2"] = "淇水汤汤，渐车帷裳。",
  ["$yuyun1"] = "春依旧，人消瘦。",
  ["$yuyun2"] = "泪沾青衫，玉殒香消。",
  ["~zhouyi"] = "江水寒，萧瑟起……",
}

local lvlingqi = General(extension, "lvlingqi", "qun", 4, 4, General.Female)
---@param player ServerPlayer @ 执行的玩家
---@param targets ServerPlayer[] @ 可选的目标范围
---@param num integer @ 可选的目标数
---@param can_minus boolean @ 是否可减少
---@param prompt string @ 提示信息
---@param skillName string @ 技能名
---@param data CardUseStruct @ 使用数据
--枚举法为使用牌增减目标（无距离限制）
local function AskForAddTarget(player, targets, num, can_minus, prompt, skillName, data)
  num = num or 1
  can_minus = can_minus or false
  prompt = prompt or ""
  skillName = skillName or ""
  local room = player.room
  local tos = {}
  if can_minus and #AimGroup:getAllTargets(data.tos) > 1 then  --默认不允许减目标至0
    tos = table.map(table.filter(targets, function(p)
      return table.contains(AimGroup:getAllTargets(data.tos), p.id) end), function(p) return p.id end)
  end
  for _, p in ipairs(targets) do
    if not table.contains(AimGroup:getAllTargets(data.tos), p.id) and not room:getPlayerById(data.from):isProhibited(p, data.card) then
      if data.card.name == "jink" or data.card.trueName == "nullification" or data.card.name == "adaptation" or
        (data.card.name == "peach" and not p:isWounded()) then
        --continue
      else
        if data.from ~= p.id then
          if (data.card.trueName == "slash") or
            ((table.contains({"dismantlement", "snatch", "chasing_near"}, data.card.name)) and not p:isAllNude()) or
            (table.contains({"fire_attack", "unexpectation"}, data.card.name) and not p:isKongcheng()) or
            (table.contains({"peach", "analeptic", "ex_nihilo", "duel", "savage_assault", "archery_attack", "amazing_grace", "god_salvation", 
              "iron_chain", "foresight", "redistribute", "enemy_at_the_gates", "raid_and_frontal_attack"}, data.card.name)) or
            (data.card.name == "collateral" and p:getEquipment(Card.SubtypeWeapon) and
              #table.filter(room:getOtherPlayers(p), function(v) return p:inMyAttackRange(v) end) > 0) then
            table.insertIfNeed(tos, p.id)
          end
        else
          if (data.card.name == "analeptic") or
            (table.contains({"ex_nihilo", "foresight", "iron_chain", "amazing_grace", "god_salvation", "redistribute"}, data.card.name)) or
            (data.card.name == "fire_attack" and not p:isKongcheng()) then
            table.insertIfNeed(tos, p.id)
          end
        end
      end
    end
  end
  if #tos > 0 then
    tos = room:askForChoosePlayers(player, tos, 1, num, prompt, skillName, true)
    if data.card.name ~= "collateral" then
      return tos
    else
      local result = {}
      for _, id in ipairs(tos) do
        local to = room:getPlayerById(id)
        local target = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(v)
          return to:inMyAttackRange(v) end), function(p) return p.id end), 1, 1,
          "#collateral-choose::"..to.id..":"..data.card:toLogString(), "collateral_skill", true)
        if #target > 0 then
          table.insert(result, {id, target[1]})
        end
      end
      if #result > 0 then
        return result
      else
        return {}
      end
    end
  end
  return {}
end
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
    local card = room:getCardsFromPileByRule("slash", 1, "discardPile")
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
    return target == player and player:getMark("guowu3-phase") > 0 and data.firstTarget and data.card:isCommonTrick()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = AskForAddTarget(player, room:getAlivePlayers(), 2, false, "#guowu-choose:::"..data.card:toLogString(), self.name, data)
    if #targets > 0 then
      for _, id in ipairs(targets) do
        TargetGroup:pushTargets(data.targetGroup, id)
      end
    end
  end,
}
local guowu_targetmod = fk.CreateTargetModSkill{
  name = "#guowu_targetmod",
  bypass_distances =  function(self, player)
    return player:getMark("guowu2-phase") > 0
  end,
  extra_target_func = function(self, player, skill)
    if player:getMark("guowu3-phase") > 0 and skill.trueName == "slash_skill" then
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
    room:handleAddLoseSkills(player, "shenwei|wushuang", nil, true, false)
  end,
}
guowu:addRelatedSkill(guowu_targetmod)
lvlingqi:addSkill(guowu)
lvlingqi:addSkill(zhuangrong)
lvlingqi:addRelatedSkill("shenwei")
lvlingqi:addRelatedSkill("wushuang")
Fk:loadTranslationTable{
  ["lvlingqi"] = "吕玲绮",
  ["guowu"] = "帼武",
  [":guowu"] = "出牌阶段开始时，你可以展示所有手牌，若包含的类别数：不小于1，你从弃牌堆中获得一张【杀】；不小于2，你本阶段使用牌无距离限制；"..
  "不小于3，你本阶段使用【杀】或普通锦囊牌可以多指定两个目标。",
  ["zhuangrong"] = "妆戎",
  [":zhuangrong"] = "觉醒技，一名角色的回合结束时，若你的手牌数或体力值为1，你减1点体力上限并将体力值回复至体力上限，然后将手牌摸至体力上限。"..
  "若如此做，你获得技能〖神威〗和〖无双〗。",
  ["#guowu-choose"] = "帼武：你可以为%arg增加至多两个目标",

  ["$guowu1"] = "方天映黛眉，赤兔牵红妆。",
  ["$guowu2"] = "武姬青丝利，巾帼女儿红。",
  ["$zhuangrong1"] = "锋镝鸣手中，锐戟映秋霜。",
  ["$zhuangrong2"] = "红妆非我愿，学武觅封侯。",
  ["$shenwei1"] = "继父神威，无坚不摧！",
  ["$shenwei2"] = "我乃温侯吕奉先之女！",
  ["~lvlingqi"] = "父亲，女儿好累。",
}

return extension
