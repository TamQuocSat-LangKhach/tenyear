local extension = Package("tenyear_sp3")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_sp3"] = "十周年-限定专属3",
  ["wm"] = "武",
}

--锦瑟良缘：曹金玉 孙翊 冯妤 来莺儿 曹华 张奋 诸葛若雪
local caojinyu = General(extension, "caojinyu", "wei", 3, 3, General.Female)
local yuqi = fk.CreateTriggerSkill{
  name = "yuqi",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and player:usedSkillTimes(self.name) < 2 and
    (target == player or player:distanceTo(target) <= player:getMark("yuqi1"))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n1, n2, n3 = player:getMark("yuqi2") + 3, player:getMark("yuqi3") + 1, player:getMark("yuqi4") + 1
    if n1 < 2 and n2 < 1 and n3 < 1 then
      return false
    end
    local cards = room:getNCards(n1)
    local result = room:askForCustomDialog(player, self.name,
    "packages/tenyear/qml/YuqiBox.qml", {
      cards,
      target.general, n2,
      player.general, n3,
    })
    local top, bottom
    if result ~= "" then
      local d = json.decode(result)
      top = d[2]
      bottom = d[3]
    else
      top = {cards[1]}
      bottom = {cards[2]}
    end
    local moveInfos = {}
    if #top > 0 then
      table.insert(moveInfos, {
        ids = top,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = self.name,
      })
      for _, id in ipairs(top) do
        table.removeOne(cards, id)
      end
    end
    if #bottom > 0 then
      table.insert(moveInfos, {
        ids = bottom,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
      for _, id in ipairs(bottom) do
        table.removeOne(cards, id)
      end
    end
    if #cards > 0 then
      for i = #cards, 1, -1 do
        table.insert(room.draw_pile, 1, cards[i])
      end
    end
    room:moveCards(table.unpack(moveInfos))
  end,

  refresh_events = {fk.EventLoseSkill, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "yuqi1", 0)
    room:setPlayerMark(player, "yuqi2", 0)
    room:setPlayerMark(player, "yuqi3", 0)
    room:setPlayerMark(player, "yuqi4", 0)
    if event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "@" .. self.name, string.format("%d-%d-%d-%d", 0, 3, 1, 1))
    else
      room:setPlayerMark(player, "yuqi1", 0)
      room:setPlayerMark(player, "yuqi2", 0)
      room:setPlayerMark(player, "yuqi3", 0)
      room:setPlayerMark(player, "yuqi4", 0)
      room:setPlayerMark(player, "@" .. self.name, 0)
    end
  end,
}
local function AddYuqi(player, skillName, num)
  local room = player.room
  local choices = {}
  local all_choices = {}
  local yuqi_initial = {0, 3, 1, 1}
  for i = 1, 4, 1 do
    table.insert(all_choices, "yuqi" .. tostring(i))
    if player:getMark("yuqi" .. tostring(i)) + yuqi_initial[i] < 5 then
      table.insert(choices, "yuqi" .. tostring(i))
    end
  end
  if #choices > 0 then
    local choice = room:askForChoice(player, choices, skillName, "#yuqi-upgrade:::" .. tostring(num), false, all_choices)
    room:setPlayerMark(player, choice, math.min(5-yuqi_initial[table.indexOf(all_choices, choice)], player:getMark(choice)+num))
    room:setPlayerMark(player, "@yuqi", string.format("%d-%d-%d-%d",
    player:getMark("yuqi1"),
    player:getMark("yuqi2")+3,
    player:getMark("yuqi3")+1,
    player:getMark("yuqi4")+1))
  end
end
local shanshen = fk.CreateTriggerSkill{
  name = "shanshen",
  anim_type = "control",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and not player.dead
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
    return target == player and target:hasSkill(self) and data.to:getMark(self.name) == 0
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
    if target == player and player:hasSkill(self) and player.phase == Player.Start then
      local yuqi_initial = {0, 3, 1, 1}
      for i = 1, 4, 1 do
        if player:getMark("yuqi" .. tostring(i)) + yuqi_initial[i] < 5 then
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
  [":yuqi"] = "每回合限两次，当一名角色受到伤害后，若你与其距离0或者更少，你可以观看牌堆顶的3张牌，将其中至多1张交给受伤角色，"..
  "至多1张自己获得，剩余的牌放回牌堆顶。",
  ["shanshen"] = "善身",
  [":shanshen"] = "当有角色死亡时，你可令〖隅泣〗中的一个数字+2（单项不能超过5）。然后若你没有对死亡角色造成过伤害，你回复1点体力。",
  ["xianjing"] = "娴静",
  [":xianjing"] = "准备阶段，你可令〖隅泣〗中的一个数字+1（单项不能超过5）。若你满体力值，则再令〖隅泣〗中的一个数字+1。",
  ["@yuqi"] = "隅泣",
  ["#yuqi-upgrade"] = "选择令〖隅泣〗中的一个数字+%arg",
  ["yuqi1"] = "距离",
  ["yuqi2"] = "观看牌数",
  ["yuqi3"] = "交给受伤角色牌数",
  ["yuqi4"] = "自己获得牌数",
  ["#yuqi"] = "隅泣：请分配卡牌，余下的牌以原顺序置于牌堆顶",

  ["$yuqi1"] = "孤影独泣，困于隅角。",
  ["$yuqi2"] = "向隅而泣，黯然伤感。",
  ["$shanshen1"] = "好善为德，坚守本心。",
  ["$shanshen2"] = "洁身自爱，独善其身。",
  ["$xianjing1"] = "文静娴丽，举止柔美。",
  ["$xianjing2"] = "娴静淡雅，温婉穆穆。",
  ["~caojinyu"] = "平叔之情，吾岂不明。",
}

local sunyi = General(extension, "ty__sunyi", "wu", 5)
local jiqiaos = fk.CreateTriggerSkill{
  name = "jiqiaos",
  anim_type = "drawcard",
  expand_pile = "jiqiaos",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(self.name, player.room:getNCards(player.maxHp), true, self.name)
  end,
}
local jiqiaos_trigger = fk.CreateTriggerSkill{
  name = "#jiqiaos_trigger",
  anim_type = "drawcard",
  expand_pile = "jiqiaos",
  events = {fk.EventPhaseEnd, fk.CardUseFinished, fk.EventLoseSkill},
  can_trigger = function(self, event, target, player, data)
    if target == player and #player:getPile("jiqiaos") > 0 then
      if event == fk.EventPhaseEnd then
        return player.phase == Player.Play
      elseif event == fk.CardUseFinished then
        return true
      elseif event == fk.EventLoseSkill then
        return data.name == "jiqiaos"
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd or event == fk.EventLoseSkill then
      room:moveCards({
        from = player.id,
        ids = player:getPile("jiqiaos"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = "jiqiaos",
        specialName = "jiqiaos",
      })
    else
      local cards = player:getPile("jiqiaos")
      if #cards == 0 then return false end
      local id = room:askForCardChosen(player, player, {
        card_data = {
          { "jiqiaos", cards }
        }
      }, "jiqiaos")
      room:obtainCard(player, id, true, fk.ReasonJustMove)
      local red = #table.filter(player:getPile("jiqiaos"), function (id) return Fk:getCardById(id, true).color == Card.Red end)
      local black = #player:getPile("jiqiaos") - red  --除了不该出现的衍生牌，都有颜色
      if red == black then
        if player:isWounded() then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = "jiqiaos",
          }
        end
      else
        room:loseHp(player, 1, "jiqiaos")
      end
    end
  end,
}
local xiongyis = fk.CreateTriggerSkill{
  name = "xiongyis",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#xiongyis1-invoke:::"..tostring(math.min(3, player.maxHp))
    if table.find(player.room.alive_players, function(p) return string.find(p.general, "xushi") end) then
      prompt = "#xiongyis2-invoke"
    end
    if player.room:askForSkillInvoke(player, self.name, nil, prompt) then
      self.cost_data = prompt
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = tonumber(string.sub(self.cost_data, 10, 10))
    if n == 1 then
      local maxHp = player.maxHp
      room:recover({
        who = player,
        num = math.min(3, maxHp) - player.hp,
        recoverBy = player,
        skillName = self.name
      })
      room:changeHero(player, "xushi", false, false, true, false)
    else
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name
      })
      room:handleAddLoseSkills(player, "hunzi", nil, true, false)
    end
  end,
}
jiqiaos:addRelatedSkill(jiqiaos_trigger)
sunyi:addSkill(jiqiaos)
sunyi:addSkill(xiongyis)
sunyi:addRelatedSkill("hunzi")
sunyi:addRelatedSkill("ex__yingzi")
sunyi:addRelatedSkill("yinghun")
Fk:loadTranslationTable{
  ["ty__sunyi"] = "孙翊",
  ["jiqiaos"] = "激峭",
  [":jiqiaos"] = "出牌阶段开始时，你可以将牌堆顶的X张牌至于武将牌上（X为你的体力上限）；当你使用一张牌结算结束后，若你的武将牌上有“激峭”牌，"..
  "你获得其中一张，然后若剩余其中两种颜色牌的数量相等，你回复1点体力，否则你失去1点体力；出牌阶段结束时，移去所有“激峭”牌。",
  ["xiongyis"] = "凶疑",
  [":xiongyis"] = "限定技，当你处于濒死状态时，若徐氏：不在场，你可以将体力值回复至3点并将武将牌替换为徐氏；"..
  "在场，你可以将体力值回复至1点并获得技能〖魂姿〗。",
  ["#jiqiaos_trigger"] = "激峭",
  ["#jiqiaos-card"] = "激峭：获得一张“激峭”牌",
  ["#xiongyis1-invoke"] = "凶疑：你可以将回复体力至%arg点并变身为徐氏！",
  ["#xiongyis2-invoke"] = "凶疑：你可以将回复体力至1点并获得〖魂姿〗！",

  ["$jiqiaos1"] = "为将者，当躬冒矢石！",
  ["$jiqiaos2"] = "吾承父兄之志，危又何惧？",
  ["$xiongyis1"] = "此仇不报，吾恨难消！",
  ["$xiongyis2"] = "功业未立，汝可继之！",
  ["$hunzi_ty__sunyi1"] = "身临绝境，亦当心怀壮志！",
  ["$hunzi_ty__sunyi2"] = "危难之时，自当振奋以对！",
  ["$ex__yingzi_ty__sunyi"] = "骁悍果烈，威震江东！",
  ["$yinghun_ty__sunyi"] = "兄弟齐心，以保父兄基业！",
  ["~ty__sunyi"] = "功业未成而身先死，惜哉，惜哉！",
}

