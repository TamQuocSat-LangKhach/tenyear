
local caorui = General(extension, "ty_ex__caorui", "wei", 3)
local ty_ex__mingjian = fk.CreateActiveSkill{
  name = "ty_ex__mingjian",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#ty_ex__mingjian-active",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(player:getCardIds(Player.Hand), Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id)
    room:addPlayerMark(target, "@@" .. self.name, 1)
  end,
}

local ty_ex__mingjian_record = fk.CreateTriggerSkill{
  name = "#ty_ex__mingjian_record",

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@@ty_ex__mingjian") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("@@ty_ex__mingjian")
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, x)
    room:addPlayerMark(player, MarkEnum.SlashResidue .. "-turn", x)

    local turn_event = room.logic:getCurrentEvent()
    turn_event:addCleaner(function()
      room:removePlayerMark(player, "@@ty_ex__mingjian", x)
    end)
  end,
}

local ty_ex__huituo = fk.CreateTriggerSkill{
  name = "ty_ex__huituo",
  anim_type = "masochism",
  events = {fk.Damaged, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.Damaged then
      return target == player
    elseif event == fk.Damage then
      if target and target:getMark("@@ty_ex__mingjian") > 0 and target.phase ~= Player.NotActive then
        local room = player.room
        local damage_event = room.logic:getCurrentEvent()
        if not damage_event then return false end
        local x = target:getMark("ty_ex__huituo_record-turn")
        if x == 0 then
          room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
            local reason = e.data[3]
            if reason == "damage" then
              local first_damage_event = e:findParent(GameEvent.Damage)
              if first_damage_event and first_damage_event.data[1].from == target then
                x = first_damage_event.id
                room:setPlayerMark(target, "ty_ex__huituo_record-turn", x)
                return true
              end
            end
          end, Player.HistoryTurn)
        end
        return damage_event.id == x
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper),
      1, 1, "#ty_ex__huituo-choose:::" .. tostring(data.damage), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local judge = {
      who = to,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if to.dead then return false end
    if judge.card.color == Card.Red then
      if to:isWounded() then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    elseif judge.card.color == Card.Black then
      to:drawCards(data.damage, self.name)
    end
  end,
}

ty_ex__mingjian:addRelatedSkill(ty_ex__mingjian_record)
caorui:addSkill(ty_ex__huituo)
caorui:addSkill(ty_ex__mingjian)
caorui:addSkill("xingshuai")
Fk:loadTranslationTable{
  ["ty_ex__caorui"] = "界曹叡",
  ["#ty_ex__caorui"] = "天资的明君",
  ["illustrator:ty_ex__caorui"] = "君桓文化",

  ["ty_ex__huituo"] = "恢拓",
  [":ty_ex__huituo"] = "当你受到伤害后，你可以令一名角色判定，若结果为：红色，其回复1点体力；黑色，其摸X张牌（X为伤害值）。",
  ["ty_ex__mingjian"] = "明鉴",
  [":ty_ex__mingjian"] = "出牌阶段限一次，你可以将所有手牌交给一名其他角色，然后该角色下回合：使用【杀】的次数上限和手牌上限+1；"..
  "首次造成伤害后，你可以发动〖恢拓〗。",

  ["#ty_ex__huituo-choose"] = "你可以发动 恢拓，令一名角色判定，若为红色，其回复1点体力；黑色，其摸%arg张牌",

  ["#ty_ex__mingjian-active"] = "发动 明鉴，将所有手牌交给一名角色，令其下个回合获得增益",
  ["@@ty_ex__mingjian"] = "明鉴",

  ["$ty_ex__huituo1"] = "拓土复疆，扬大魏鸿威！",
  ["$ty_ex__huituo2"] = "制律弘法，固天下社稷！",
  ["$ty_ex__mingjian1"] = "敌将寇边，还请将军领兵御之。",
  ["$ty_ex__mingjian2"] = "逆贼滔乱，须得阁下出手相助。",
  ["$xingshuai_ty_ex__caorui1"] = "家国兴衰，与君共担！",
  ["$xingshuai_ty_ex__caorui2"] = "携君并进，共克此难！",
  ["~ty_ex__caorui"] = "胸有宏图待展，奈何命数已尽……",
}

