local extension = Package("tenyear_liezhuan")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_liezhuan"] = "十周年-武将列传",
}

local hansui = General(extension, "ty__hansui", "qun", 4)
local ty__niluan = fk.CreateViewAsSkill{
  name = "ty__niluan",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response and player.phase == Player.Play
  end,
}
local ty__niluan_record = fk.CreateTriggerSkill{
  name = "#ty__niluan_record",

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "ty__niluan") and not data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    player:addCardUseHistory(data.card.trueName, -1)
  end,
}
local weiwu = fk.CreateViewAsSkill{
  name = "weiwu",
  anim_type = "control",
  pattern = "snatch",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("snatch")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
}
local weiwu_prohibit = fk.CreateProhibitSkill{
  name = "#weiwu_prohibit",
  is_prohibited = function(self, from, to, card)
    return table.contains(card.skillNames, "weiwu") and to:getHandcardNum() < from:getHandcardNum()
  end,
}
ty__niluan:addRelatedSkill(ty__niluan_record)
weiwu:addRelatedSkill(weiwu_prohibit)
hansui:addSkill(ty__niluan)
hansui:addSkill(weiwu)
Fk:loadTranslationTable{
  ["ty__hansui"] = "韩遂",
  ["ty__niluan"] = "逆乱",
  [":ty__niluan"] = "出牌阶段，你可以将一张黑色牌当【杀】使用；你以此法使用的【杀】结算后，若此【杀】未造成伤害，其不计入使用次数限制。",
  ["weiwu"] = "违忤",
  [":weiwu"] = "出牌阶段限一次，你可以将一张红色牌当【顺手牵羊】对手牌数大于等于你的角色使用。",
}

--刘宏

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
  [":gongjian"] = "每回合限一次，当一名角色使用【杀】指定目标后，若此【杀】与上一张【杀】有相同的目标，则你可以弃置其中相同目标角色各至多两张牌，"..
  "你获得其中的【杀】。",
  ["kuimang"] = "溃蟒",
  [":kuimang"] = "锁定技，当一名角色死亡时，若你对其造成过伤害，你摸两张牌。",
  ["#gongjian-choose"] = "攻坚：你可以选择其中相同的目标角色，弃置每名角色各至多两张牌，你获得其中的【杀】",
}

--许劭 丁原

Fk:loadTranslationTable{
  ["ty__wangrongh"] = "王荣",
  ["minsi"] = "敏思",
  [":minsi"] = "出牌阶段限一次，你可以弃置任意张点数之和为13的牌，并摸两倍的牌。本回合以此法获得的牌中，黑色牌无距离限制，红色牌不计入手牌上限。",
  ["jijing"] = "吉境",
  [":jijing"] = "当你受到伤害后，你可以判定，然后你可以弃置任意张点数之和等于判定结果的牌，若如此做，你回复1点体力",
  ["zhuide"] = "追德",
  [":zhuide"] = "当你死亡时，你可以令一名其他角色摸四张不同牌名的基本牌。",
}

--韩馥