local fengyu = General(extension, "ty__fengfangnv", "qun", 3, 3, General.Female)
local tiqi = fk.CreateTriggerSkill{
  name = "tiqi",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player ~= target and target and not target.dead and target:getMark("tiqi-turn") ~= 2 and
        player:usedSkillTimes(self.name) < 1 then
      return data.to == Player.Play or data.to == Player.Discard or data.to == Player.Finish
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.abs(target:getMark("tiqi-turn") - 2)
    player:drawCards(n, self.name)
    local choice = room:askForChoice(player, {"tiqi_add", "tiqi_minus", "Cancel"}, self.name,
      "#tiqi-choice::" .. target.id .. ":" .. tostring(n))
    if choice == "tiqi_add" then
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, n)
    elseif choice == "tiqi_minus" then
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, n)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase == Player.Draw
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to == player.id and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        player.room:addPlayerMark(player, "tiqi-turn", #move.moveInfo)
      end
    end
  end,
}
local baoshu = fk.CreateTriggerSkill{
  name = "baoshu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), Util.IdMapper), 1, player.maxHp, "#baoshu-choose", self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player.maxHp - #self.cost_data + 1
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:addPlayerMark(p, "@fengyu_shu", x)
        if p.chained then
          p:setChainState(false)
        end
      end
    end
  end,
}
local baoshu_delay = fk.CreateTriggerSkill{
  name = "#baoshu_delay",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@fengyu_shu") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@fengyu_shu")
    player.room:setPlayerMark(player, "@fengyu_shu", 0)
  end,
}
baoshu:addRelatedSkill(baoshu_delay)
fengyu:addSkill(tiqi)
fengyu:addSkill(baoshu)
Fk:loadTranslationTable{
  ["ty__fengfangnv"] = "冯妤",
  ["tiqi"] = "涕泣",
  [":tiqi"] = "其他角色出牌阶段、弃牌阶段、结束开始前，若其于此回合的摸牌阶段内因摸牌而得到的牌数之和不等于2且你于此回合内未发动过此技能，"..
  "则你摸超出或少于2的牌，然后可以令该角色本回合手牌上限增加或减少同样的数值。",
  ["baoshu"] = "宝梳",
  ["#baoshu_delay"] = "宝梳",
  [":baoshu"] = "准备阶段，你可以选择至多X名角色（X为你的体力上限），这些角色各获得一个“梳”标记并重置武将牌，"..
  "你每少选一名角色，每名目标角色便多获得一个“梳”。有“梳”标记的角色摸牌阶段多摸其“梳”数量的牌，然后移去其所有“梳”。",
  ["#tiqi-choice"] = "涕泣：你可以令%dest本回合的手牌上限增加或减少 %arg",
  ["tiqi_add"] = "增加手牌上限",
  ["tiqi_minus"] = "减少手牌上限",
  ["#baoshu-choose"] = "宝梳：你可以令若干名角色获得“梳”标记，重置其武将牌且其摸牌阶段多摸牌",
  ["@fengyu_shu"] = "梳",

  ["$tiqi1"] = "远望中原，涕泪交流。",
  ["$tiqi2"] = "瞻望家乡，泣涕如雨。",
  ["$baoshu1"] = "明镜映梳台，黛眉衬粉面。",
  ["$baoshu2"] = "头作扶摇髻，首枕千金梳。",
  ["~ty__fengfangnv"] = "诸位，为何如此对我？",
}