local caoxiu = General(extension, "ty_ex__caoxiu", "wei", 4)
local ty_ex__qingxi = fk.CreateTriggerSkill{
  name = "ty_ex__qingxi",
  events = {fk.TargetSpecified},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.trueName == "duel")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if player:inMyAttackRange(p) then
        n = n + 1
      end
    end
    local max_num = #player:getEquipments(Card.SubtypeWeapon) > 0 and 4 or 2
    n = math.min(n, max_num)
    if player.room:askForSkillInvoke(player, self.name, data, "#ty_ex__qingxi::" .. data.to..":"..n) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local num = self.cost_data
    if #room:askForDiscard(to, num, num, false, self.name, true, ".", "#ty_ex__qingxi-discard:::"..num) == num then
      local weapon = player:getEquipments(Card.SubtypeWeapon)
      if #weapon > 0 then
        room:throwCard(weapon, self.name, player, to)
      end
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.ty_ex__qingxi = data.to
      local judge = {
        who = player,
        reason = self.name,
        pattern = ".|.|heart,diamond",
      }
      room:judge(judge)
      if judge.card.color == Card.Red then
        data.disresponsive = true
      end
    end
  end,
}
local ty_ex__qingxi_delay = fk.CreateTriggerSkill{
  name = "#ty_ex__qingxi_delay",
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data[1]
        if use.extra_data and use.extra_data.ty_ex__qingxi == data.to.id then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
ty_ex__qingxi:addRelatedSkill(ty_ex__qingxi_delay)
caoxiu:addSkill("qianju")
caoxiu:addSkill(ty_ex__qingxi)
Fk:loadTranslationTable{
  ["ty_ex__caoxiu"] = "界曹休",
  ["#ty_ex__caoxiu"] = "千里骐骥",
  ["cv:ty_ex__caoxiu"] = "清水浊流",
  ["illustrator:ty_ex__caoxiu"] = "写之火工作室",
  ["ty_ex__qingxi"] = "倾袭",
  [":ty_ex__qingxi"] = "当你使用【杀】或【决斗】指定一名角色为目标后，你可以令其选择一项：1.弃置等同于你攻击范围内的角色数张手牌（至多为2，若你武器区里有武器牌则改为至多为4），然后弃置你装备区里的武器牌；2.令此牌对其造成的基础伤害值+1且你进行一次判定，若结果为红色，该角色不能响应此牌。",
  ["#ty_ex__qingxi"] = "倾袭：可令 %dest 选一项：1.弃 %arg 张手牌并弃置你的武器；2.伤害+1且你判定，为红不能响应",
  ["#ty_ex__qingxi-discard"] = "倾袭：你需弃置 %arg 张手牌，否则伤害+1且其判定，结果为红你不能响应",

  ["$ty_ex__qingxi1"] = "虎豹骑倾巢而动，安有不胜之理？",
  ["$ty_ex__qingxi2"] = "任尔等固若金汤，虎豹骑可破之！",
  ["~ty_ex__caoxiu"] = "奈何痈发背薨！",
}

local ty_ex__zhongyao = General(extension, "ty_ex__zhongyao", "wei", 3)
local ty_ex__huomo = fk.CreateViewAsSkill{
  name = "ty_ex__huomo",
  pattern = ".|.|.|.|.|basic",
  prompt = function ()
    return "#ty_ex__huomo-card"
  end,
  interaction = function()
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, "ty_ex__huomo", all_names, {}, Self:getTableMark("ty_ex__huomo-turn"))
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = function (self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.type ~= Card.TypeBasic and card.color == Card.Black
  end,
  before_use = function (self, player, use)
    local room = player.room
    room:addTableMark(player, "ty_ex__huomo-turn", use.card.trueName)
    local put = use.card:getMark(self.name)
    if put ~= 0 and table.contains(player:getCardIds("he"), put) then
      room:moveCards({
        ids = {put},
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = self.name,
        proposer = player.id,
        moveVisible = true,
      })
    end
  end,
  view_as = function(self, cards)
    if not self.interaction.data or #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:setMark(self.name, cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isNude()
  end,
  enabled_at_response = function(self, player, response)
    return not response and not player:isNude()
  end,
}
ty_ex__zhongyao:addSkill(ty_ex__huomo)
ty_ex__zhongyao:addSkill("zuoding")
Fk:loadTranslationTable{
  ["ty_ex__zhongyao"] = "界钟繇",
  ["#ty_ex__zhongyao"] = "正楷萧曹",
  ["illustrator:ty_ex__zhongyao"] = "匠人绘",
  ["ty_ex__huomo"] = "活墨",
  [":ty_ex__huomo"] = "当你需要使用基本牌时（每种牌名每回合限一次），你可以将一张黑色非基本牌置于牌堆顶，视为使用此基本牌。",
  ["#ty_ex__huomo-card"] = "活墨：将一张黑色非基本牌置于牌堆顶",

  ["$ty_ex__huomo1"] = "笔墨抒胸臆，妙手成汗青。",
  ["$ty_ex__huomo2"] = "胸蕴大家之行，则下笔如有神助。",
  ["$zuoding_ty_ex__zhongyao1"] = "腹有大才，可助阁下成事。",
  ["$zuoding_ty_ex__zhongyao2"] = "胸有良策，可济将军之危。",
  ["~ty_ex__zhongyao"] = "人有寿终日，笔有墨尽时。",
}

local quancong = General(extension, "ty_ex__quancong", "wu", 4)
local ty_ex__yaoming = fk.CreateTriggerSkill{
  name = "ty_ex__yaoming",
  anim_type = "control",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player:getMark("ty_ex__yaoming_throw-turn") == 0
    or player:getMark("ty_ex__yaoming_draw-turn") == 0 or player:getMark("ty_ex__yaoming_recast-turn") == 0)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, dat = room:askForUseActiveSkill(player, "ty_ex__yaoming_active", "#ty_ex__yaoming-invoke", true)
    if dat then
      self.cost_data = {dat.interaction, dat.targets[1]}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data[1]
    room:setPlayerMark(player, choice.."-turn", 1)
    local to = room:getPlayerById(self.cost_data[2])
    if choice == "ty_ex__yaoming_throw" then
      local cid = room:askForCardChosen(player, to, "h", self.name)
      room:throwCard({cid}, self.name, to, player)
    elseif choice == "ty_ex__yaoming_draw" then
      to:drawCards(1, self.name)
    else
      local n = #room:askForDiscard(to, 0, 2, true, self.name, true, ".", "#ty_ex__yaoming-recast")
      if n > 0 and not to.dead then
        to:drawCards(n, self.name)
      end
    end
  end,
}
local ty_ex__yaoming_active = fk.CreateActiveSkill{
  name = "ty_ex__yaoming_active",
  card_num = 0,
  target_num = 1,
  interaction = function()
    local all_choices = {"ty_ex__yaoming_throw", "ty_ex__yaoming_draw", "ty_ex__yaoming_recast" }
    local choices = table.filter(all_choices, function (c)
      return Self:getMark(c.."-turn") == 0
    end)
    return UI.ComboBox {choices = choices, all_choices = all_choices }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected ~= 0 then return false end
    local to = Fk:currentRoom():getPlayerById(to_select)
    if self.interaction.data == "ty_ex__yaoming_throw" then
      return Self.id ~= to_select and not to:isKongcheng()
    elseif self.interaction.data == "ty_ex__yaoming_draw" then
      return Self.id ~= to_select
    else
      return not to:isNude()
    end
  end,
}
Fk:addSkill(ty_ex__yaoming_active)
quancong:addSkill(ty_ex__yaoming)
Fk:loadTranslationTable{
  ["ty_ex__quancong"] = "界全琮",
  ["#ty_ex__quancong"] = "慕势耀族",
  ["illustrator:ty_ex__quancong"] = "YanBai",
  ["ty_ex__yaoming"] = "邀名",
  [":ty_ex__yaoming"] = "每回合每项限一次，当你造成或受到伤害后，你可以选择一项：1.弃置一名其他角色的一张手牌；2.令一名其他角色摸一张牌；3.令一名角色弃置至多两张牌再摸等量的牌。",
  ["#ty_ex__yaoming-invoke"] = "邀名：你可以执行本回合未选择的一项",
  ["ty_ex__yaoming_throw"] = "弃置一名其他角色的一张手牌",
  ["ty_ex__yaoming_draw"] = "令一名其他角色摸一张牌",
  ["ty_ex__yaoming_recast"] = "令一名角色弃置至多两张牌再摸等量的牌",
  ["ty_ex__yaoming_active"] = "邀名",
  ["#ty_ex__yaoming-recast"] = "邀名：可以弃置至多两张牌再摸等量的牌",
  ["$ty_ex__yaoming1"] = "养威持重，不营小利。",
  ["$ty_ex__yaoming2"] = "则天而行，作功邀名。",
  ["~ty_ex__quancong"] = "邀名射利，内伤骨体，外乏筋肉。",
}

