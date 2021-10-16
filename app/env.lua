-- google api key, discord token, game api key and more. this is should be protected
_G.ACCOUNTData = data.load("data/ACCOUNT.json");

-- EULA text
_G.EULA = data.loadRaw("data/EULA.txt");

-- Off keywords, used on 미나 음악 켜기 and more
_G.onKeywords = {
	["켜기"] = true;
	["켜"] = true;
	["켜줘"] = true;
	["켜봐"] = true;
	["켜라"] = true;
	["켜줘라"] = true;
	["켜봐라"] = true;
	["켜주세요"] = true;
	["온"] = true;
	["on"] = true;
	["ON"] = true;
	["On"] = true;
	["켜보세요"] = true;
	["켜라고요"] = true;
};

-- Off keywords, used on 미나 음악 끄기 and more
_G.offKeywords = {
	["끄기"] = true;
	["꺼"] = true;
	["꺼줘"] = true;
	["꺼봐"] = true;
	["꺼라"] = true;
	["꺼줘라"] = true;
	["꺼봐라"] = true;
	["꺼주세요"] = true;
	["오프"] = true;
	["off"] = true;
	["OFF"] = true;
	["Off"] = true;
	["꺼보세요"] = true;
	["꺼라고요"] = true;
};

-- giveing love cooltime
_G.loveCooltime = 3600;

-- this is used on displays disabled on dm message
_G.disableDm = "이 반응은 DM 에서 사용 할 수 없어요! 서버에서 이용해 주세요";

-- this is used on when user is not accept eula
_G.eulaComment_love = (
	"\n> 호감도 기능을 사용할 수 없어요!" ..
	"\n> 호감도 기능을 사용하려면 '미나야 약관 동의' 를 입력해주세요!" ..
	"\n> (약관의 세부정보를 보려면 '미나야 약관' 을 입력해주세요)"
);

-- the admins of this bot
_G.admins = { -- 관리 명령어 권한
	["367946917197381644"] = true; -- me
	["756035861250048031"] = true; -- my sub account
	["647101613047152640"] = true; -- 눈송이
	["755378215907885116"] = true; -- 삿갓
};

-- the bot prefixs
_G.prefixs = {
	[1] = "미나야";
	[2] = "미나";
	[3] = "미나야.";
	[4] = "미나!";
	[5] = "미나야!";
	[6] = "미나야...";
	[7] = "미나야..",
	[8] = "미나...";
	[9] = "미나는";
	[10] = "미나의";
	[11] = "mina";
	[12] = "hey mina";
};

-- this is used on display when user messaged only perfixs
_G.prefixReply = { -- 그냥 미나야 하면 답
	"미나는 여기 있어요!","부르셨나요?","넹?",
	"왜요 왜요 왜요?","심심해요?","네넹","미나에요",
	"Zzz... 아! 안졸았어요","네!"
};

-- this is used on when user messaged texts that bot didn't know
_G.unknownReply = { -- 반응 없을때 띄움
	"**(갸우뚱?)**","무슨 말이에요?","네?","으에?"--,"먕?",":thinking: 먀?"
};

-- bot managing functions
local function startBot(botToken) -- 봇 시작시키는 함수
	-- 토큰주고 시작
	logger.debug("starting bot ...");
	client:run(("Bot %s"):format(botToken));
	client:setGame("'미나야 도움말' 을 이용해 도움말을 얻거나 '미나야 <할말>' 을 이용해 미나와 대화하세요!");
	return;
end
local function reloadBot() -- 봇 종료 함수
	logger.info("try restarting ...");
	client:setGame("재시작중...");
end
_G.reloadBot = reloadBot;
_G.startBot = startBot;

-- js's timeout function that inspired by js's timeout function
local function timeout(time,func)
	timer.setTimeout(time,coroutine.wrap(func));
end
_G.timeout = timeout;

do -- normal love range
	local cache = {};
	_G.loveRang = function (min,max)
		local key = ("%dx%d"):format(min,max);
		local incache = cache[key];
		if incache then return incache; end
		local new = function ()
			return cRandom(min,max);
		end;
		cache[key] = new;
		return new;
	end;
	_G.defaultLove = loveRang(2,8);
	_G.rmLove = loveRang(-2,-8);
end
