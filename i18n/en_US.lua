return {
  -- tenyear_xinghuo.lua
  ["tenyear_xinghuo"] = "10th-Spark",
  ["ty"] = "10th",

  ["yanjun"] = "Yan Jun",
  ["#yanjun"] = "志存补益",
  ["illustrator:yanjun"] = "YanBai",
  ["guanchao"] = "Tide Watching",
  [":guanchao"] = "At the start of the Action Phase, you can choose one to " ..
    "fill the gap: a) Increase(++); b) Decrease(--). When you use a card, " ..
    "if the value of all cards you have used in this turn is in ____ order, you draw 1.",
  ["xunxian"] = "Invite the Talented",
  [":xunxian"] = "1x each turn, when your used/played card goes into the discard pile, you can" ..
    " give it to a hero whose hand cards > yours.",
  ["@@guanchao_ascending-turn"] = "Tide W. ++",
  ["@@guanchao_decending-turn"] = "Tide W. --",
  ["@guanchao_ascending-turn"] = "Tide W. ++",
  ["@guanchao_decending-turn"] = "Tide W. --",
  ["#xunxian-choose"] = "Invite the Talended: can give %arg to whom hand cards > yours",

  ["ty__lidian"] = "Li Dian",
  ["#ty__lidian"] = "深明大义",
  ["ty__wangxi"] = "Forget Grudges",
  [":ty__wangxi"] = "After you deal/suffer dmg to/by a other hero, for each unit, " ..
    "you can draw 2 then give him 1 card.",
  ["#ty__wangxi-invoke"] = "Do you want to use Forget Grudges to %dest",
  ["#ty__wangxi-give"] = "Forget Grudges: give 1 card to %dest",

  ["duji"] = "Du Ji",
  ["#duji"] = "卧镇京畿",
  ["illustrator:duji"] = "李秀森",
  ["andong"] = "Secure the East",
  [":andong"] = "When you are about to suffer DMG from another hero, you " ..
    "can make him choose: 1. Prevent this DMG, his <font color='red'>♥" ..
    "</font> cards are not counted into max cards in this turn;" ..
    "2. you watch his hand cards and get all of <font color='red'>♥</font>" ..
    " cards.",
  ["yingshi"] = "React",
  [":yingshi"] = "At start of Action Phase, if there is no ‘Reward’, you " ..
    "can place all your ♥ atop another hero (‘Reward’). After a hero " ..
    "deals dmg using Slash to a hero with a ‘Reward’, the source will " ..
    "choose and get a ‘Reward’. When a hero with ‘Reward’ dies, you get " ..
    "all ‘Rewards’.",
  ["#andong-invoke"] = "Secure the East: you can make %dest to choose",
  ["andong1"] = "Prevent DMG, <font color='red'>♥</font> cards not counted this turn",
  ["andong2"] = "He watches your hand cards and take <font color='red'>♥</font> cards",
  ["#andong-choice"] = "Secure the East: %src wants you to choose",
  ["duji_chou"] = "Reward",
  ["#yingshi-choose"] = "React: you can place all <font color='red'>♥</font> as Reward",
  ["#yingshi-get"] = "React: take 1 'Reward'",

  ["liuyan"] = "Liu Yan",
  ["#liuyan"] = "裂土之宗",
  ["cv:liuyan"] = "金垚",
	["illustrator:liuyan"] = "明暗交界", -- 传说皮 雄踞益州
  ["tushe"] = "Attempt to Secede",
  [":tushe"] = "After you target a hero using a non-equipment card, " ..
    "if you have no basic cards, you can draw X (X = # targets of this card).",
  ["limu"] = "Set Up the Local Governor",
  [":limu"] = "In Action Phase, you can use a ♦ card as Indulgence on " ..
    "yourself → heal 1. If you have cards in your judgment area, your " ..
    "cards are distance-less and unlimited when targeting heroes in range.",
  ["#limu"] = "Set Governor: use a ♦ card to yourself as Indulgence",

  ["panjun"] = "Pan Jun",
  ["#panjun"] = "方严疾恶",
  ["illustrator:panjun"] = "秋呆呆",
  ["guanwei"] = "Sightseeing",
  [":guanwei"] = "1x every hero’s turn, at the end of his Action Phase, " ..
    "if this turn he has used 2 or 2+ cards and all have the same suit, " ..
    "you can discard 1 → he draws 2 and has an extra Action Phase.",
  ["gongqing"] = "Quite Honorable",
  [":gongqing"] = "(forced) When you suffer dmg, if X < 3, u only suffer " ..
    "1 dmg; if X > 3, the dmg is +1. X = source’s range.",
  ["#guanwei-invoke"] = "Sightseeing: you can discard 1 and let %dest has extra Action Phase",

  ["ty__wangcan"] = "Wang Can",
  ["#ty__wangcan"] = "七子之冠冕",
  ["illustrator:ty__wangcan"] = "ZOO",
  ["sanwen"] = "Prose",
  [":sanwen"] = "1x each hero’s turn, when u get cards, if u’ve cards with " ..
    "the same name in your hand, you can show all of them, then discard " ..
    "the received cards shown and draw 2x # of discarded cards.",
  ["qiai"] = "Seven Sorrows",
  [":qiai"] = "(limited) When you enter the brink-of-death, you can make " ..
    "each other hero to give you a card.",
  ["denglou"] = "Record Story",
  [":denglou"] = "(limited) At End Phase, if u’ve no hand cards, u can " ..
    "show the top 4 cards, then get the non-basic cards and use the basic " ..
    "cards (discard if u can’t use).",
  ["#sanwen-invoke"] = "Prose: you can discard received cards (#=%arg), then draw 2x",
  ["#qiai-give"] = "Seven Sorrows: give 1 card to %dest",
  ["#denglou-use"] = "Record Story: you can use the basic cards",
  ["denglou_viewas"] = "Record Story",

  ["sp__pangtong"] = "Pang Tong",
  ["#sp__pangtong"] = "南州士冠",
  ["illustrator:sp__pangtong"] = "兴游",
  ["guolun"] = "Cross Opinions",
  [":guolun"] = "1x Action Phase, you can show 1 hand card from another " ..
    "hero, then you show 1 hand card -> exchange the 2 cards. The hero who " ..
    "shows lower number draws 1.",
  ["songsang"] = "Funeral",
  [":songsang"] = "(limited) When other hero dies, if you are wounded, " ..
    "you can heal 1 HP, otherwise gain 1 Max HP. Then, acquire 'Exhibit'.",
  ["zhanji"] = "Exhibit",
  [":zhanji"] = "(forced) When you draw any cards in Action Phase (except " ..
    "by this way), draw 1.",
  ["#guolun-card"] = "Cross Opinions: show 1 hand card (his number is %arg)",

  ["sp__taishici"] = "Taishi Ci",
  ["#sp__taishici"] = "北海酬恩",
  ["illustrator:sp__taishici"] = "王立雄",
  ["jixu"] = "Fake Strike",
  [":jixu"] = "1x Action Phase, you can ask any other heroes with the same " ..
    "HP to guess whether you have Slash in your hand. ▪ If you do have " ..
    "Slash: after you target using Slash during this phase, you make all " ..
    "heroes who chose 'No' also targets of this Slash; ▪ if you don’t " ..
    "have, you discard 1 card from each hero who chose 'Yes'.  You draw " ..
    "X (X = # heroes who guessed incorrectly). If X = 0, you end this phase.",
  ["#jixu-choice"] = "Fake Strike: guess whether %src has Slash in his hand",
  ["#jixu-quest"] = "%from guesses %arg",
  ["@@jixu-turn"] = "Fake Strike",

  ["zhoufang"] = "Zhou Fang",
  ["#zhoufang"] = "下发载义",
  ["illustrator:zhoufang"] = "黑白画谱",
  ["duanfa"] = "Haircut",
  [":duanfa"] = "出In Action Phase, u can discard any black cards, and " ..
    "then draw the same amount of cards (the total number of cards you " ..
    "discard in this way in each phase cannot be greater than your maxHP).",
  ["sp__youdi"] = "Lure the Enemy",
  [":sp__youdi"] = "At End Phase, you can make another hero discard you a " ..
    "hand card. If the discarded card is not Slash, you get one of his " ..
    "cards; if the discarded card is not black, you draw 1.",
  ["#sp__youdi-choose"] = "Lure the Enemy: you can let another hero " ..
    "discard you 1 hand card",

  ["lvdai"] = "Lv Dai",
  ["#lvdai"] = "清身奉公",
  ["illustrator:lvdai"] = "biou09",
  ["qinguo"] = "Diligent Country",
  [":qinguo"] = "After you use equipment during your turn, you can view " ..
    "as using Slash. After the # of cards in your equipment area changes, " ..
    "if # of your equipped cards = HP, you heal 1.",
  ["qinguo_viewas"] = "Diligent Country",
  ["#qinguo-ask"] = "Diligent Country: can view as using Slash",

  ["liuyao"] = "Liu Yao",
  ["#liuyao"] = "宗英外镇",
  ["illustrator:liuyao"] = "异酷",
  ["kannan"] = "Counter Insurgency",
  [":kannan"] = "(X-1) x Action Phase (X = your HP) you can Point Fight " ..
    "(1x hero x turn). If: ▪ you win, the next Slash you use will dmg +1 " ..
    "and u cannot activate this skill again this turn; ▪ he wins, his next " ..
    "Slash will dmg +1.",
  ["@kannan"] = "Counter Ins.",

  ["lvqian"] = "Lv Qian",
  ["#lvqian"] = "恩威并诸",
  ["illustrator:lvqian"] = "Town",
  ["weilu"] = "Take Prestige Prisionar of War",
  [":weilu"] = "(forced) When u suffer dmg by other heroes, at the start " ..
    "of your next Action Phase the source loses HP to 1 HP → he heals the " ..
    "HP lost this way at the end of your turn.",
  ["zengdao"] = "Give a Knife",
  [":zengdao"] = "(limited) in the Action Phase, u can place any # of " ..
    "cards in your equipment area atop other hero (“Knife”). When he deals " ..
    "dmg, remove 1 Knife → this dmg has +1.",
  ["@@weilu"] = "Prestige",
  ["#zengdao-invoke"] = "Give a Knife: remove 1 Knife, the DMG +1",

  ["zhangliang"] = "Zhang Liang",
  ["#zhangliang"] = "人公将军",
  ["illustrator:zhangliang"] = "Town",
  ["jijun"] = "Assemble Army",
  [":jijun"] = "After you use weapon or non-equipment that targets " ..
    "yourself in your Action Phase, you can be judged, place the result " ..
    "card atop your hero (‘Riot’).",
  ["zhangliang_fang"] = "Riot",
  ["fangtong"] = "Command All Regions",
  [":fangtong"] = "At End Phase, you can discard 1 card → discard at least " ..
    "1 Riots. If the sum of values of these cards = 36, deal 3 Thunder DMG " ..
    "to another hero.",
  ["#fangtong-invoke"] = "Command All Regions: you can discard 1 card",
  ["#fangtong-discard"] = "Command All Regions: remove at least 1 Riot",
  ["#fangtong-choose"] = "Command All Regions: deal 3 Thunder DMG now",
}