local sunxiu = General(extension, "ty_ex__sunxiu", "wu", 3)
local ty_ex__yanzhu = fk.CreateActiveSkill{
  name = "ty_ex__yanzhu",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if Self:getMark(self.name) > 0 then
      return #selected == 0 and to_select ~= Self.id
    else
      return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if player:getMark(self.name) > 0 then
      room:setPlayerMark(target, "@@yanzhudamage", 1)
      return
    end
    local choices = {"ty_ex__yanzhu_choice1"}
    if #target:getCardIds("e") > 0 then
      table.insert(choices, "ty_ex__yanzhu_choice2")
    end
    local choice = room:askForChoice(target, choices, self.name, "#ty_ex__yanzhu-choice:" .. player.id)
    if choice == "ty_ex__yanzhu_choice1" then
      room:setPlayerMark(target, "@@yanzhudamage", 1)
      room:askForDiscard(target, 1, 1, true, self.name, false)
    elseif choice == "ty_ex__yanzhu_choice2" then
      room:obtainCard(player.id, target:getCardIds(Player.Equip), true, fk.ReasonGive, target.id)
      room:setPlayerMark(player, self.name, 1)
    end
  end,
}
local ty_ex__yanzhu_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__yanzhu_trigger",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target:getMark("@@yanzhudamage") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
    local room = player.room
    room:setPlayerMark(target, "@@yanzhudamage",0)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target:getMark("@@yanzhudamage") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "@@yanzhudamage",0)
  end,
}
ty_ex__yanzhu:addRelatedSkill(ty_ex__yanzhu_trigger)
local ty_ex__xingxue = fk.CreateTriggerSkill{
  name = "ty_ex__xingxue",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local n = player.hp
    if player:getMark("ty_ex__yanzhu") > 0 then
      n = player.maxHp
    end
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, n,
      "#ty_ex__xingxue-choose:::"..n, self.name, true)
    if #tos > 0 then
      player.room:sortPlayersByAction(tos)
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local to = room:getPlayerById(id)
      if not to.dead then
        to:drawCards(1, self.name)
      end
    end
    for _, id in ipairs(self.cost_data) do
      local to = room:getPlayerById(id)
      if to:getHandcardNum() > to.hp then
        local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#ty_ex__xingxue-card")
        room:moveCards({
          ids = card,
          from = id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
        })
      end
    end
  end,
}
sunxiu:addSkill(ty_ex__yanzhu)
sunxiu:addSkill(ty_ex__xingxue)
sunxiu:addSkill("zhaofu")
Fk:loadTranslationTable{
  ["ty_ex__sunxiu"] = "界孙休",
  ["#ty_ex__sunxiu"] = "弥殇的景君",
  ["cv:ty_ex__sunxiu"] = "清水浊流",
  ["illustrator:ty_ex__sunxiu"] = "写之火工作室",

  ["ty_ex__yanzhu"] = "宴诛",
  ["#ty_ex__yanzhu_trigger"] = "宴诛",
  [":ty_ex__yanzhu"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.弃置一张牌，其下次受到伤害的+1直到其下个回合开始；2.交给你装备区内所有的牌，"..
  "你修改〖宴诛〗为 “出牌阶段限一次，你可以选择一名其他角色，令其下次受到的伤害+1直到其下个回合开始。”和修改〖兴学〗为“X为你的体力上限”。",
  ["ty_ex__xingxue"] = "兴学",
  [":ty_ex__xingxue"] = "结束阶段，你可以令X名角色依次摸一张牌，然后其中手牌数量大于体力值的角色依次将一张牌置于牌堆顶（X为你的体力值）。",
  ["@@yanzhudamage"] = "宴诛 受伤+1",
  ["#ty_ex__yanzhu-choice"] = "宴诛：选择%src弃置一张牌或令%src获得你装备区所有牌并修改“宴诛”和“兴学”",
  ["ty_ex__yanzhu_choice1"] = "弃置一张牌",
  ["ty_ex__yanzhu_choice2"] = "令其获得你装备区里所有牌并修改宴诛和兴学",
  ["#ty_ex__xingxue-choose"] = "兴学：你可以令至多%arg名角色依次摸一张牌，然后其中手牌数量大于体力值的角色依次将一张牌置于牌堆顶",
  ["#ty_ex__xingxue-card"] = "兴学：将一张牌置于牌堆顶",

  ["$ty_ex__yanzhu1"] = "觥筹交错，杀人于无形！",
  ["$ty_ex__yanzhu2"] = "子烈设宴，意在汝项上人头！",
  ["$ty_ex__xingxue1"] = "案古置学官，以敦王化，以隆风俗。",
  ["$ty_ex__xingxue2"] = "志善好学，未来可期！",
  ["~ty_ex__sunxiu"] = "盛世未成，实为憾事！",
}

local zhuzhi = General(extension, "ty_ex__zhuzhi", "wu", 4)
local function doty_ex__anguo(player, type, source)
  local room = player.room
  if type == "draw" then
    if table.every(room.alive_players, function (p) return p:getHandcardNum() >= player:getHandcardNum() end) then
      player:drawCards(1, "ty_ex__anguo")
      return true
    end
  elseif type == "recover" then
    if player:isWounded() and table.every(room.alive_players, function (p) return p.hp >= player.hp end) then
      room:recover({
        who = player,
        num = 1,
        recoverBy = source,
        skillName = "ty_ex__anguo",
      })
      return true
    end
  elseif type == "equip" then
    if #player:getCardIds("e") < 5 and table.every(room.alive_players, function(p)
      return #p:getCardIds("e") >= #player:getCardIds("e") end) then
      local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
      local cards = {}
      for i = 1, #room.draw_pile, 1 do
        local card = Fk:getCardById(room.draw_pile[i])
        for _, t in ipairs(types) do
          if card.sub_type == t and player:getEquipment(t) == nil then
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
        return true
      end
    end
  end
  return false
end
local ty_ex__anguo = fk.CreateActiveSkill{
  name = "ty_ex__anguo",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local types = {"equip", "recover", "draw"}
    for i = 3, 1, -1 do
      if target.dead then break end
      if doty_ex__anguo(target, types[i], player) then
        table.removeOne(types, types[i])
      end
    end
    for i = #types, 1, -1 do
      if player.dead then break end
      if doty_ex__anguo(player, types[i], player) then
        table.removeOne(types, types[i])
      end
    end
    if #types ==0 and not player.dead and not player:isNude() then
      local cards = room:askForCard(player, 1, 999, true, self.name, true, ".", "#ty_ex__anguo-card")
      if #cards > 0 then
        room:recastCard(cards, player, self.name)
      end
    end
  end,
}
zhuzhi:addSkill(ty_ex__anguo)
Fk:loadTranslationTable{
  ["ty_ex__zhuzhi"] = "界朱治",
  ["#ty_ex__zhuzhi"] = "王事靡盬",
  ["illustrator:ty_ex__zhuzhi"] = "福州明暗",
  ["ty_ex__anguo"] = "安国",
  [":ty_ex__anguo"] = "出牌阶段限一次，你可以选择一名其他角色，若其手牌数为全场最少，其摸一张牌；体力值为全场最低，回复1点体力；"..
  "装备区内牌数为全场最少，随机使用一张装备牌。然后若该角色有未执行的效果且你满足条件，你执行之。若双方执行了全部分支，你可以重铸任意张牌。",
  ["#ty_ex__anguo-card"] = "安国：你可以重铸任意张牌",

  ["$ty_ex__anguo1"] = "非武不可安邦，非兵不可定国。",
  ["$ty_ex__anguo2"] = "天下纷乱，正是吾等用武之时。",
  ["~ty_ex__zhuzhi"] = "刀在人在，刀折人亡……",
}

local ty_ex__liuchen = General(extension, "ty_ex__liuchen", "shu", 4)
local ty_ex__zhanjue = fk.CreateViewAsSkill{
  name = "ty_ex__zhanjue",
  anim_type = "offensive",
  card_num = 0,
  prompt = "#ty_ex__zhanjue",
  times = function(self)
    return Self.phase == Player.Play and 3 - Self:getMark("ty_ex__zhanjue-phase") or -1
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("duel")
    local cards = table.filter(Self:getCardIds("h"), function (id) return Fk:getCardById(id):getMark("@@ty_ex__qinwang-inhand-turn") == 0 end)
    card:addSubcards(cards)
    return card
  end,
  after_use = function(self, player, use)
    local room = player.room
    if not player.dead then
      player:drawCards(1, "ty_ex__zhanjue")
      room:addPlayerMark(player, "ty_ex__zhanjue-phase", 1)
    end
    if use.damageDealt then
      for _, p in ipairs(room.alive_players) do
        if use.damageDealt[p.id] then
          p:drawCards(1, "ty_ex__zhanjue")
          if p == player then
            room:addPlayerMark(player, "ty_ex__zhanjue-phase", 1)
          end
        end
      end
    end
  end,
  enabled_at_play = function(self, player)
    return player:getMark("ty_ex__zhanjue-phase") < 3 and table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@ty_ex__qinwang-inhand") == 0 end)
  end
}
ty_ex__liuchen:addSkill(ty_ex__zhanjue)
local ty_ex__qinwang = fk.CreateActiveSkill{
  name = "ty_ex__qinwang$",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local loyal = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then break end
      if not p.dead and p.kingdom == "shu" and not p:isKongcheng() then
        local cards = room:askForCard(p, 1, 1, false, self.name, true, "slash", "#ty_ex__qinwang-ask:"..player.id)
        if #cards > 0 then
          table.insert(loyal, p)
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, self.name, "", true, p.id, "@@ty_ex__qinwang-inhand-turn")
        end
      end
    end
    if not player.dead and #loyal > 0 and room:askForSkillInvoke(player, self.name, nil, "#ty_ex__qinwang-draw") then
      for _, p in ipairs(loyal) do
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    end
  end,
}
ty_ex__liuchen:addSkill(ty_ex__qinwang)
Fk:loadTranslationTable{
  ["ty_ex__liuchen"] = "界刘谌",
  ["#ty_ex__liuchen"] = "血荐轩辕",
  ["illustrator:ty_ex__liuchen"] = "青雨",
  ["ty_ex__zhanjue"] = "战绝",
  [":ty_ex__zhanjue"] = "出牌阶段，你可以将所有手牌（至少一张）当【决斗】使用，然后此【决斗】结算结束后，你和因此【决斗】受伤的角色各摸一张牌。"..
  "若你本阶段因此技能而摸过至少三张牌，本阶段你的〖战绝〗失效。",
  ["ty_ex__qinwang"] = "勤王",
  [":ty_ex__qinwang"] = "主公技，出牌阶段限一次，你可以令其他蜀势力角色依次选择是否交给你一张【杀】，然后你可以令所有交给你【杀】的角色摸一张牌"..
  "（以此法获得的【杀】于本回合不会被〖战绝〗使用）。",
  ["#ty_ex__zhanjue"] = "战绝：你可以将除因勤王获得的牌外的所有手牌当【决斗】使用，然后你和受伤的角色各摸一张牌",
  ["#ty_ex__qinwang-ask"] = "勤王：可以交给 %src 一张【杀】",
  ["#ty_ex__qinwang-draw"] = "勤王：你可以令所有交给你【杀】的角色摸一张牌",
  ["@@ty_ex__qinwang-inhand-turn"] = "勤王",

  ["$ty_ex__zhanjue1"] = "千里锦绣江山，岂能拱手相让！",
  ["$ty_ex__zhanjue2"] = "先帝一生心血，安可坐以待毙！",
  ["$ty_ex__qinwang1"] = "泰山倾崩，可有坚贞之臣？",
  ["$ty_ex__qinwang2"] = "大江潮来，怎无忠勇之士？",
  ["~ty_ex__liuchen"] = "儿欲死战，父亲何故先降……",
}