local laiyinger = General(extension, "laiyinger", "qun", 3, 3, General.Female)
local xiaowu = fk.CreateActiveSkill{
  name = "xiaowu",
  anim_type = "offensive",
  prompt = "#xiaowu",
  max_card_num = 0,
  target_num = 1,
  interaction = function(self)
    return UI.ComboBox { choices = {"xiaowu_clockwise", "xiaowu_anticlockwise"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local players = room:getOtherPlayers(player)
    local targets = {}
    local choice = self.interaction.data
    for i = 1, #players, 1 do
      local real_i = i
      if choice == "xiaowu_anticlockwise" then
        real_i = #players + 1 - real_i
      end
      local temp = players[real_i]
      table.insert(targets, temp)
      if temp == target then break end
    end
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local x = 0
    local to_damage = {}
    for _, p in ipairs(targets) do
      if not p.dead and not player.dead then
        choice = room:askForChoice(p, {"xiaowu_draw1", "draw1"}, self.name, "#xiawu_draw:" .. player.id)
        if choice == "xiaowu_draw1" then
          player:drawCards(1, self.name)
          x = x+1
        elseif choice == "draw1" then
          p:drawCards(1, self.name)
          table.insert(to_damage, p.id)
        end
      end
    end
    if not player.dead then
      if x > #to_damage then
        room:addPlayerMark(player, "@xiaowu_sand")
      elseif x < #to_damage then
        room:sortPlayersByAction(to_damage)
        for _, pid in ipairs(to_damage) do
          local p = room:getPlayerById(pid)
          if not p.dead then
            room:damage{ from = player, to = p, damage = 1, skillName = self.name }
          end
        end
      end
    end
  end,
}
local huaping = fk.CreateTriggerSkill{
  name = "huaping",
  events = {fk.Death},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name, false, player == target) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player == target then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#huaping-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#huaping-invoke::"..target.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player == target then
      local to = room:getPlayerById(self.cost_data)
      room:handleAddLoseSkills(to, "shawu", nil, true, false)
      room:setPlayerMark(to, "@xiaowu_sand", player:getMark("@xiaowu_sand"))
    else
      local skills = {}
      for _, s in ipairs(target.player_skills) do
        if not (s.attached_equip or s.name[#s.name] == "&") then
          table.insertIfNeed(skills, s.name)
        end
      end
      if #skills > 0 then
        room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
      end
      local x = player:getMark("@xiaowu_sand")
      room:handleAddLoseSkills(player, "-xiaowu", nil, true, false)
      room:setPlayerMark(player, "@xiaowu_sand", 0)
      if x > 0 then
        player:drawCards(x, self.name)
      end
    end
  end,
}
local shawu_select = fk.CreateActiveSkill{
  name = "shawu_select",
  can_use = Util.FalseFunc,
  target_num = 0,
  max_card_num = 2,
  min_card_num = function ()
    if Self:getMark("@xiaowu_sand") > 0 then
      return 0
    end
    return 2
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and not Self:prohibitDiscard(Fk:getCardById(to_select)) and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
}
local shawu = fk.CreateTriggerSkill{
  name = "shawu",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      (player:getMark("@xiaowu_sand") > 0 or player:getHandcardNum() > 1) and not player.room:getPlayerById(data.to).dead
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askForUseActiveSkill(player, "shawu_select", "#shawu-invoke::" .. data.to, true)
    if ret then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:getPlayerById(data.to)
    local draw2 = false
    if #self.cost_data > 1 then
      room:throwCard(self.cost_data, self.name, player, player)
    else
      room:removePlayerMark(player, "@xiaowu_sand")
      draw2 = true
    end
    if not to.dead then
      room:damage{ from = player, to = to, damage = 1, skillName = self.name }
    end
    if draw2 and not player.dead then
      player:drawCards(2, self.name)
    end
  end,
}
Fk:addSkill(shawu_select)
laiyinger:addSkill(xiaowu)
laiyinger:addSkill(huaping)
laiyinger:addRelatedSkill(shawu)
Fk:loadTranslationTable{
  ["laiyinger"] = "来莺儿",
  ["xiaowu"] = "绡舞",
  [":xiaowu"] = "出牌阶段限一次，你可以从你的上家或下家起选择任意名座位连续的其他角色，每名角色依次选择一项：1.令你摸一张牌；2.自己摸一张牌。"..
  "选择完成后，若令你摸牌的选择人数较多，你获得一个“沙”标记；若自己摸牌的选择人数较多，你对这些角色各造成1点伤害。",
  ["huaping"] = "化萍",
  [":huaping"] = "限定技，一名其他角色死亡时，你可以获得其所有武将技能，然后你失去〖绡舞〗和所有“沙”标记并摸等量的牌。"..
  "你死亡时，若此技能未发动过，你可令一名其他角色获得技能〖沙舞〗和所有“沙”标记。",
  ["shawu"] = "沙舞",
  ["shawu_select"] = "沙舞",
  [":shawu"] = "当你使用【杀】指定目标后，你可以弃置两张手牌或1枚“沙”标记对目标角色造成1点伤害。若你弃置的是“沙”标记，你摸两张牌。",

  ["#xiaowu"] = "发动绡舞，选择按顺时针或逆时针顺序结算，并选择作为终点的目标角色",
  ["xiaowu_clockwise"] = "顺时针顺序",
  ["xiaowu_anticlockwise"] = "逆时针顺序",
  ["#xiawu_draw"] = "绡舞：选择令%src摸一张牌或自己摸一张牌",
  ["xiaowu_draw1"] = "令其摸一张牌",
  ["@xiaowu_sand"] = "沙",
  ["#huaping-choose"] = "化萍：选择一名角色，令其获得沙舞",
  ["#huaping-invoke"] = "化萍：你可以获得%dest的所有武将技能，然后失去绡舞",
  ["#shawu-invoke"] = "沙舞：你可选择两张手牌弃置，或直接点确定弃置沙标记。来对%dest造成1点伤害",

  ["$xiaowu1"] = "繁星临云袖，明月耀舞衣。",
  ["$xiaowu2"] = "逐舞飘轻袖，传歌共绕梁。",
  ["$huaping1"] = "风絮飘残，化萍而终。",
  ["$huaping2"] = "莲泥刚倩，藕丝萦绕。",
  ["~laiyinger"] = "谷底幽兰艳，芳魂永留香……",
}

local caohua = General(extension, "caohua", "wei", 3, 3, General.Female)
local function doCaiyi(player, target, choice, n)
  local room = player.room
  local state = string.sub(choice, 6, 9)
  local i = tonumber(string.sub(choice, 10))
  if i == 4 then
    local num = {}
    for i = 1, 3, 1 do
      if player:getMark("caiyi"..state..tostring(i)) == 0 then
        table.insert(num, i)
      end
    end
    doCaiyi(player, target, "caiyi"..state..tostring(table.random(num)), n)
  else
    if state == "yang" then
      if i == 1 then
        if target:isWounded() then
          room:recover({
            who = target,
            num = math.min(n, target:getLostHp()),
            recoverBy = player,
            skillName = "caiyi",
          })
        end
      elseif i == 2 then
        target:drawCards(n, "caiyi")
      else
        if not target.faceup then
          target:turnOver()
        end
        if target.chained then
          target:setChainState(false)
        end
      end
    else
      if i == 1 then
        room:damage{
          to = target,
          damage = n,
          skillName = "caiyi",
        }
      elseif i == 2 then
        if #target:getCardIds{Player.Hand, Player.Equip} <= n then
          target:throwAllCards("he")
        else
          room:askForDiscard(target, n, n, true, "caiyi", false)
        end
      else
        target:turnOver()
        if not target.chained then
          target:setChainState(true)
        end
      end
    end
  end
end
local caiyi = fk.CreateTriggerSkill{
  name = "caiyi",
  anim_type = "switch",
  switch_skill_name = "caiyi",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
      local state = "yang"
      if player:getSwitchSkillState(self.name, false) == fk.SwitchYin then
        state = "yinn"
      end
      for i = 1, 4, 1 do
        local mark = "caiyi"..state..tostring(i)
        if player:getMark(mark) == 0 then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#caiyi1-invoke"
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYin then
      prompt = "#caiyi2-invoke"
    end
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local state = "yang"
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYin then
      state = "yinn"
    end
    for i = 1, 4, 1 do
      local mark = "caiyi"..state..tostring(i)
      if player:getMark(mark) == 0 then
        table.insert(choices, mark)
      end
    end
    local num = #choices
    if num == 4 then
      table.remove(choices, 4)
    end
    local to = room:getPlayerById(self.cost_data)
    local choice = room:askForChoice(to, choices, self.name, "#caiyi-choice:::"..tostring(num))
    room:setPlayerMark(player, choice, 1)
    doCaiyi(player, to, choice, num)
  end,
}
local guili = fk.CreateTriggerSkill{
  name = "guili",
  anim_type = "control",
  events = {fk.TurnStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
        local room = player.room
      if target == player and event == fk.TurnStart then
        local turn_event = room.logic:getCurrentEvent()
        if not turn_event then return false end
        local x = player:getMark("guili_record")
        if x == 0 then
          local events = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
          for _, e in ipairs(events) do
            local current_player = e.data[1]
            if current_player == player then
              x = e.id
              room:setPlayerMark(player, "guili_record", x)
              break
            end
          end
        end
        return turn_event.id == x
      elseif event == fk.TurnEnd and not target.dead and player:getMark(self.name) == target.id then
        local turn_event = room.logic:getCurrentEvent()
        if not turn_event then return false end
        local x = target:getMark("guili_record-round")
        if x == 0 then
          room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
            local current_player = e.data[1]
            if current_player == target then
              x = e.id
              room:setPlayerMark(target, "guili_record", x)
              return true
            end
          end, Player.HistoryRound)
        end
        return turn_event.id == x and #room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local damage = e.data[5]
          if damage and target == damage.from then
            return true
          end
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#guili-choose", self.name, false, true)
      local to
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:setPlayerMark(player, self.name, to)
      room:setPlayerMark(room:getPlayerById(to), "@@guili", 1)
    elseif event == fk.TurnEnd then
      player:gainAnExtraTurn(true)
    end
  end,
}
caohua:addSkill(caiyi)
caohua:addSkill(guili)
Fk:loadTranslationTable{
  ["caohua"] = "曹华",
  ["caiyi"] = "彩翼",
  [":caiyi"] = "转换技，结束阶段，你可以令一名角色选择一项并移除该选项：阳：1.回复X点体力；2.摸X张牌；3.复原武将牌；4.随机执行一个已移除的阳选项；"..
  "阴：1.受到X点伤害；2.弃置X张牌；3.翻面并横置；4.随机执行一个已移除的阴选项（X为当前状态剩余选项数）。",
  ["guili"] = "归离",
  [":guili"] = "你的第一个回合开始时，你选择一名其他角色。该角色每轮的第一个回合结束时，若其本回合未造成过伤害，你执行一个额外的回合。",
  ["#caiyi1-invoke"] = "彩翼：你可以令一名角色执行一个正面选项",
  ["#caiyi2-invoke"] = "彩翼：你可以令一名角色执行一个负面选项",
  ["#caiyi-choice"] = "彩翼：选择执行的一项（其中X为%arg）",
  ["caiyiyang1"] = "回复X点体力",
  ["caiyiyang2"] = "摸X张牌",
  ["caiyiyang3"] = "复原武将牌",
  ["caiyiyang4"] = "随机一个已移除的阳选项",
  ["caiyiyinn1"] = "受到X点伤害",
  ["caiyiyinn2"] = "弃置X张牌",
  ["caiyiyinn3"] = "翻面并横置",
  ["caiyiyinn4"] = "随机一个已移除的阴选项",
  ["@@guili"] = "归离",
  ["#guili-choose"] = "归离：选择一名角色，其回合结束时，若其本回合未造成过伤害，你执行一个额外回合",

  ["$caiyi1"] = "凰凤化越，彩翼犹存。",
  ["$caiyi2"] = "身披彩翼，心有灵犀。",
  ["$guili1"] = "既离厄海，当归泸沽。",
  ["$guili2"] = "山野如春，不如归去。",
  ["~caohua"] = "自古忠孝难两全……",
}

local zhangfen = General(extension, "zhangfen", "wu", 4)
local wanglu_engine = {{"siege_engine", Card.Spade, 9}}
local wanglu = fk.CreateTriggerSkill{
  name = "wanglu",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "siege_engine" end) then
      player:gainAnExtraPhase(Player.Play)
    else
      local engine = table.find(U.prepareDeriveCards(room, wanglu_engine, "wanglu_engine"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if engine and U.canMoveCardIntoEquip(player, engine) then
        for i = 1, 3, 1 do
          room:setPlayerMark(player, "xianzhu"..tostring(i), 0)
        end
        U.moveCardIntoEquip (room, player, engine, self.name, true, player)
      end
    end
  end,
}
local xianzhu = fk.CreateTriggerSkill{
  name = "xianzhu",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and
    table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "siege_engine" end)
    and (player:getMark("xianzhu1") + player:getMark("xianzhu2") + player:getMark("xianzhu3")) < 5
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"xianzhu2", "xianzhu3"}
    if player:getMark("xianzhu1") == 0 then
      table.insert(choices, 1, "xianzhu1")
    end
    local choice = room:askForChoice(player, choices, self.name, "#xianzhu-choice")
    room:addPlayerMark(player, choice, 1)
  end,
}
local chaixie = fk.CreateTriggerSkill{
  name = "chaixie",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.toArea == Card.Void then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId, true).name == "siege_engine" then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for i = 1, 3, 1 do
      n = n + player:getMark("xianzhu"..tostring(i))
      room:setPlayerMark(player, "xianzhu"..tostring(i), 0)
    end
    player:drawCards(n, self.name)
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local mirror_moves = {}
    local to_void, cancel_move = {},{}
    local no_updata = (player:getMark("xianzhu1") + player:getMark("xianzhu2") + player:getMark("xianzhu3")) == 0
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea ~= Card.Void then
        local move_info = {}
        local mirror_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if Fk:getCardById(id, true).name == "siege_engine" and info.fromArea == Card.PlayerEquip then
            if no_updata and move.moveReason == fk.ReasonDiscard then
              table.insert(cancel_move, id)
            else
              table.insert(mirror_info, info)
              table.insert(to_void, id)
            end
          else
            table.insert(move_info, info)
          end
        end
        move.moveInfo = move_info
        if #mirror_info > 0 then
          local mirror_move = table.clone(move)
          mirror_move.to = nil
          mirror_move.toArea = Card.Void
          mirror_move.moveInfo = mirror_info
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    if #cancel_move > 0 then
      player.room:sendLog{ type = "#cancelDismantle", card = cancel_move, arg = "#siege_engine_skill"  }
    end
    if #to_void > 0 then
      table.insertTable(data, mirror_moves)
      player.room:sendLog{ type = "#destructDerivedCards", card = to_void, }
    end
  end,
}
zhangfen:addSkill(wanglu)
zhangfen:addSkill(xianzhu)
zhangfen:addSkill(chaixie)
Fk:loadTranslationTable{
  ["zhangfen"] = "张奋",
  ["wanglu"] = "望橹",
  [":wanglu"] = "锁定技，准备阶段，你将【大攻车】置入你的装备区，若你的装备区内已有【大攻车】，则你执行一个额外的出牌阶段。<br>"..
  "<font color='grey'>【大攻车】<br>♠9 装备牌·宝物<br /><b>装备技能</b>：出牌阶段开始时，你可以视为使用一张【杀】，"..
  "当此【杀】对目标角色造成伤害后，你弃置其一张牌。若此牌未升级，则防止此牌被弃置。此牌离开装备区时销毁。",
  ["xianzhu"] = "陷筑",
  [":xianzhu"] = "当你使用【杀】造成伤害后，你可以升级【大攻车】（每个【大攻车】最多升级5次）。升级选项：<br>"..
  "【大攻车】的【杀】无视距离和防具；<br>【大攻车】的【杀】可指定目标+1；<br>【大攻车】的【杀】造成伤害后弃牌数+1。",
  ["chaixie"] = "拆械",
  [":chaixie"] = "锁定技，当【大攻车】销毁后，你摸X张牌（X为该【大攻车】的升级次数）。",
  ["#xianzhu-choice"] = "陷筑：选择【大攻车】使用【杀】的增益效果",
  ["xianzhu1"] = "无视距离和防具",
  ["xianzhu2"] = "可指定目标+1",
  ["xianzhu3"] = "造成伤害后弃牌数+1",
  
  ["$wanglu1"] = "大攻车前，坚城弗当。",
  ["$wanglu2"] = "大攻既作，天下可望！",
  ["$xianzhu1"] = "敌垒已陷，当长驱直入！",
  ["$xianzhu2"] = "舍命陷登，击蛟蟒于狂澜！",
  ["$chaixie1"] = "利器经久，拆合自用。",
  ["$chaixie2"] = "损一得十，如鲸落宇。",
  ["~zhangfen"] = "身陨外，愿魂归江东……",
}

local zhugeruoxue = General(extension, "zhugeruoxue", "wei", 3, 3, General.Female)
local qiongying = fk.CreateActiveSkill{
  name = "qiongying",
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  prompt = "#qiongying",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:currentRoom():getPlayerById(selected[1]):canMoveCardsInBoardTo(target, nil)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local result = room:askForMoveCardInBoard(player, room:getPlayerById(effect.tos[1]), room:getPlayerById(effect.tos[2]), self.name)
    if player.dead or player:isKongcheng() then return end
    local suit = result.card:getSuitString()
    if #room:askForDiscard(player, 1, 1, false, self.name, false, ".|.|"..suit) == 0 then
      player:showCards(player:getCardIds("h"))
    end
  end,
}
local nuanhui = fk.CreateTriggerSkill{
  name = "nuanhui",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      table.find(player.room.alive_players, function(p) return #p:getCardIds("e") > 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room.alive_players, function(p) return #p:getCardIds("e") > 0 end), Util.IdMapper)
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#nuanhui-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local n = #to:getCardIds("e")
    local count = 0
    room:addPlayerMark(to, MarkEnum.BypassTimesLimit.."-tmp", 1)
    for i = 1, n, 1 do
      if to.dead then return end
      local success, dat = room:askForUseActiveSkill(to, "nuanhui_viewas", "#nuanhui-use:::"..i..":"..n, true)
      if success then
        count = i
        local card = Fk.skills["nuanhui_viewas"]:viewAs(dat.cards)
        card.skillName = self.name
        room:useCard{
          from = player.id,
          tos = table.map(dat.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
      else
        break
      end
    end
    if not to.dead then
      room:removePlayerMark(to, MarkEnum.BypassTimesLimit.."-tmp", 1)
      if count > 1 then
        to:throwAllCards("e")
      end
    end
  end,
}
local nuanhui_viewas = fk.CreateViewAsSkill{
  name = "nuanhui_viewas",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and not card.is_derived and Self:canUse(card) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "nuanhui"
    return card
  end,
}
Fk:addSkill(nuanhui_viewas)
zhugeruoxue:addSkill(qiongying)
zhugeruoxue:addSkill(nuanhui)
Fk:loadTranslationTable{
  ["zhugeruoxue"] = "诸葛若雪",
  ["qiongying"] = "琼英",
  [":qiongying"] = "出牌阶段限一次，你可以移动场上一张牌，然后你弃置一张同花色的手牌（若没有需展示手牌）。",
  ["nuanhui"] = "暖惠",
  [":nuanhui"] = "结束阶段，你可以选择一名角色，该角色可视为使用X张基本牌（X为其装备区牌数）。若其使用超过一张，结算完成后弃置装备区所有牌。",
  ["#qiongying"] = "琼英：你可以移动场上一张牌，然后弃置一张此花色的手牌",
  ["#nuanhui-choose"] = "暖惠：选择一名角色，其可以视为使用其装备区内牌张数的基本牌",
  ["nuanhui_viewas"] = "暖惠",
  ["#nuanhui-use"] = "暖惠：你可以视为使用基本牌（第%arg张，共%arg2张）",

  ["$qiongying1"] = "冰心碎玉壶，光转琼英灿。",
  ["$qiongying2"] = "玉心玲珑意，撷英倚西楼。",
  ["$nuanhui1"] = "暖阳映雪，可照八九之风光。",
  ["$nuanhui2"] = "晓风和畅，吹融附柳之霜雪。",
  ["~zhugeruoxue"] = "自古佳人叹白头……",
}

--高山仰止：王朗 刘徽
local wanglang = General(extension, "ty__wanglang", "wei", 3)
local ty__gushe = fk.CreateActiveSkill{
  name = "ty__gushe",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  can_use = function(self, player)
    return not player:isKongcheng() and player:getMark("ty__gushe-turn") < 7 - player:getMark("@ty__raoshe")
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < 3 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.map(effect.tos, function(p) return room:getPlayerById(p) end)
    local pindian = player:pindian(targets, self.name)
    for _, target in ipairs(targets) do
      local losers = {}
      if pindian.results[target.id].winner then
        if pindian.results[target.id].winner == player then
          table.insert(losers, target)
        else
          table.insert(losers, player)
        end
      else
        table.insert(losers, player)
        table.insert(losers, target)
      end
      for _, p in ipairs(losers) do
        if p == player then
          room:addPlayerMark(player, "@ty__raoshe", 1)
          if player:getMark("@ty__raoshe") >= 7 then
            room:killPlayer({who = player.id,})
          end
        end
        local cancelable = true
        local prompt = "#ty__gushe-discard:"..player.id
        if player.dead then
          cancelable = false
          prompt = "#ty__gushe2-discard"
        end
        if #room:askForDiscard(p, 1, 1, true, self.name, cancelable, ".", prompt) == 0 and not player.dead then
          player:drawCards(1, self.name)
        end
      end
    end
  end,
}
local ty__gushe_record = fk.CreateTriggerSkill{
  name = "#ty__gushe_record",

  refresh_events = {fk.PindianResultConfirmed},
  can_refresh = function(self, event, target, player, data)
    return data.winner and data.winner == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "ty__gushe-turn", 1)
    if player:getMark("ty__gushe-turn") >= (7 - player:getMark("@ty__raoshe")) and player:hasSkill("ty__gushe", true) then
      room:setPlayerMark(player, "@@ty__gushe-turn", 1)
    end
  end,
}
local ty__jici = fk.CreateTriggerSkill{
  name = "ty__jici",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.PindianCardsDisplayed, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PindianCardsDisplayed then
      if player:hasSkill(self) then
        if data.from == player then
          return data.fromCard.number <= player:getMark("@ty__raoshe")
        elseif table.contains(data.tos, player) then
          return data.results[player.id].toCard.number <= player:getMark("@ty__raoshe")
        end
      end
    elseif event == fk.Death then
      return target == player and player:hasSkill(self.name, false, true) and data.damage and data.damage.from and not data.damage.from.dead
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PindianCardsDisplayed then
      local card
      if data.from == player then
        card = data.fromCard
      elseif table.contains(data.tos, player) then
        card = data.results[player.id].toCard
      end
      card.number = card.number + player:getMark("@ty__raoshe")
      if player.dead then return end
      local n = card.number
      if data.fromCard.number > n then
        n = data.fromCard.number
      end
      for _, result in pairs(data.results) do
        if result.toCard.number > n then
          n = result.toCard.number
        end
      end
      local cards = {}
      if data.fromCard.number == n and room:getCardArea(data.fromCard) == Card.Processing then
        table.insertIfNeed(cards, data.fromCard)
      end
      for _, result in pairs(data.results) do
        if result.toCard.number == n and room:getCardArea(data.fromCard) == Card.Processing then
          table.insertIfNeed(cards, result.toCard)
        end
      end
      if #cards > 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(cards)
        room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
      end
    elseif event == fk.Death then
      local n = 7 - player:getMark("@ty__raoshe")
      if n > 0 and not data.damage.from:isNude() then
        if #data.damage.from:getCardIds{Player.Hand, Player.Equip} <= n then
          data.damage.from:throwAllCards("he")
        else
          room:askForDiscard(data.damage.from, n, n, true, self.name, false)
        end
      end
      if not data.damage.from.dead then
        room:loseHp(data.damage.from, 1, self.name)
      end
    end
  end,
}
ty__gushe:addRelatedSkill(ty__gushe_record)
wanglang:addSkill(ty__gushe)
wanglang:addSkill(ty__jici)
Fk:loadTranslationTable{
  ["ty__wanglang"] = "王朗",
  ["ty__gushe"] = "鼓舌",
  [":ty__gushe"] = "出牌阶段，你可以用一张手牌与至多三名角色同时拼点，没赢的角色选择一项: 1.弃置一张牌；2.令你摸一张牌。"..
  "若你没赢，获得一个“饶舌”标记；若你有7个“饶舌”标记，你死亡。当你一回合内累计七次拼点赢时（每有一个“饶舌”标记，此累计次数减1），本回合此技能失效。",
  ["ty__jici"] = "激词",
  [":ty__jici"] = "锁定技，当你的拼点牌亮出后，若此牌点数小于等于X，则点数+X（X为“饶舌”标记的数量）且你获得本次拼点中点数最大的牌。"..
  "你死亡时，杀死你的角色弃置7-X张牌并失去1点体力。",
  ["#ty__gushe-discard"] = "鼓舌：你需弃置一张牌，否则 %src 摸一张牌",
  ["#ty__gushe2-discard"] = "鼓舌：你需弃置一张牌",
  ["@@ty__gushe-turn"] = "鼓舌失效",
  ["@ty__raoshe"] = "饶舌",

  ["$ty__gushe1"] = "承寇贼之要，相时而后动，择地而后行，一举更无余事。",
  ["$ty__gushe2"] = "春秋之义，求诸侯莫如勤王。今天王在魏都，宜遣使奉承王命。",
  ["$ty__jici1"] = "天数有变，神器更易，而归于有德之人，此自然之理也。",
  ["$ty__jici2"] = "王命之师，囊括五湖，席卷三江，威取中国，定霸华夏。",
  ["~ty__wanglang"] = "我本东海弄墨客，如何枉做沙场魂……",
}

--钟灵毓秀：董贵人 滕芳兰 张瑾云 周不疑
local dongguiren = General(extension, "dongguiren", "qun", 3, 3, General.Female)
local lianzhi = fk.CreateTriggerSkill{
  name = "lianzhi",
  anim_type = "special",
  events = {fk.GameStart, fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        return player:getMark(self.name) == target.id
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    if event == fk.GameStart then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#lianzhi-choose", self.name, false, true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:setPlayerMark(player, self.name, to.id)
    else
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#lianzhi2-choose", self.name, true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
        room:handleAddLoseSkills(player, "shouze", nil, true, false)
        room:handleAddLoseSkills(to, "shouze", nil, true, false)
        room:addPlayerMark(to, "@dongguiren_jiao", math.max(player:getMark("@dongguiren_jiao"), 1))
      end
    end
  end,
}
local lianzhi_trigger = fk.CreateTriggerSkill{
  name = "#lianzhi_trigger",
  mute = true,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("lianzhi") and player:getMark("lianzhi") ~= 0 and
      not player.room:getPlayerById(player:getMark("lianzhi")).dead and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("lianzhi")
    room:notifySkillInvoked(player, "lianzhi", "support")
    local lianzhi_id = player:getMark("lianzhi")
    local to = room:getPlayerById(lianzhi_id)
    if player:getMark("@lianzhi") == 0 then
      room:setPlayerMark(player, "@lianzhi", to.general)
    end
    room:doIndicate(player.id, {lianzhi_id})
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = "lianzhi"
    })
    if not player.dead then
      player:drawCards(1, "lianzhi")
    end
    if not to.dead then
      to:drawCards(1, "lianzhi")
    end
  end,
}
local lingfang = fk.CreateTriggerSkill{
  name = "lingfang",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseStart then
      return player == target and player.phase == Player.Start
    elseif event == fk.CardUseFinished then
      if data.card.color == Card.Black and data.tos then
        if target == player then
          return table.find(TargetGroup:getRealTargets(data.tos), function(id) return id ~= player.id end)
        else
          return table.contains(TargetGroup:getRealTargets(data.tos), player.id)
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@dongguiren_jiao", 1)
  end,
}
local fengying = fk.CreateViewAsSkill{
  name = "fengying",
  anim_type = "special",
  pattern = ".",
  prompt = "#fengying",
  interaction = function()
    local all_names, names = Self:getMark("fengying"), {}
    for _, name in ipairs(all_names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = "fengying"
      if ((Fk.currentResponsePattern == nil and to_use.skill:canUse(Self, to_use) and not Self:prohibitUse(to_use)) or
         (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
        table.insertIfNeed(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).number <= Self:getMark("@dongguiren_jiao") and
      Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    local names = player:getMark("fengying")
    if player:getMark("@dongguiren_jiao") == 0 or type(names) ~= "table" then return false end
    for _, name in ipairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if to_use.skill:canUse(player, to_use) and not player:prohibitUse(to_use) then
        return true
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    local names = player:getMark("fengying")
    if player:getMark("@dongguiren_jiao") == 0 or type(names) ~= "table" then return false end
    for _, name in ipairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use)) then
        return true
      end
    end
  end,
  before_use = function(self, player, useData)
    local names = player:getMark("fengying")
    if type(names) == "table" then
      table.removeOne(names, useData.card.name)
      player.room:setPlayerMark(player, "fengying", names)
      player.room:setPlayerMark(player, "@$fengying", names)
    end
  end,
}
local fengying_trigger = fk.CreateTriggerSkill{
  name = "#fengying_trigger",
  events = {fk.TurnStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fengying.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local names = {}
    for _, id in ipairs(player.room.discard_pile) do
      local card = Fk:getCardById(id)
      if card.color == Card.Black and (card.type == Card.TypeBasic or card:isCommonTrick()) then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    player.room:setPlayerMark(player, "fengying", names)
    if player:hasSkill("fengying", true) then
      player.room:setPlayerMark(player, "@$fengying", names)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data.name == "fengying"
  end,
  on_refresh = function(self, event, target, player, data)
      player.room:setPlayerMark(player, "fengying", 0)
      player.room:setPlayerMark(player, "@$fengying", 0)
  end,
}
local fengying_targetmod = fk.CreateTargetModSkill{
  name = "#fengying_targetmod",
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, "fengying")
  end,
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "fengying")
  end,
}
local shouze = fk.CreateTriggerSkill{
  name = "shouze",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and player:getMark("@dongguiren_jiao") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@dongguiren_jiao", 1)
    local card = room:getCardsFromPileByRule(".|.|spade,club", 1, "discardPile")
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
    room:loseHp(player, 1, self.name)
  end,
}
lianzhi:addRelatedSkill(lianzhi_trigger)
fengying:addRelatedSkill(fengying_trigger)
fengying:addRelatedSkill(fengying_targetmod)
dongguiren:addSkill(lianzhi)
dongguiren:addSkill(lingfang)
dongguiren:addSkill(fengying)
dongguiren:addRelatedSkill(shouze)
Fk:loadTranslationTable{
  ["dongguiren"] = "董贵人",
  ["lianzhi"] = "连枝",
  [":lianzhi"] = "游戏开始时，你选择一名其他角色。每回合限一次，当你进入濒死状态时，若该角色没有死亡，你回复1点体力且与其各摸一张牌。"..
  "该角色死亡时，你可以选择一名其他角色，你与其获得〖受责〗，其获得与你等量的“绞”标记（至少1个）。",
  ["lingfang"] = "凌芳",
  [":lingfang"] = "锁定技，准备阶段或当其他角色对你使用或你对其他角色使用的黑色牌结算后，你获得一枚“绞”标记。",
  ["fengying"] = "风影",
  ["#fengying_trigger"] = "风影",
  [":fengying"] = "每个回合开始时，记录此时弃牌堆中的黑色基本牌和黑色普通锦囊牌牌名。"..
  "每回合每种牌名限一次，你可以将一张点数不大于“绞”标记数的手牌当一张记录的牌使用，且无距离和次数限制。",
  ["shouze"] = "受责",
  [":shouze"] = "锁定技，结束阶段，你弃置一枚“绞”，然后随机获得弃牌堆一张黑色牌并失去1点体力。",
  ["@lianzhi"] = "连枝",
  ["#lianzhi-choose"] = "连枝：选择一名角色成为“连枝”角色",
  ["#lianzhi2-choose"] = "连枝：你可以选择一名角色，你与其获得技能〖受责〗",
  ["@dongguiren_jiao"] = "绞",
  ["@$fengying"] = "风影",
  ["#fengying"] = "发动风影，将一张点数不大于绞标记数的手牌当一张记录的牌使用",

  ["$lianzhi1"] = "刘董同气连枝，一损则俱损。",
  ["$lianzhi2"] = "妾虽女流，然亦有忠侍陛下之心。",
  ["$lingfang1"] = "曹贼欲加之罪，何患无据可言。",
  ["$lingfang2"] = "花落水自流，何须怨东风。",
  ["$fengying1"] = "可怜东篱寒累树，孤影落秋风。",
  ["$fengying2"] = "西风落，西风落，宫墙不堪破。",
  ["~dongguiren"] = "陛下乃大汉皇帝，不可言乞。",
}

local tengfanglan = General(extension, "ty__tengfanglan", "wu", 3, 3, General.Female)
local ty__luochong = fk.CreateTriggerSkill{
  name = "ty__luochong",
  anim_type = "control",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:getMark(self.name) < 4 and
      not table.every(player.room.alive_players, function (p) return p:isAllNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p) return not p:isAllNude() end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1,
      "#ty__luochong-choose:::"..tostring(4 - player:getMark(self.name))..":"..tostring(4 - player:getMark(self.name)), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local total = 4 - player:getMark(self.name)
    local n = total
    local to = room:getPlayerById(self.cost_data)
    repeat
      local cards = room:askForCardsChosen(player, to, 1, n, "hej", self.name)
      if #cards > 0 then
        room:throwCard(cards, self.name, to, player)
        room:addPlayerMark(to, "ty__luochong_target", #cards)
        n = n - #cards
        if n <= 0 then break end
      end
      local targets = table.map(table.filter(room.alive_players, function(p)
        return not p:isAllNude() end), Util.IdMapper)
      if #targets == 0 then break end
      local tos = room:askForChoosePlayers(player, targets, 1, 1,
        "#ty__luochong-choose:::"..tostring(total)..":"..tostring(n), self.name, true)
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        break
      end
    until total == 0 or player.dead
    if table.find(room.players, function(p) return p:getMark("ty__luochong_target") > 2 end) then
      room:addPlayerMark(player, self.name, 1)
    end
    for _, p in ipairs(room.players) do
      room:setPlayerMark(p, "ty__luochong_target", 0)
    end
  end,
}
local ty__aichen = fk.CreateTriggerSkill{
  name = "ty__aichen",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.EventPhaseChanging, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove and #player.room.draw_pile > 80 and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 then
        for _, move in ipairs(data) do
          if move.skillName == "ty__luochong" and move.from == player.id then
            return true
          end
        end
      elseif event == fk.EventPhaseChanging and #player.room.draw_pile > 40 then
        return target == player and data.to == Player.Discard
      elseif event == fk.TargetConfirmed and #player.room.draw_pile < 40 then
        return target == player and data.card.type ~= Card.TypeEquip and data.card.suit == Card.Spade
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      player:drawCards(2, self.name)
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "drawcard")
    elseif event == fk.EventPhaseChanging then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "defensive")
      return true
    elseif event == fk.TargetConfirmed then
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
      data.disresponsiveList = data.disresponsiveList or {}
      table.insertIfNeed(data.disresponsiveList, player.id)
    end
  end,
}
tengfanglan:addSkill(ty__luochong)
tengfanglan:addSkill(ty__aichen)
Fk:loadTranslationTable{
  ["ty__tengfanglan"] = "滕芳兰",
  ["ty__luochong"] = "落宠",
  [":ty__luochong"] = "每轮开始时，你可以弃置任意名角色区域内共计至多4张牌，若你一次性弃置了一名角色区域内至少3张牌，〖落宠〗弃置牌数-1。",
  ["ty__aichen"] = "哀尘",
  [":ty__aichen"] = "锁定技，若剩余牌堆数大于80，当你发动〖落宠〗弃置自己区域内的牌后，你摸两张牌；"..
  "若剩余牌堆数大于40，你跳过弃牌阶段；若剩余牌堆数小于40，当你成为♠牌的目标后，你不能响应此牌。",
  ["#ty__luochong-choose"] = "落宠：你可以依次选择角色，弃置其区域内的牌（共计至多%arg张，还剩%arg2张）",

  ["$ty__luochong1"] = "陛下独宠她人，奈何雨露不均。",
  ["$ty__luochong2"] = "妾贵于佳丽，然宠不及三千。",
  ["$ty__aichen1"] = "君可负妾，然妾不负君。",
  ["$ty__aichen2"] = "所思所想，皆系陛下。",
  ["~ty__tengfanglan"] = "今生缘尽，来世两宽……",
}

local zhangjinyun = General(extension, "zhangjinyun", "shu", 3, 3, General.Female)
local huizhi = fk.CreateTriggerSkill{
  name = "huizhi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local discard_data = {
      num = 999,
      min_num = 0,
      include_equip = false,
      skillName = self.name,
      pattern = ".",
    }
    local success, ret = player.room:askForUseActiveSkill(player, "discard_skill", "#huizhi-invoke", true, discard_data)
    if success then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data > 0 then
      room:throwCard(self.cost_data, self.name, player, player)
    end
    local n = 0
    for _, p in ipairs(room.alive_players) do
      n = math.max(n, p:getHandcardNum())
    end
    room:drawCards(player, math.max(math.min(n - player:getHandcardNum(), 5), 1), self.name)
  end,
}
local jijiao = fk.CreateActiveSkill{
  name = "jijiao",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and #Fk:currentRoom().discard_pile > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local ids = {}
    local discard_pile = table.simpleClone(room.discard_pile)
    local logic = room.logic
    local events = logic.event_recorder[GameEvent.MoveCards] or Util.DummyTable
    for i = #events, 1, -1 do
      local e = events[i]
      local move_by_use = false
      local parentUseEvent = e:findParent(GameEvent.UseCard)
      if parentUseEvent then
        local use = parentUseEvent.data[1]
        if use.from == effect.from then
          move_by_use = true
        end
      end
      for _, move in ipairs(e.data) do
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.removeOne(discard_pile, id) and Fk:getCardById(id):isCommonTrick() then
            if move.toArea == Card.DiscardPile then
              if move.moveReason == fk.ReasonUse and move_by_use then
                table.insert(ids, id)
              elseif move.moveReason == fk.ReasonDiscard and move.from == player.id then
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  table.insert(ids, id)
                end
              end
            end
          end
        end
      end
      if #discard_pile == 0 then break end
    end

    if #ids > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(ids)
      room:setPlayerMark(player, "jijiao_cards", dummy.subcards)
      room:obtainCard(target.id, dummy, true, fk.ReasonJustMove)
    end
  end,
}
local jijiao_record = fk.CreateTriggerSkill{
  name = "#jijiao_record",
  anim_type = "special",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:getMark(self.name) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
    player:setSkillUseHistory("jijiao", 0, Player.HistoryGame)
  end,

  refresh_events = {fk.AfterDrawPileShuffle, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return player:usedSkillTimes("jijiao", Player.HistoryGame) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 1)
  end,
}
local jijiao_trigger = fk.CreateTriggerSkill{
  name = "#jijiao_trigger",
  mute = true,
  events = {fk.CardUsing, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("jijiao_cards") ~= 0 and #player:getMark("jijiao_cards") > 0 then
      if event == fk.CardUsing then
        return target == player and data.card:isCommonTrick() and not data.card:isVirtual()
      else
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then  --TODO: 这也弄个全局记录！
      local mark = player:getMark("jijiao_cards")
      if table.contains(mark, data.card.id) then
        data.prohibitedCardNames = {"nullification"}
        table.removeOne(mark, data.card.id)
        room:setPlayerMark(player, "jijiao_cards", mark)
      end
    else
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              local mark = player:getMark("jijiao_cards")
              if table.contains(mark, info.cardId) then
                table.removeOne(mark, info.cardId)
                room:setPlayerMark(player, "jijiao_cards", mark)
              end
            end
          end
        end
      end
    end
  end,
}
jijiao:addRelatedSkill(jijiao_record)
jijiao:addRelatedSkill(jijiao_trigger)
zhangjinyun:addSkill(huizhi)
zhangjinyun:addSkill(jijiao)
Fk:loadTranslationTable{
  ["zhangjinyun"] = "张瑾云",
  ["huizhi"] = "蕙质",
  [":huizhi"] = "准备阶段，你可以弃置任意张手牌（可不弃），然后将手牌摸至与全场手牌最多的角色相同（至少摸一张，最多摸五张）。",
  ["jijiao"] = "继椒",
  [":jijiao"] = "限定技，出牌阶段，你可以令一名角色获得弃牌堆中本局游戏你使用和弃置的所有普通锦囊牌，这些牌不能被【无懈可击】响应。"..
  "每回合结束后，若此回合内牌堆洗过牌或有角色死亡，复原此技能。",
  ["#huizhi-invoke"] = "蕙质：你可以弃置任意张手牌，然后将手牌摸至与全场手牌最多的角色相同（最多摸五张）",
  ["#jijiao_record"] = "继椒",

  ["$huizhi1"] = "妾有一席幽梦，予君三千暗香。",
  ["$huizhi2"] = "我有玲珑之心，其情唯衷陛下。",
  ["$jijiao1"] = "哀吾姊早逝，幸陛下垂怜。",
  ["$jijiao2"] = "居椒之殊荣，妾得之惶恐。",
  ["~zhangjinyun"] = "陛下，妾身来陪你了……",
}

local zhoubuyi = General(extension, "zhoubuyi", "wei", 3)
local shijiz = fk.CreateTriggerSkill{
  name = "shijiz",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Finish and not target:isNude() then
      local events = player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
        local damage = e.data[5]
        return damage and target == damage.from
      end, Player.HistoryTurn)
      return #events == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("shijiz_names")
    if type(mark) ~= "table" then
      mark = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card:isCommonTrick() and not card.is_derived then
          table.insertIfNeed(mark, card.name)
        end
      end
      room:setPlayerMark(player, "shijiz_names", mark)
    end
    local mark2 = player:getMark("@$shijiz-round")
    if mark2 == 0 then mark2 = {} end
    local names, choices = {}, {}
    for _, name in ipairs(mark) do
      local card = Fk:cloneCard(name)
      card.skillName = self.name
      if target:canUse(card) and not target:prohibitUse(card) then
        table.insert(names, name)
        if not table.contains(mark2, name) then
          table.insert(choices, name)
        end
      end
    end
    table.insert(names, "Cancel")
    table.insert(choices, "Cancel")
    local choice = room:askForChoice(player, choices, self.name, "#shijiz-invoke::"..target.id, false, names)
    if choice ~= "Cancel" then
      room:doIndicate(player.id, {target.id})
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@$shijiz-round")
    if mark == 0 then mark = {} end
    table.insert(mark, self.cost_data)
    room:setPlayerMark(player, "@$shijiz-round", mark)
    room:doIndicate(player.id, {target.id})
    room:setPlayerMark(target, "shijiz-tmp", self.cost_data)
    local success, dat = room:askForUseActiveSkill(target, "shijiz_viewas", "#shijiz-use:::"..self.cost_data, true)
    room:setPlayerMark(target, "shijiz-tmp", 0)
    if success then
      local card = Fk:cloneCard(self.cost_data)
      card:addSubcards(dat.cards)
      card.skillName = self.name
      room:useCard{
        from = target.id,
        tos = table.map(dat.targets, function(p) return {p} end),
        card = card,
      }
    end
  end,
}
local shijiz_viewas = fk.CreateViewAsSkill{
  name = "shijiz_viewas",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getMark("shijiz-tmp") ~= 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(Self:getMark("shijiz-tmp"))
    card:addSubcard(cards[1])
    card.skillName = "shijiz"
    return card
  end,
}
local shijiz_prohibit = fk.CreateProhibitSkill{
  name = "#shijiz_prohibit",
  is_prohibited = function(self, from, to, card)
    return card and from == to and table.contains(card.skillNames, "shijiz")
  end,
}
local silun = fk.CreateTriggerSkill{
  name = "silun",
  anim_type = "masochism",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start
      else
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(4, self.name)
    for i = 1, 4, 1 do
      if player.dead or player:isNude() then return end
      local success, _ = room:askForUseActiveSkill(player, "silun_active", "#silun-card:::" .. tostring(i), false)
      if not success then
        room:moveCards({
          ids = {player:getCardIds("he")[1]},
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = self.name,
        })
      end
    end
  end,
}
local silun_active = fk.CreateActiveSkill{
  name = "silun_active",
  mute = true,
  card_num = 1,
  max_target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"Field", "Top", "Bottom"}}
  end,
  card_filter = function(self, to_select, selected, targets)
    if #selected == 0 then
      if self.interaction.data == "Field" then
        local card = Fk:getCardById(to_select)
        return card.type == Card.TypeEquip or card.sub_type == Card.SubtypeDelayedTrick
      end
      return true
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and self.interaction.data == "Field" and #selected_cards == 1 then
      local card = Fk:getCardById(selected_cards[1])
      local target = Fk:currentRoom():getPlayerById(to_select)
      if card.type == Card.TypeEquip then
        return target:hasEmptyEquipSlot(card.sub_type)
      elseif card.sub_type == Card.SubtypeDelayedTrick then
        return not target:isProhibited(target, card)
      end
      return false
    end
  end,
  feasible = function(self, selected, selected_cards)
    if #selected_cards == 1 then
      if self.interaction.data == "Field" then
        return #selected == 1
      else
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card_id = effect.cards[1]
    local reset_self = room:getCardArea(card_id) == Card.PlayerEquip
    if self.interaction.data == "Field" then
      local target = room:getPlayerById(effect.tos[1])
      local card = Fk:getCardById(card_id)
      if card.type == Card.TypeEquip then
        room:moveCardTo(card, Card.PlayerEquip, target, fk.ReasonPut, "silun", "", true, player.id)
        if reset_self and not player.dead then
          player:reset()
        end
        if not target.dead then
          target:reset()
        end
      elseif card.sub_type == Card.SubtypeDelayedTrick then
        room:moveCardTo(card, Card.PlayerJudge, target, fk.ReasonPut, "silun", "", true, player.id)
        if reset_self and not player.dead then
          player:reset()
        end
      end
    else
      local drawPilePosition = 1
      if self.interaction.data == "Bottom" then
        drawPilePosition = -1
      end
      room:moveCards({
        ids = effect.cards,
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = "silun",
        drawPilePosition = drawPilePosition,
      })
      if reset_self and not player.dead then
        player:reset()
      end
    end
  end,
}
Fk:addSkill(shijiz_viewas)
shijiz:addRelatedSkill(shijiz_prohibit)
Fk:addSkill(silun_active)
zhoubuyi:addSkill(shijiz)
zhoubuyi:addSkill(silun)
Fk:loadTranslationTable{
  ["zhoubuyi"] = "周不疑",
  ["shijiz"] = "十计",
  [":shijiz"] = "一名角色的结束阶段，若其本回合未造成伤害，你可以声明一种普通锦囊牌（每轮每种牌名限一次），其可以将一张牌当你声明的牌使用"..
  "（不能指定其为目标）。",
  ["silun"] = "四论",
  [":silun"] = "准备阶段或当你受到伤害后，你可以摸四张牌，然后将四张牌依次置于场上、牌堆顶或牌堆底，若此牌为你装备区里的牌，你复原武将牌，"..
  "若你将装备牌置于一名角色装备区，其复原武将牌。",
  ["@$shijiz-round"] = "十计",
  ["#shijiz-invoke"] = "十计：你可以选择一种锦囊，令 %dest 可以将一张牌当此牌使用（不能指定其自己为目标）",
  ["shijiz_viewas"] = "十计",
  ["#shijiz-use"] = "十计：你可以将一张牌当【%arg】使用",
  ["silun_active"] = "四论",
  ["#silun-card"] = "四论：将一张牌置于场上、牌堆顶或牌堆底（第%arg张/共4张）",
  ["Field"] = "场上",

  ["$shijiz1"] = "区区十丈之城，何须丞相图画。",
  ["$shijiz2"] = "顽垒在前，可依不疑之计施为。",
  ["$silun1"] = "习守静之术，行务时之风。",
  ["$silun2"] = "纵笔瑞白雀，满座尽高朋。",
  ["~zhoubuyi"] = "人心者，叵测也。",
}