local caosong = General(extension, "ty__caosong", "wei", 4)
local lilu = fk.CreateTriggerSkill{
  name = "lilu",
  anim_type = "support",
  events ={fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#lilu-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local n = math.min(player.maxHp - player:getHandcardNum(), 5)
    if n > 0 then
      player:drawCards(n, self.name)
    end
    player.room:askForUseActiveSkill(player, "lilu_active", "#lilu-card:::"..player:getMark(self.name), false)
    return true
  end,
}
local lilu_active = fk.CreateActiveSkill{
  name = "lilu_active",
  mute = true,
  max_card_num = function ()
    return #Self.player_cards[Player.Hand]
  end,
  min_card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target, dummy, false, fk.ReasonGive)
    if #effect.cards > player:getMark("lilu") then
      room:changeMaxHp(player, 1)
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
    room:setPlayerMark(player, "lilu", #effect.cards)
  end,
}
local yizhengc = fk.CreateTriggerSkill{
  name = "yizhengc",
  mute = true,
  events = {fk.EventPhaseStart, fk.DamageCaused, fk.PreHpRecover},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
      else
        if player:getMark("@@yizhengc") ~= 0 then
          for _, id in ipairs(player:getMark("@@yizhengc")) do
            local p = player.room:getPlayerById(id)
            if not p.dead and p.maxHp > player.maxHp then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
        return p.id end), 1, 1, "#yizhengc-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "support")
      local to = room:getPlayerById(self.cost_data)
      local mark = to:getMark("@@yizhengc")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, player.id)
      room:setPlayerMark(to, "@@yizhengc", mark)
      room:setPlayerMark(player, self.name, to.id)
    else
      for _, id in ipairs(player:getMark("@@yizhengc")) do
        local p = player.room:getPlayerById(id)
        room:broadcastSkillInvoke(self.name)
        room:notifySkillInvoked(p, self.name, "support")
        room:changeMaxHp(p, -1)
        if event == fk.DamageCaused then
          data.damage = data.damage + 1
        else
          data.num = data.num + 1
        end
      end
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) ~= 0 and data.from == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark(self.name))
    room:setPlayerMark(player, self.name, 0)
    if not to.dead then
      local mark = to:getMark("@@yizhengc")
      table.removeOne(mark, player.id)
      if #mark == 0 then mark = 0 end
      room:setPlayerMark(to, "@@yizhengc", mark)
    end
  end,
}
Fk:addSkill(lilu_active)
caosong:addSkill(lilu)
caosong:addSkill(yizhengc)
Fk:loadTranslationTable{
  ["ty__caosong"] = "曹嵩",
  ["lilu"] = "礼赂",
  [":lilu"] = "摸牌阶段，你可以放弃摸牌，改为将手牌摸至体力上限（最多摸至5张），并将至少一张手牌交给一名其他角色；"..
  "若你交出的牌数大于上次以此法交出的牌数，你增加1点体力上限并回复1点体力。",
  ["yizhengc"] = "翊正",
  [":yizhengc"] = "结束阶段，你可以选择一名其他角色。直到你的下回合开始，当该角色造成伤害或回复体力时，若其体力上限小于你，"..
  "你减1点体力上限，然后此伤害或回复值+1。",
  ["#lilu-invoke"] = "礼赂：你可以放弃摸牌，改为将手牌摸至体力上限，然后将至少一张手牌交给一名其他角色",
  ["#lilu-card"] = "礼赂：将至少一张手牌交给一名其他角色，若大于%arg，你加1点体力上限并回复1点体力",
  ["lilu_active"] = "礼赂",
  ["#yizhengc-choose"] = "翊正：你可以指定一名角色，直到你下回合开始，其造成伤害/回复体力时数值+1，你减1点体力上限",
  ["@@yizhengc"] = "翊正",

  ["$lilu1"] = "乱狱滋丰，以礼赂之。",
  ["$lilu2"] = "微薄之礼，聊表敬意！",
  ["$yizhengc1"] = "玉树盈阶，望子成龙！",
  ["$yizhengc2"] = "择善者，翊赞季兴。",
  ["~ty__caosong"] = "孟德，勿忘汝父之仇！",
}

--张邈

Fk:loadTranslationTable{
  ["qiuliju"] = "丘力居",
  ["koulve"] = "寇略",
  [":koulve"] = "出牌阶段，当你对其他角色造成伤害后，你可以展示其X张手牌（X为其已损失体力值），你获得其中的伤害牌。若展示牌中有红色牌，"..
  "若你已受伤，你减1点体力上限；若你未受伤，则失去1点体力；然后你摸两张牌。",
  ["suirenq"] = "随认",
  [":suirenq"] = "你死亡时，可以将手牌中伤害牌交给一名其他角色。",
}

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
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
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

--胡车儿

local zoushi = General(extension, "ty__zoushi", "qun", 3, 3, General.Female)
local ty__huoshui_active = fk.CreateActiveSkill{
  name = "ty__huoshui_active",
  mute = true,
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    local n = math.max(Self:getLostHp(), 1)
    return math.min(n, 3)
  end,
  card_filter = function(self, to_select, selected, targets)
    return false
  end,
  target_filter = function(self, to_select, selected, cards)
    if to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return not target:isKongcheng()
      elseif #selected == 2 then
        return #target.player_cards[Player.Equip] > 0
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for i = 1, #effect.tos, 1 do
      local target = room:getPlayerById(effect.tos[i])
      if i == 1 then
        room:setPlayerMark(target, MarkEnum.UncompulsoryInvalidity.."-turn", 1)
      elseif i == 2 then
        local card = room:askForCard(target, 1, 1, false, "ty__huoshui", false, ".", "#ty__huoshui-give:"..player.id)
        room:obtainCard(player.id, card[1], false, fk.ReasonGive)
      elseif i == 3 then
        target:throwAllCards("e")
      end
    end
  end,
}
local ty__huoshui = fk.CreateTriggerSkill{
  name = "ty__huoshui",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local n = math.max(player:getLostHp(), 1)
    n = math.min(n, 3)
    return player.room:askForUseActiveSkill(player, "ty__huoshui_active", "#ty__huoshui-choose:::"..tostring(n), true, {}, false)
  end,
}
local ty__qingcheng = fk.CreateActiveSkill{
  name = "ty__qingcheng",
  anim_type = "control",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= Self.id and target.gender == General.Male and Self:getHandcardNum() >= target:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local cards1 = table.clone(room:getPlayerById(effect.from).player_cards[Player.Hand])
    local cards2 = table.clone(room:getPlayerById(effect.tos[1]).player_cards[Player.Hand])
    local move1 = {
      from = effect.from,
      ids = cards1,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = self.name,
    }
    local move2 = {
      from = effect.tos[1],
      ids = cards2,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = self.name,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = table.filter(cards1, function(id) return room:getCardArea(id) == Card.Processing end),
      fromArea = Card.Processing,
      to = effect.tos[1],
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = self.name,
    }
    local move4 = {
      ids = table.filter(cards2, function(id) return room:getCardArea(id) == Card.Processing end),
      fromArea = Card.Processing,
      to = effect.from,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = self.name,
    }
    room:moveCards(move3, move4)
  end,
}
Fk:addSkill(ty__huoshui_active)
zoushi:addSkill(ty__huoshui)
zoushi:addSkill(ty__qingcheng)
Fk:loadTranslationTable{
  ["ty__zoushi"] = "邹氏",
  ["ty__huoshui"] = "祸水",
  [":ty__huoshui"] = "准备阶段，你可以令至多X名其他角色（X为你已损失体力值，至少为1，至多为3）按你选择的顺序依次执行一项：1.本回合所有非锁定技失效；"..
  "2.交给你一张手牌；3.弃置装备区里的所有牌。",
  ["ty__qingcheng"] = "倾城",
  [":ty__qingcheng"] = "出牌阶段限一次，你可以与一名手牌数不大于你的男性角色交换手牌。",
  ["#ty__huoshui-choose"] = "祸水：选择至多%arg名角色，按照选择的顺序：<br>1.本回合非锁定技失效，2.交给你一张手牌，3.弃置装备区里的所有牌",
  ["ty__huoshui_active"] = "祸水",
  ["#ty__huoshui-give"] = "祸水：你须交给%src一张手牌",
}