local ty_ex__zhangyi = General(extension, "ty_ex__zhangyi", "shu", 5)
local ty_ex__wurong = fk.CreateActiveSkill{
  name = "ty_ex__wurong",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local fromCard = room:askForCard(player, 1, 1, false, self.name, false, ".", "#ty_ex__wurong-show")[1]
    local toCard = room:askForCard(target, 1, 1, false, self.name, false, ".", "#ty_ex__wurong-show")[1]
    player:showCards(fromCard)
    target:showCards(toCard)
    if Fk:getCardById(fromCard).trueName == "slash" and Fk:getCardById(toCard).name ~= "jink" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
    if Fk:getCardById(fromCard).trueName ~= "slash" and Fk:getCardById(toCard).name == "jink" then
      if not target:isNude() then
        local id = room:askForCardChosen(player, target, "he", self.name)
        room:obtainCard(player, id, false)
      end
    end
  end,
}
ty_ex__zhangyi:addSkill(ty_ex__wurong)
local ty_ex__shizhi = fk.CreateFilterSkill{
  name = "ty_ex__shizhi",
  card_filter = function(self, to_select, player, isJudgeEvent)
    return player:hasSkill(self) and player.hp == 1 and to_select.name == "jink" and
    (table.contains(player.player_cards[Player.Hand], to_select.id) or isJudgeEvent)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
}
local ty_ex__shizhi_trigger = fk.CreateTriggerSkill{
  name = "#ty_ex__shizhi_trigger",
  events = {fk.Damage},
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    return player == target and player:hasSkill("ty_ex__shizhi") and data.card and player:isWounded()
    and table.contains(data.card.skillNames, "ty_ex__shizhi")
  end,
  on_use = function (self, event, target, player, data)
    player:broadcastSkillInvoke("ty_ex__shizhi")
    player.room:notifySkillInvoked(player, "ty_ex__shizhi", "defensive")
    player.room:recover { num = 1, skillName = "ty_ex__shizhi", who = player, recoverBy = player}
  end,

  refresh_events = {fk.HpChanged},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      Fk:filterCard(id, player)
    end
  end,
}
ty_ex__shizhi:addRelatedSkill(ty_ex__shizhi_trigger)
ty_ex__zhangyi:addSkill(ty_ex__shizhi)