local xujing = General(extension, "ty__xujing", "shu", 3)

local shangyu = fk.CreateTriggerSkill{
  name = "shangyu",
  events = {fk.AfterCardsMove, fk.Damage, fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.AfterCardsMove then
      local cid = player:getMark("shangyu_slash")
      if player.room:getCardArea(cid) ~= Card.DiscardPile then return false end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.cardId == cid then
              return true
            end
          end
        end
      end
    elseif event == fk.Damage then
      if data.card and data.card.trueName == "slash" then
        local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
        if #cardlist == 1 and cardlist[1] == player:getMark("shangyu_slash") then
          local room = player.room
          local parentUseEvent = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
          if parentUseEvent then
            local use = parentUseEvent.data[1]
            local from = room:getPlayerById(use.from)
            if from and not from.dead then
              self.cost_data = use.from
              return true
            end
          end
        end
      end
    elseif event == fk.GameStart then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local targets = table.map(room.alive_players, Util.IdMapper)
      local marks = player:getMark("shangyu_prohibit-turn")
      if type(marks) == "table" then
        targets = table.filter(targets, function (pid)
          return not table.contains(marks, pid)
        end)
      else
        marks = {}
      end
      if #targets == 0 then return false end
      local card = Fk:getCardById(player:getMark("shangyu_slash"))
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#shangyu-give:::" .. card:toLogString(), self.name, false)
      if #to > 0 then
        table.insert(marks, to[1])
        room:setPlayerMark(player, "shangyu_prohibit-turn", marks)
        room:moveCardTo(card, Card.PlayerHand, room:getPlayerById(to[1]), fk.ReasonGive, self.name, nil, true, player.id)
      end
    elseif event == fk.Damage then
      local target = room:getPlayerById(self.cost_data)
      room:doIndicate(player.id, {self.cost_data})
      room:drawCards(player, 1, self.name)
      if not target.dead then
        room:drawCards(target, 1, self.name)
      end
    elseif event == fk.GameStart then
      local cards = room:getCardsFromPileByRule("slash", 1)
      if #cards > 0 then
        local cid = cards[1]
        room:setPlayerMark(player, "shangyu_slash", cid)
        local card = Fk:getCardById(cid)
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
        if player.dead or not table.contains(player:getCardIds(Player.Hand), cid) then return false end
        local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
        "#shangyu-give:::" .. card:toLogString(), self.name, true)
        if #to > 0 then
          room:moveCardTo(card, Card.PlayerHand, room:getPlayerById(to[1]), fk.ReasonGive, self.name, nil, true, player.id)
        end
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return not player.dead and player:getMark("shangyu_slash") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cid = player:getMark("shangyu_slash")
    local card = Fk:getCardById(cid)
    if room:getCardArea(cid) == Card.PlayerHand and card:getMark("@@shangyu-inhand") == 0 then
      room:setCardMark(Fk:getCardById(cid), "@@shangyu-inhand", 1)
    end
  end,
}