--曹安民 郝萌

local yanfuren = General(extension, "yanfuren", "qun", 3, 3, General.Female)
local channi_viewas = fk.CreateViewAsSkill{
  name = "channi_viewas",
  anim_type = "offensive",
  pattern = "duel",
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and #selected < Self:getMark("channi")
  end,
  view_as = function(self, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcards(cards)
    card.skillName = "channi"
    return card
  end,
}
local channi = fk.CreateActiveSkill{
  name = "channi",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #effect.cards
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target.id, dummy, false, fk.ReasonGive)
    room:setPlayerMark(target, self.name, n)
    local success, data = room:askForUseActiveSkill(target, "channi_viewas", "#channi-invoke:"..player.id.."::"..n, true, {}, false)
    room:setPlayerMark(target, self.name, 0)
    if success then
      local card = Fk:cloneCard("duel")
      card.skillName = self.name
      card:addSubcards(data.cards)
      local use = {
        from = target.id,
        tos = table.map(data.targets, function(id) return {id} end),
        card = card,
      }
      room:useCard(use)
      if use.damageDealt then
        if not use.damageDealt[target.id] and not target.dead then
          target:drawCards(#card.subcards, self.name)
        elseif use.damageDealt[target.id] and not player.dead and not player:isKongcheng() then
          player:throwAllCards("h")
        end
      end
    end
  end,
}
local nifu = fk.CreateTriggerSkill{
  name = "nifu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.phase == Player.Finish and player:getHandcardNum() ~= 3
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getHandcardNum() - 3
    if n < 0 then
      player:drawCards(-n, self.name)
    else
      player.room:askForDiscard(player, n, n, false, self.name, false)
    end
  end,
}
Fk:addSkill(channi_viewas)
yanfuren:addSkill(channi)
yanfuren:addSkill(nifu)
Fk:loadTranslationTable{
  ["yanfuren"] = "严夫人",
  ["channi"] = "谗逆",
  [":channi"] = "出牌阶段限一次，你可以交给一名其他角色任意张手牌，然后该角色可以将X张手牌当一张【决斗】使用（X至多为你以此法交给其的牌数）。"..
  "其因此使用【决斗】造成伤害后，其摸X张牌；其因此使用【决斗】受到伤害后，你弃置所有手牌。",
  ["nifu"] = "匿伏",
  [":nifu"] = "锁定技，一名角色的结束阶段，你将手牌摸至或弃置至三张。",
  ["channi_viewas"] = "谗逆",
  ["#channi-invoke"] = "谗逆：你可以将至多%arg张手牌当一张【决斗】使用<br>若对目标造成伤害你摸等量牌，若你受到伤害则 %src 弃置所有手牌",

  ["$channi1"] = "此人心怀叵测，将军当拔剑诛之！",
  ["$channi2"] = "请夫君听妾身之言，勿为小人所误！",
  ["$nifu1"] = "当为贤妻宜室，莫做妒妇祸家。",
  ["$nifu2"] = "将军且往沙场驰骋，妾身自有苟全之法。",
  ["~yanfuren"] = "妾身绝不会害将军呀！",
}

Fk:loadTranslationTable{
  ["ty__zhuling"] = "朱灵",
  ["ty__zhanyi"] = "战意",
  [":ty__zhanyi"] = "出牌阶段开始时，你可以弃置一种类别的所有牌，另外两种类别的牌本回合获得以下效果：<br>"..
  "基本牌：你使用基本牌无距离限制且造成的伤害和回复值+1；<br>"..
  "锦囊牌：你使用锦囊牌时摸一张牌且锦囊牌不计入手牌上限；<br>"..
  "装备牌：你使用装备牌时可以弃置一名其他角色的一张牌。",
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

return extension