Fk:loadTranslationTable{
  ["ty_ex__zhangyi"] = "界张嶷",
  ["#ty_ex__zhangyi"] = "通壮逾古",
  ["illustrator:ty_ex__zhangyi"] = "兴游",
  ["ty_ex__wurong"] = "怃戎",
  [":ty_ex__wurong"] = "出牌阶段限一次，你可以令一名其他角色与你同时展示一张手牌，若：你展示的是【杀】且该角色不是【闪】，你对其造成1点伤害；你展示的不是【杀】且该角色是【闪】，你获得其一张牌。",
  ["#ty_ex__wurong-show"] = "怃戎：选择一张展示的手牌",
  ["ty_ex__shizhi"] = "矢志",
  [":ty_ex__shizhi"] = "锁定技，当你的体力值为1时，你的【闪】视为【杀】；当你使用这些【杀】造成伤害后，你回复1点体力。",

  ["$ty_ex__wurong1"] = "策略以入算，果烈以立威！",
  ["$ty_ex__wurong2"] = "诈与和亲，不攻可得！",
  ["~ty_ex__zhangyi"] = "挥师未捷，杀身以报！",
}

local xiahoushi = General(extension, "ty_ex__xiahoushi", "shu", 3, 3, General.Female)
local ty_ex__qiaoshi = fk.CreateTriggerSkill{
  name = "ty_ex__qiaoshi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and
      player:getHandcardNum() == target:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty_ex__qiaoshi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(player:drawCards(1, self.name)[1])
    local card1 = Fk:getCardById(target:drawCards(1, self.name)[1])
    if card.color == card1.color then
      for i = 1, 99, 1 do
        if room:askForSkillInvoke(player, self.name, nil, "#ty_ex__qiaoshi-invoke::"..target.id) then
          card = Fk:getCardById(player:drawCards(1, self.name)[1])
          card1 = Fk:getCardById(target:drawCards(1, self.name)[1])
          if card.color ~= card1.color then
            
            return
          end
        else
          return
        end
      end
    end
  end,
}
local ty_ex__yanyu = fk.CreateActiveSkill{
  name = "ty_ex__yanyu",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  on_use = function(self, room, effect)
    room:recastCard(effect.cards, room:getPlayerById(effect.from), self.name)
  end,
}
local ty_ex__yanyu_record = fk.CreateTriggerSkill{
  name = "#ty_ex__yanyu_record",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == player.Play and player:usedSkillTimes("ty_ex__yanyu", Player.HistoryPhase) > 0 and
      not table.every(player.room:getOtherPlayers(player), function(p) return p.gender ~= General.Male end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
      return p:isMale() end), Util.IdMapper), 1, 1,
      "#ty_ex__yanyu-draw:::"..math.min(3, player:usedSkillTimes("ty_ex__yanyu", Player.HistoryPhase)), self.name, true)
    if #to > 0 then
      self.cost_data = room:getPlayerById(to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local num = math.min(3, player:usedSkillTimes("ty_ex__yanyu", Player.HistoryPhase))
    self.cost_data:drawCards(num, "ty_ex__yanyu")
  end,
}
ty_ex__yanyu:addRelatedSkill(ty_ex__yanyu_record)
xiahoushi:addSkill(ty_ex__qiaoshi)
xiahoushi:addSkill(ty_ex__yanyu)
Fk:loadTranslationTable{
  ["ty_ex__xiahoushi"] = "界夏侯氏",
  ["#ty_ex__xiahoushi"] = "采缘撷睦",
  ["illustrator:ty_ex__xiahoushi"] = "匠人绘",
  ["ty_ex__qiaoshi"] = "樵拾",
  [":ty_ex__qiaoshi"] = "其他角色的结束阶段，若其手牌数等于你，你可以与其各摸一张牌，若这两张牌颜色相同，你可以重复此流程。",
  ["ty_ex__yanyu"] = "燕语",
  [":ty_ex__yanyu"] = "①出牌阶段，你可以重铸【杀】；②出牌阶段结束时，若你于此阶段内发动过【燕语①】，则你可以令一名男性角色摸X张牌"..
  "（X为你本阶段发动过【燕语①】的次数且至多为3）。",
  ["#ty_ex__qiaoshi-invoke"] = "樵拾：你可以与 %dest 各摸一张牌",
  ["#ty_ex__yanyu_record"] = "燕语",
  ["#ty_ex__yanyu-draw"] = "燕语：你可以选择一名男性角色，令其摸%arg张牌",

  ["$ty_ex__qiaoshi1"] = "暖风细雨，心有灵犀。",
  ["$ty_ex__qiaoshi2"] = "樵采城郭外，忽见郎君来。",
  ["$ty_ex__yanyu1"] = "边功未成，还请郎君努力。",
  ["$ty_ex__yanyu2"] = "郎君有意倾心诉，妾身心中相思埋。",
  ["~ty_ex__xiahoushi"] = "天气渐寒，郎君如今安在？",
}