local caixia = fk.CreateTriggerSkill{
  name = "caixia",
  events = {fk.Damage, fk.Damaged, fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardUsing then
      return player == target and player:getMark("@caixia") > 0
    else
      return player == target and player:getMark("@caixia") == 0 
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return true
    else
      local room = player.room
      local choices = {}
      for i = 1, math.min(5, #room.players), 1 do
        table.insert(choices, "caixia_draw" .. tostring(i))
      end
      table.insert(choices, "Cancel")
      local choice = room:askForChoice(player, choices, self.name, "#caixia-draw")
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:notifySkillInvoked(player, self.name)
      room:removePlayerMark(player, "@caixia")
    else
      room:notifySkillInvoked(player, self.name, event == fk.Damaged and "masochism" or "drawcard")
      player:broadcastSkillInvoke(self.name)
      local x = tonumber(string.sub(self.cost_data, 12, 12))
      room:setPlayerMark(player, "@caixia", x)
      room:drawCards(player, x, self.name)
    end
  end
}
xujing:addSkill(shangyu)
xujing:addSkill(caixia)
Fk:loadTranslationTable{
  ["ty__xujing"] = "许靖",
  ["shangyu"] = "赏誉",
  [":shangyu"] = "锁定技，游戏开始时，你获得一张【杀】并标记之，然后可以将其交给一名角色。此【杀】：造成伤害后，你和使用者各摸一张牌；"..
  "进入弃牌堆后，你将其交给一名本回合未以此法指定过的角色。",
  ["caixia"] = "才瑕",
  [":caixia"] = "当你造成或受到伤害后，你可以摸至多X张牌（X为游戏人数且至多为5）。若如此做，此技能失效直到你累计使用了等量的牌。",

  ["@@shangyu-inhand"] = "赏誉",
  ["#shangyu-give"] = "赏誉：将“赏誉”牌【%arg】交给一名角色",
  ["#caixia-draw"] = "你可以发动 才瑕，选择摸牌的数量",
  ["caixia_draw1"] = "摸一张牌",
  ["caixia_draw2"] = "摸两张牌",
  ["caixia_draw3"] = "摸三张牌",
  ["caixia_draw4"] = "摸四张牌",
  ["caixia_draw5"] = "摸五张牌",
  ["@caixia"] = "才瑕",

  ["$shangyu1"] = "君满腹才学，当为国之大器。",
  ["$shangyu2"] = "一腔青云之志，正待梦日之时。",
  ["$caixia1"] = "吾习扫天下之术，不善净一屋之秽。",
  ["$caixia2"] = "玉有十色五光，微瑕难掩其瑜。",
  ["~ty__xujing"] = "时人如江鲫，所逐者功利尔……",
}

--武庙：诸葛亮、陆逊
local zhugeliang = General(extension, "wm__zhugeliang", "shu", 4, 7)
local jincui = fk.CreateTriggerSkill{
  name = "jincui",
  anim_type = "control",
  frequency = Skill.Compulsory,
  mute = true,
  events = {fk.EventPhaseStart, fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self) and player:getHandcardNum() < 7
    elseif event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self) and player.phase == Player.Start
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      local n = 7 - player:getHandcardNum()
      if n > 0 then
        player:drawCards(n, self.name)
      end
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name)
      player:broadcastSkillInvoke(self.name)
      local n = 0
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number == 7 then
          n = n + 1
        end
      end
      n = math.max(n, 1)
      if player.hp > n then
        room:loseHp(player, player.hp - n, self.name)
      elseif player.hp < n then
        room:recover({
          who = player,
          num = math.min(n - player.hp, player:getLostHp()),
          recoverBy = player,
          skillName = self.name
        })
      end
      room:askForGuanxing(player, room:getNCards(player.hp))
    end
  end,
}
local qingshi = fk.CreateTriggerSkill{
  name = "qingshi",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player:getMark("@@qingshi-turn") == 0 and
      table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end) and
      (player:getMark("@$qingshi-turn") == 0 or not table.contains(player:getMark("@$qingshi-turn"), data.card.trueName))
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"qingshi2", "qingshi3", "Cancel"}
    if data.card.is_damage_card and data.tos then
      table.insert(choices, 1, "qingshi1")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#qingshi-invoke:::"..data.card:toLogString())
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@$qingshi-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, data.card.trueName)
    room:setPlayerMark(player, "@$qingshi-turn", mark)
    if self.cost_data == "qingshi1" then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name)
      local to = room:askForChoosePlayers(player, TargetGroup:getRealTargets(data.tos), 1, 1,
        "#qingshi1-choose:::"..data.card:toLogString(), self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(TargetGroup:getRealTargets(data.tos))
      end
      data.extra_data = data.extra_data or {}
      data.extra_data.qingshi = to
    elseif self.cost_data == "qingshi2" then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name)
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 10, "#qingshi2-choose", self.name, false)
      if #tos == 0 then
        tos = table.random(targets, 1)
      end
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    elseif self.cost_data == "qingshi3" then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      player:drawCards(3, self.name)
      room:setPlayerMark(player, "@@qingshi-turn", 1)
    end
  end,

  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return use.extra_data and use.extra_data.qingshi and data.to.id == use.extra_data.qingshi
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local zhizhe = fk.CreateActiveSkill{
  name = "zhizhe",
  prompt = "#zhizhe-active",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and not Fk:getCardById(to_select).is_derived
  end,
  on_use = function(self, room, effect)
    local c = Fk:getCardById(effect.cards[1], true)
    local toGain = room:printCard(c.name, c.suit, c.number)
    room:moveCards({
      ids = {toGain.id},
      to = effect.from,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = effect.from,
      skillName = self.name,
      moveVisible = false,
    })
  end
}
local zhizhe_trigger = fk.CreateTriggerSkill{
  name = "#zhizhe_trigger",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("zhizhe")
    if type(mark) ~= "table" then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    if parent_event and (parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard) then
      local parent_data = parent_event.data[1]
      if parent_data.from == player.id then
        local card_ids = room:getSubcardsByRule(parent_data.card)
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if info.fromArea == Card.Processing and room:getCardArea(id) == Card.DiscardPile and
              table.contains(card_ids, id) and table.contains(mark, id) then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(zhizhe.name)
    local mark = player:getMark("zhizhe")
    local to_get = {}
    if type(mark) ~= "table" then return false end
    local move_event = room.logic:getCurrentEvent():findParent(GameEvent.MoveCards, true)
    local parent_event = move_event.parent
    if parent_event and (parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard) then
      local parent_data = parent_event.data[1]
      if parent_data.from == player.id then
        local card_ids = room:getSubcardsByRule(parent_data.card)
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if info.fromArea == Card.Processing and room:getCardArea(id) == Card.DiscardPile and
              table.contains(card_ids, id) and table.contains(mark, id) then
                table.insertIfNeed(to_get, id)
              end
            end
          end
        end
      end
    end
    if #to_get > 0 then
      room:moveCards({
        ids = to_get,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = zhizhe.name,
        moveVisible = false,
      })
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local marked = type(player:getMark("zhizhe")) == "table" and player:getMark("zhizhe") or {}
    local marked2 = type(player:getMark("zhizhe-turn")) == "table" and player:getMark("zhizhe-turn") or {}
    marked2 = table.filter(marked2, function (id)
      return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player
    end)
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == zhizhe.name then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            if info.fromArea == Card.Void then
              table.insertIfNeed(marked, id)
            else
              table.insert(marked2, id)
            end
            room:setCardMark(Fk:getCardById(id), "@@zhizhe-inhand", 1)
          end
        end
      elseif move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          table.removeOne(marked, id)
        end
      end
    end
    room:setPlayerMark(player, "zhizhe", marked)
    room:setPlayerMark(player, "zhizhe-turn", marked2)
  end,
}
local zhizhe_prohibit = fk.CreateProhibitSkill{
  name = "#zhizhe_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getMark("zhizhe-turn")
    if type(mark) ~= "table" then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("zhizhe-turn")
    if type(mark) ~= "table" then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
}
zhizhe:addRelatedSkill(zhizhe_trigger)
zhizhe:addRelatedSkill(zhizhe_prohibit)
zhugeliang:addSkill(jincui)
zhugeliang:addSkill(qingshi)
zhugeliang:addSkill(zhizhe)
Fk:loadTranslationTable{
  ["wm__zhugeliang"] = "武诸葛亮",
  ["jincui"] = "尽瘁",
  [":jincui"] = "锁定技，游戏开始时，你将手牌补至7张。准备阶段，你的体力值调整为与牌堆中点数为7的游戏牌数量相等（至少为1）。"..
  "然后你观看牌堆顶X张牌（X为你的体力值），将这些牌以任意顺序放回牌堆顶或牌堆底。",
  ["qingshi"] = "情势",
  [":qingshi"] = "当你于出牌阶段内使用一张牌时（每种牌名每回合限一次），若手牌中有同名牌，你可以选择一项：1.令此牌对其中一个目标造成的伤害值+1："..
  "2.令任意名其他角色各摸一张牌；3.摸三张牌，然后此技能本回合失效。",
  ["zhizhe"] = "智哲",
  [":zhizhe"] = "限定技，出牌阶段，你可以复制一张手牌（衍生牌除外）。此牌因你使用或打出而进入弃牌堆后，你获得且本回合不能再使用或打出之。",
  ["@$qingshi-turn"] = "情势",
  ["@@qingshi-turn"] = "情势失效",
  ["#qingshi-invoke"] = "情势：请选择一项（当前使用牌为%arg）",
  ["qingshi1"] = "令此牌对其中一个目标伤害+1",
  ["qingshi2"] = "令任意名其他角色各摸一张牌",
  ["qingshi3"] = "摸三张牌，然后此技能本回合失效",
  ["#qingshi1-choose"] = "情势：令%arg对其中一名目标造成伤害+1",
  ["#qingshi2-choose"] = "情势：令任意名其他角色各摸一张牌",
  ["#zhizhe_trigger"] = "智哲",
  ["#zhizhe-active"] = "发动 智哲，选择一张手牌（衍生牌除外），获得一张此牌的复制",
  ["@@zhizhe-inhand"] = "智哲",

  ["$jincui1"] = "情记三顾之恩，亮必继之以死。",
  ["$jincui2"] = "身负六尺之孤，臣当鞠躬尽瘁。",
  ["$qingshi1"] = "兵者，行霸道之势，彰王道之实。",
  ["$qingshi2"] = "将为军魂，可因势而袭，其有战无类。",
  ["$zhizhe1"] = "轻舟载浊酒，此去，我欲借箭十万。",
  ["$zhizhe2"] = "主公有多大胆略，亮便有多少谋略。",
  ["~wm__zhugeliang"] = "天下事，了犹未了，终以不了了之……",
}

local luxun = General(extension, "wm__luxun", "wu", 3)
local xiongmu = fk.CreateTriggerSkill{
  name = "xiongmu",
  mute = true,
  events = {fk.RoundStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.RoundStart then
        return true
      else
        return player == target and player:getHandcardNum() <= player.hp and player:getMark("xiongmu_defensive-turn") == 0 and
        #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local damage = e.data[5]
          return damage and damage.to == player
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "drawcard")
      local x = player.maxHp - player:getHandcardNum()
      if x > 0 and room:askForSkillInvoke(player, self.name, nil, "#xiongmu-draw:::" .. tostring(x)) then
        room:drawCards(player, x, self.name)
        if player.dead then return false end
      end
      if player:isNude() then return false end
      local cards = room:askForCard(player, 1, 998, true, self.name, true, ".", "#xiongmu-cards")
      x = #cards
      if x == 0 then return false end
      table.shuffle(cards)
      local positions = {}
      local y = #room.draw_pile
      for _ = 1, x, 1 do
        table.insert(positions, math.random(y+1))
      end
      table.sort(positions, function (a, b)
        return a > b
      end)
      local moveInfos = {}
      for i = 1, x, 1 do
        table.insert(moveInfos, {
          ids = {cards[i]},
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
          drawPilePosition = positions[i],
        })
      end
      room:moveCards(table.unpack(moveInfos))
      if player.dead then return false end
      cards = room:getCardsFromPileByRule(".|8", x)
      if x > #cards then
        table.insertTable(cards, room:getCardsFromPileByRule(".|8", x - #cards, "discardPile"))
      end
      if #cards > 0 then
        player.room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = "xiongmu_get",
        })
      end
    else
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "defensive")
      room:setPlayerMark(player, "xiongmu_defensive-turn", 1)
      data.damage = data.damage - 1
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.RoundEnd},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "xiongmu_get" then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
              room:setCardMark(Fk:getCardById(id), "@@xiongmu-inhand", 1)
            end
          end
        end
      end
    elseif event == fk.RoundEnd then
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        room:setCardMark(Fk:getCardById(id), "@@xiongmu-inhand", 0)
      end
    end
  end,
}
local xiongmu_maxcards = fk.CreateMaxCardsSkill{
  name = "#xiongmu_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@xiongmu-inhand") > 0
  end,
}
local zhangcai = fk.CreateTriggerSkill{
  name = "zhangcai",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player:getMark("@@ruxian") > 0 or data.card.number == 8)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.max(1, #table.filter(player:getCardIds(Player.Hand), function (id)
      return Fk:getCardById(id):compareNumberWith(data.card, false)
    end)), self.name)
  end,
}
local ruxian = fk.CreateActiveSkill{
  name = "ruxian",
  prompt = "#ruxian-active",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    room:setPlayerMark(room:getPlayerById(effect.from), "@@ruxian", 1)
  end,
}
local ruxian_refresh = fk.CreateTriggerSkill{
  name = "#ruxian_refresh",

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@ruxian") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ruxian", 0)
  end,
}
xiongmu:addRelatedSkill(xiongmu_maxcards)
ruxian:addRelatedSkill(ruxian_refresh)
luxun:addSkill(xiongmu)
luxun:addSkill(zhangcai)
luxun:addSkill(ruxian)
Fk:loadTranslationTable{
  ["wm__luxun"] = "武陆逊",
  ["xiongmu"] = "雄幕",
  [":xiongmu"] = "每轮开始时，你可以将手牌摸至体力上限，然后将任意张牌随机置入牌堆，从牌堆或弃牌堆中获得等量的点数为8的牌，"..
  "这些牌此轮内不计入你的手牌上限。当你每回合受到第一次伤害时，若你的手牌数小于等于体力值，此伤害-1。",
  ["zhangcai"] = "彰才",
  [":zhangcai"] = "当你使用或打出点数为8的牌时，你可摸X张牌（X为手牌中与使用的牌点数相同的牌的数量且至少为1）。",
  ["ruxian"] = "儒贤",
  [":ruxian"] = "限定技，出牌阶段，你可将〖彰才〗改为所有点数均可触发摸牌直到你的下回合开始。",

  ["#xiongmu-draw"] = "雄幕：是否将手牌补至体力上限（摸%arg张牌）",
  ["#xiongmu-cards"] = "雄幕：你可将任意张牌随机置入牌堆，然后获得等量张点数为8的牌",
  ["@@xiongmu-inhand"] = "雄幕",
  ["#ruxian-active"] = "发动 儒贤，令你发动〖彰才〗没有点数的限制直到你的下个回合开始",
  ["@@ruxian"] = "儒贤",

  ["$xiongmu1"] = "步步为营者，定无后顾之虞。",
  ["$xiongmu2"] = "明公彀中藏龙卧虎，放之海内皆可称贤。",
  ["$zhangcai1"] = "今提墨笔绘乾坤，湖海添色山永春。",
  ["$zhangcai2"] = "手提玉剑斥千军，昔日锦鲤化金龙。",
  ["$ruxian1"] = "儒道尚仁而有礼，贤者知命而独悟。",
  ["$ruxian2"] = "儒门有言，仁为己任，此生不负孔孟之礼。",
  ["~wm__luxun"] = "此生清白，不为浊泥所染……",
}

return extension