local guotupangji = General(extension, "ty_ex__guotupangji", "qun", 3)
local ty_ex__jigong = fk.CreateTriggerSkill{
  name = "ty_ex__jigong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
      for i = 1, 3, 1 do
        table.insert(choices, tostring(i))
      end
     local choice = room:askForChoice(player, choices, self.name, "#ty_ex__jigong-choice")
    player:drawCards(tonumber(choice), self.name)
    room:addPlayerMark(player, "@jigong_draw-turn",tonumber(choice))
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryPhase) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@ty_ex__jigong-turn", data.damage)
  end,
}
local ty_ex__jigong_maxcards = fk.CreateMaxCardsSkill{
  name = "#ty_ex__jigong_maxcards",
  fixed_func = function (self, player)
    if player:usedSkillTimes("ty_ex__jigong", Player.HistoryTurn) > 0 then
      return player:getMark("@ty_ex__jigong-turn")
    end
  end,
}
local ty_ex__jigong_recover = fk.CreateTriggerSkill{
  name = "#ty_ex__jigong_recover",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
      local num = player:getMark("@ty_ex__jigong-turn")
      local num1 = player:getMark("@jigong_draw-turn")
      if target == player and player:usedSkillTimes("ty_ex__jigong", Player.HistoryTurn) > 0 and player.phase == Player.Discard then
        return num >= num1 and player:isWounded()
      end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "ty_ex__jigong"
    })  
  end,
}
ty_ex__jigong:addRelatedSkill(ty_ex__jigong_maxcards)
ty_ex__jigong:addRelatedSkill(ty_ex__jigong_recover)
guotupangji:addSkill(ty_ex__jigong)
guotupangji:addSkill("shifei")
Fk:loadTranslationTable{
  ["ty_ex__guotupangji"] = "界郭图逄纪",
  ["#ty_ex__guotupangji"] = "凶蛇两端",
  ["illustrator:ty_ex__guotupangji"] = "磐蒲",
  ["ty_ex__jigong"] = "急攻",
  [":ty_ex__jigong"] = "出牌阶段开始时，你可以摸至多三张牌。若如此做，你本回合的手牌上限基数改为X，且弃牌阶段结束时，若X不小于Y，则你回复1点体力。"..
  "（X为你本回合内造成的伤害值之和，Y为你本回合内因〖急攻〗摸牌而获得的牌的数量总和）",
  ["@jigong_draw-turn"] = "急攻 摸牌数",
  ["@ty_ex__jigong-turn"] = "急攻 伤害数",
  ["#ty_ex__jigong-choice"] = "急攻:请选择你要摸的牌数量",

  ["$ty_ex__jigong1"] = "此时不战，更待何时！",
  ["$ty_ex__jigong2"] = "箭在弦上，不得不发！",
  ["$shifei_ty_ex__guotupangji1"] = "若依吾计而行，许昌旦夕可破！",
  ["$shifei_ty_ex__guotupangji2"] = "先锋怯战，非谋策之过。",
  ["~ty_ex__guotupangji"] = "主公，我还有一计啊！",
}

local gongsunyuan = General(extension, "ty_ex__gongsunyuan", "qun", 4)
local ty_ex__huaiyi = fk.CreateActiveSkill{
  name = "ty_ex__huaiyi",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 + player:getMark("huaiyi-phase") and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards = table.clone(player:getCardIds("h"))
    player:showCards(cards)
    local colors = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(colors, Fk:getCardById(id):getColorString())
    end
    if #colors < 2 then
      if player:getMark("huaiyi-phase") == 0 then
        room:setPlayerMark(player, "huaiyi-phase", 1)
      end
      player:drawCards(1, self.name)
    else
      local color = room:askForChoice(player, colors, self.name)
      local throw = {}
      for _, id in ipairs(cards) do
        if Fk:getCardById(id):getColorString() == color then
          table.insert(throw, id)
        end
      end
      room:throwCard(throw, self.name, player, player)
      local targets = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
        return (not p:isNude()) end), Util.IdMapper), 1, #throw, "#huaiyi-choose:::"..tostring(#throw), self.name, true)
      if #targets > 0 then
        local get = {}
        for _, p in ipairs(targets) do
          local id = room:askForCardChosen(player, room:getPlayerById(p), "he", self.name)
          table.insert(get, id)
        end
        for _, id in ipairs(get) do
          room:obtainCard(player, id, false, fk.ReasonPrey)
        end
        if #get > 1 and not player.dead then
          room:loseHp(player, 1, self.name)
        end
      end
    end
  end,
}
gongsunyuan:addSkill(ty_ex__huaiyi)
Fk:loadTranslationTable{
  ["ty_ex__gongsunyuan"] = "界公孙渊",
  ["#ty_ex__gongsunyuan"] = "狡徒悬海",
  ["illustrator:ty_ex__gongsunyuan"] = "君桓文化",
  ["ty_ex__huaiyi"] = "怀异",
  [":ty_ex__huaiyi"] = "出牌阶段限一次，你可以展示所有手牌。若仅有一种颜色，你摸一张牌，然后此技能本阶段改为“出牌阶段限两次”；"..
  "若有两种颜色，你弃置其中一种颜色的牌，然后获得至多X名角色各一张牌（X为弃置的手牌数），若你获得的牌大于一张，你失去1点体力。",

  ["$ty_ex__huaiyi1"] = "曹刘可王，孤亦可王！",
  ["$ty_ex__huaiyi2"] = "汉失其鹿，天下豪杰当共逐之。",
  ["~ty_ex__gongsunyuan"] = "大星落，君王死……",
}
