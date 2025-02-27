--[[
	작성 : qwreey
	2021y 04m 06d
	7:07 (PM)

	MINA Discord bot
	https://github.com/qwreey75/MINA_DiscordBot/blob/faf29242b29302341d631513617810d9fe102587/bot.lua

	-- TODO: 지우기 명령,강퇴,채널잠금,밴 같은거 만들기
	-- TODO: 다 못찾으면 !., 같은 기호 지우고 찾기
	-- TODO: 그리고도 못찾으면 조사 다 지우고 찾기
]]

--#region : sys setup
-- Setup require system

-- setup os env / lua env
local jit = jit or require "jit";
local procEnv = process.env;
local osName = jit.os;
local osArch = jit.arch;
local binPath;
for _,v in pairs(args) do
	local matching = v:match("^binPath=(.*)");
	if matching then
		binPath = matching;
		break;
	end
end
if not binPath then
	binPath = ("./bin/%s_%s"):format(osName,osArch);
end
procEnv.PATH = procEnv.PATH .. ( -- add bin libs path
	(osName == "Windows" and (";"..binPath:gsub("/","\\"))) or (":"..binPath)
);
package.path = require"app.path"(package.path,binPath); -- set require path
if osName == "Linux" then -- os file searching
	local libpath = ("%s/%s"):format(process.cwd(),binPath:gsub("^%./",""));
	-- print(libpath)
	-- process.env.LD_LIBRARY_PATH = libpath
	-- process.env.PATH = process.env.PATH .. ":" .. libpath
	-- process.env.LD_LIBRARY_PATH = ("%s:%s"):format((process.env.LD_LIBRARY_PATH or ""),libpath);
	local ffi = require "ffi"
	local lastFFILOAD = ffi.load;
	ffi.load = function (file,...)
		local loaded, lib = pcall(lastFFILOAD,file,...);
		if loaded then return lib end

		loaded, lib = pcall(lastFFILOAD,("%s/lib%s.so"):format(libpath,file),...);
		if not loaded then error(lib) end

		return lib
	end;
	require("proctime")(libpath .. "/libptimelua.so",ffi); -- fix the lua's os clock on linux
end

-- require essential modules
local profiler = require"profiler"; _G.profiler = profiler;
local promise = require "promise"; _G.promise,_G.async,_G.await,_G.waitter = promise,promise.async,promise.await,promise.waitter; -- promise library
local require = require"app.require"(require); -- set global require function
local initProfiler = profiler.new"INIT"; _G.initProfiler = initProfiler;
-- Make app object
local args,options = (require "argsParser").decode(args,{
	["--logger_prefix"] = true;
});
_G.app = {
	name = "DiscordBot";
	fullname = "discord_mina_bot";
	version = "Unknown";
	args = args;
	options = options;
	changelog = require "app.changelog";
	disabledFeature = {};
};

--#endregion sys setup
initProfiler:start"MAIN";
initProfiler:start"Load global modules"; --#region --** Load modules **--
	local cat = require "cat"; _G.cat = cat;
	local randomModule = require "random";
	local utf8 = require "utf8"; _G.utf8 = utf8; -- unicode 8 library
	local uv = require "uv"; _G.uv = uv; -- load uv library
	local prettyPrint = require "pretty-print"; _G.prettyPrint = prettyPrint; -- print many typed object on terminal
	local readline = require "readline"; _G.readline = readline; -- reading terminal lines
	local json = require "json"; _G.json = json; -- json library
	local corohttp = require "coro-http"; _G.corohttp = corohttp; -- luvit's http library
	local timer = require "timer"; _G.timer = timer; -- luvit's timer library that include timeout, sleep, ...
	local thread = require "thread"; _G.thread = thread; -- luvit's thread library
	local fs = require "fs"; _G.fs = fs; -- luvit's fils system library
	local ffi = require "ffi"; _G.ffi = ffi; -- luajit's ffi library
	local utils = require "utils"; _G.utils = utils; -- luvit's utils library
	local spawn = require "coro-spawn"; _G.spawn = spawn; -- spawn process (child process wrapper)
	local split = require "coro-split"; _G.split = split; -- run splitted coroutines
	local sha1 = require "sha1"; _G.sha1 = sha1; -- sha1
	local logger = require "logger"; _G.logger = logger; -- log library
	local dumpTable = require "dumpTable"; _G.dumpTable = dumpTable; -- table dump library, this is auto injecting dump function on global 'table'
	local exitCodes = require "app.exitCodes"; _G.exitCodes = exitCodes; -- get exit codes
	local term = require "term"; -- setuping REPL terminal
	local strSplit = require "strSplit"; _G.strSplit = strSplit; -- string split library
	local urlCode = require "urlCode"; _G.urlCode = urlCode; -- url encoder/decoder library
	local myXml = require "myXml"; _G.myXml = myXml; -- myXml library
	local userLearn = require "commands.learning.learn"; -- user learning library
	local userData = require "class.userData"; _G.userData = userData; -- Userdata system
	local posixTime = require "posixTime"; _G.posixTime = posixTime; -- get posixTime library
	local mutex = require "mutex"; _G.mutex = mutex;
	local argsParser = require "argsParser"; _G.argsParser = argsParser;
	local IPC = require "IPC"; _G.IPC = IPC;
	local data = require "data"; _G.data = data; -- Data system
	local commandHandler = require "class.commandHandler"; _G.commandHandler = commandHandler; -- command decoding-caching-indexing system
	local serverData = require "class.serverData"; _G.serverData = serverData; -- Serverdata system
	local interactionData = require "class.interactionData"; _G.interactionData = interactionData; -- interactiondata system
	local commonSlashCommand = require "class.commonSlashCommand"; _G.commonSlashCommand = commonSlashCommand;
	local random = randomModule.random; _G.random = random; -- LUA random handler
	local makeId = randomModule.makeId; _G.makeId = makeId; -- making id with random library
	local makeSeed = randomModule.makeSeed; _G.makeSeed = makeSeed; -- making seed library, this is used on random llibrary
	local format = string.format;
	local traceback = debug.traceback;
	local insert = table.insert;
	local gsub = string.gsub;
	local lower = string.lower;
	local osTime = os.time; _G.osTime = osTime; -- time
	cat.upgradeString();
initProfiler:stop(); --#endregion --** Load modules **--
initProfiler:start"Load discordia"; --#region --** Discordia Module **--
	logger.info("-------------------------- [INIT ] --------------------------");
	logger.info("global modules was loaded");
	logger.infof("binPath setted to %s",binPath);
	local file;
	for _,v in ipairs(args) do
		local matched = v:match"env.flagfile=(.+)" or v:match"flag=(.+)";
		if matched then
			file = matched;
			break;
		end
	end
	--TODO: implement for flag file
	logger.info("load discordia ...");

	require("app.jsonErrorWrapper"); -- enable pcall wrapped json en-decoder

	local discordia = require "discordia"; _G.discordia = discordia; ---@type discordia -- 디스코드 lua 봇 모듈 불러오기
	local discordia_enchant = require "discordia_enchant"; _G.discordia_enchant = discordia_enchant;
	local userInteractWarpper = require("class.userInteractWarpper"); _G.userInteractWarpper = userInteractWarpper;

	local discordia_class = discordia.class; ---@type class -- 디스코드 클레스 가져오기
	local discordia_Logger = discordia_class.classes.Logger; ---@type Logger -- 로거부분 가져오기 (통합을 위해 수정)
	local enums = discordia.enums; _G.enums = enums; ---@type enums -- 디스코드 enums 가져오기
	local client = discordia.Client(require("class.clientSettings")); _G.client = client; ---@type Client -- 디스코드 클라이언트 만들기
	local Date = discordia.Date; _G.Date = Date; ---@type Date
	local commonButtons = require "class.commonButtons"; _G.buttons = commonButtons;

	-- inject logger
	function discordia_Logger:log(level, msg, ...)
		if self._level < level then return end ---@diagnostic disable-line
		msg = format(msg, ...);
		local logFn =
			(level == 3 and logger.debug) or
			(level == 2 and logger.info) or
			(level == 1 and logger.warn) or
			(level == 0 and logger.error) or logger.info;
		if level <= 1 then
			logFn(("%s\n%s"):format(msg,traceback()));
		else
			logFn(msg);
		end
		return msg;
	end

	---@diagnostic disable-next-line
	discordia_enchant.inject(client);
	---@diagnostic disable-next-line
	client:setIntents(3243773)
	client:enableIntents(enums.gatewayIntent.messageContent);
	-- client:setIntents(bit.bor(3243773,enums.gatewayIntent.messageContent))
initProfiler:stop(); --#endregion --** Discordia Module **--
initProfiler:start"Load bot environments"; --#region --** Load bot environments **--
	logger.info("---------------------- [LOAD SETTINGS] ----------------------");

	-- Load environments
	initProfiler:start"Load environments / datas";
		logger.info("load environments ...");
		require("app.global"); -- inject environment
		local adminCmd = require("class.adminCommands"); -- load admin commands
		local hook = require("class.hook");
		local registeLeaderstatus = require("class.registeLeaderstatus");
		local formatTraceback = _G.formatTraceback;
		local admins = _G.admins;
		local testingMode = ACCOUNTData.testing;
		-- startBot(ACCOUNTData.botToken,testingMode); -- init bot (init discordia)
	initProfiler:stop();

	-- Load commands
	initProfiler:start"Load commands";
		initProfiler:start"Require files";
			logger.info(" |- load commands from commands folder");
			local otherCommands = promise.waitter(); -- read commands from commands folder
			for dir in fs.scandirSync("commands") do
				dir = gsub(dir,"%.lua$","");
				logger.info(" |  |- load from : commands." .. dir);
				otherCommands:add(promise.new(require,"commands." .. dir));
			end
			otherCommands = otherCommands:await();
		initProfiler:stop();

		-- Load command indexer
		initProfiler:start"Indexing commands";
			local reacts,commands,noPrefix,commandsLen;
			reacts,commands,noPrefix,commandsLen = commandHandler.encodeCommands({
				-- 특수기능
				["유저등록"] = {
					alias = {"등록","약관동의","EULA동의","약관 동의","사용계약 동의"};
					reply = function (message,args,content,self)
						local this = content.loadUserData();
						local author = message.author;
						local id = author.id;
						local name = author.name;
						if this then
							return message:reply{
								content = zwsp;
								embed = {
									title = (":x: **%s** 님은 이미 등록되어 있어요!"):format(
										name:gsub("%*","\\*")
									);
									color = embedColors.error;
								};
							};
						end

						userData.saveData(id,{
							latestName = name;
							lastName = {name};
							lastCommand = {};
							love = 20;
						});

						return message:reply{
							content = zwsp;
							embed = {
								title = ":white_check_mark: 등록되었습니다!";
								description = ("> 안녕하세요 %s 님!\n이 봇을 사용해 주셔서 감사합니다!\n이제 이 기능들을 사용할 수 있습니다\n`미나 배워` `미나 호감도` . . .\n더 많은 기능을 탐색하려면 `미나 도움말` 을 참조하세요!")
								:format(name:gsub("%*","\\*"));
							};
						};
					end;
				};
				["등록정보"] = {
					alias = {"등록 도움말","등록도움말","약관","등록정보","EULA","사용계약"};
					-- reply = EULA;
					---@param message Message
					reply = function (message)
						message:reply{
							content = zwsp;
							embed = {
								color = embedColors.success;
								title = ":white_check_mark: DM 으로 전송되었습니다!";
							};
						};
						return message.author:getPrivateChannel():send(EULA);
					end;
				};
				["미나"] = {
					alias = {"미나야","미나!","미나...","미나야...","미나..","미나야..","미나.","미나야.","미나야!"};
					reply = prefixReply;
				};
				["반응"] = {
					alias = {"반응수","반응 수","반응 갯수"};
					reply = "새어보고 있어요...";
					func = function (replyMsg,message,args,Content)
						replyMsg:setContent(("미나가 아는 반응은 %d개 이에요!"):format(commandsLen));
					end;
				};
			},unpack(otherCommands));
			_G.reacts = reacts;
			_G.commands = commands;
			_G.noPrefix = noPrefix;
			logger.info(" |- command indexing end!");
		initProfiler:stop();

		local disabledFeature = app.disabledFeature;
		if next(disabledFeature) then
			logger.warn("Some feature was disabled when loading commands");
		end
		for index,reason in pairs(app.disabledFeature) do
			logger.warnf(" |- %s: %s",tostring(index),tostring(index));
		end
	initProfiler:stop();
initProfiler:stop(); --#endregion --** Load bot environments **--
initProfiler:start"Setup bot Logic"; --#region --** Main logic **--
	logger.info("----------------------- [SET UP BOT ] -----------------------");
	local findCommandFrom = commandHandler.findCommandFrom;
	local afterHook = hook.afterHook;
	local beforeHook = hook.beforeHook;

	-- making command reader
	---@param message Message
	local function processCommand(message)

		-- get base information from message object
		local isSlashCommand = rawget(message,"slashCommand");
		local channel = message.channel; ---@type GuildTextChannel
		if not channel then
			if isSlashCommand then
				message:reply("아직 스레드 혹은 포스트에서 미나 명령을 사용할 수 없습니다!");
			end return;
		end -- ignore thread

		local user = message.author; ---@type User
		local text = message.content; ---@type string
		local guild = message.guild; ---@type Guild
		local isDm = channel.type == enums.channelType.private; ---@diagnostic disable-line
		if (not channel) or (not text) then return; end

		-- check user that is bot; if it is bot, then return (ignore call)
		if user.bot then
			return;
		end

		-- if no permission to send message, ignore it
		if guild and (not guild.me:hasPermission(channel,'sendMessages')) then
			return;
		end

		-- run admin command if exist
		if admins[user.id] then
			local cmdText = text;
			if testingMode then
				cmdText = cmdText:sub(2,-1);
			end
			pcall(adminCmd,cmdText,message);
		end

		-- run before hook
		local hookContent;
		for _,thisHook in pairs(beforeHook) do
			hookContent = hookContent or {
				text = text;
				user = user;
				channel = channel;
				isDm = isDm;
				message = message;
			};
			local isPassed,result = pcall(thisHook.func,thisHook,hookContent);
			if isPassed and result then
				return;
			end
		end

		-- LOCAL VARIABLES
		-- Text : 들어온 텍스트 (lower cased)
		-- prefix : 접두사
		-- rawCommandText : 접두사 뺀 커맨드 전채
		-- splitCommandText : rawCommandText 를 \32 로 분해한 array
		-- rawCommandText : 커맨드 이름 (앞부분 다 자르고)
		-- CommandName : 커맨드 이름
		-- | 찾은 후 (for 루프 뒤)
		-- Command : 커맨드 개체 (찾은경우)

		-- 접두사 구문 분석하기
		local prefix;
		local TextLower = lower(text); -- make sure text is lower case
		for index,nprefix in ipairs(prefixs) do
			if prefixsWithoutSpace[index] == TextLower then -- 만약 접두사와 글자가 일치하는경우 반응 달기
				if not isSlashCommand then
					promise.spawn(channel.broadcastTyping,channel); ---@diagnostic disable-line
				end
				message:reply {
					content = prefixReply[random(1,#prefixReply)];
					reference = {message = message, mention = false};
				};
				return;
			end
			if TextLower:sub(1,#nprefix) == nprefix then -- 만약에 접두가사 일치하면
				prefix = nprefix;
				break;
			end
		end

		-- guild prefix
		local guildCommandMode;
		if guild then
			local guildData = serverData.loadData(guild.id);
			if guildData then
				local guildPrefix = guildData.guildPrefix;
				if guildPrefix then
					local lenGuildPrefix = #guildPrefix;
					if guildPrefix == text:sub(1,lenGuildPrefix) then
						guildCommandMode = true;
						prefix = guildPrefix;
					end
				end
			end
		end
		if (not prefix) and (not isDm) and (not isSlashCommand) then
			return;
		end
		prefix = prefix or "";

		-- for other type channel support
		if not isSlashCommand then
			---@diagnostic disable-next-line
			local broadcastTyping = channel.broadcastTyping;
			if broadcastTyping then
				broadcastTyping(channel);
			end
		end

		-- 커맨드 찾기
		-- 단어 분해 후 COMMAND DICT 에 색인시도
		-- 못찾으면 다시 넘겨서 뒷단어로 넘김
		-- 찾으면 넘겨서 COMMAND RUN 에 TRY 던짐
		local rawCommandText = text:sub(#prefix+1,-1); -- 접두사 뺀 글자
		local splited = strSplit(rawCommandText:lower(),"\32\n");
		local Command,CommandName,rawCommandName = findCommandFrom(guildCommandMode and commands or reacts,rawCommandText,splited);
		if not Command then
			-- is guild command mode
			if guildCommandMode then
				message:reply {
					content = ("커맨드 **'%s'** 는 존재하지 않습니다!"):format(rawCommandText:gsub("@everyone","everyone"):gsub("@here","here"):gsub("<@.+>",""));
					reference = {message = message, mention = false};
				};
				return;
			end

			-- find from none prefixed commands table
			Command,CommandName,rawCommandName = findCommandFrom(noPrefix,rawCommandText,splited);
			if not Command then
				-- Solve user learn commands
				local pass,userReact = pcall(findCommandFrom,userLearn.get,rawCommandText,splited);
				if pass and userReact then
					message:reply {
						content = userLearn.format(userReact);
						reference = {message = message, mention = false};
					};
					return;
				elseif not pass then
					logger.errorf("Error occurred on loading userLearn data! Error message was\n%s",tostring(userReact));
				end

				-- not found
				message:reply({
					content = unknownReply[random(1,#unknownReply)];
					reference = {message = message, mention = false};
				});
				fs.appendFile("log/unknownTexts/raw.txt","\n" .. text); -- save
				return;
			end
		else
			-- check dm
			local cmdDisableDm = Command.disableDm;
			if isDm and cmdDisableDm then
				message:reply({
					content = (type(cmdDisableDm) == "string") and cmdDisableDm or disableDm;
					reference = {message = message, mention = false};
				});
				return;
			end
		end

		-- 커맨드 찾음 (실행)
		local love = Command.love; -- 호감도
		love = tonumber((type(love) == "function") and love() or love);
		local loveText = (love ~= 0 and love) and ( -- love 가 0 이 아님을 확인
			(love > 0 and ("\n` ❤ + %d `"):format(love)) or -- 만약 love 가 + 면
			(love < 0 and ("\n` 💔 - %d `"):format(math.abs(love))) -- 만약 love 가 - 면
		) or "";
		local func = Command.func; -- 커맨드 함수 가져오기
		local replyText = Command.reply; -- 커맨드 리플(답변) 가져오기
		local rawArgs,args; -- 인수 (str,띄어쓰기 단위로 나눔 array)
		replyText = ( -- reply 하나 가져오기
			(type(replyText) == "table") -- 커맨드 답변이 여러개면 하나 뽑기
			and (replyText[random(1,#replyText)])
			or replyText
		);
		local sendToDm = Command.sendToDm;

		-- Make love prompt
		if love then
			local userId = user.id
			local thisUserDat = userData.loadData(userId);

			if thisUserDat then
				local username = user.name;
				thisUserDat.latestName = username;
				local lastNames = thisUserDat.lastName;
				if lastNames[#lastNames] ~= username then
					insert(lastNames,username);
				end
				local CommandID = Command.id;
				-- get last command used status
				local lastCommand = thisUserDat.lastCommand;
				if not lastCommand then
					lastCommand = {};
					thisUserDat.lastCommand = lastCommand;
				end
				local lastTime = lastCommand[CommandID];
				if lastTime and (lastTime+loveCooltime > osTime()) then -- need more sleep . . .
					loveText = "";
				else
					thisUserDat.love = thisUserDat.love + love;
					lastCommand[CommandID] = osTime();
					userData.saveData(user.id);
					registeLeaderstatus(userId,thisUserDat);
				end
			else
				loveText = eulaComment_love;
			end
		end

		-- 함수 실행을 위한 콘탠츠 만들기
		---@class commandContent
		local contents = {
			member = message.member; ---@type Member a guild member that called this command
			guild = guild; ---@type Guild a guild that where used this command
			user = user; ---@type User a user that called this command
			channel = channel; ---@type Channel|TextChannel|GuildChannel|PrivateChannel|GuildTextChannel a channel that this command is called on
			isDm = isDm; ---@type boolean whether this channel is dm
			rawCommandText = rawCommandText; ---@type string raw command text (removed prefix)
			prefix = prefix; ---@type string used prefix
			rawArgs = rawArgs; ---@type string raw string arguments
			rawCommandName = rawCommandName; ---@type string command name, this is can be alias
			self = Command; ---@type Command this command it self
			commandName = CommandName; ---@type string this command is self's name
			---@type function Save this user's data with userData library
			---@return nil
			saveUserData = function ()
				return userData.saveData(user.id);
			end;
			---@type function Save this user's data with userData library
			---@return userDataObject userDataObject User's Data
			loadUserData = function ()
				return userData.loadData(user.id);
			end;
			loveText = loveText; ---@type string love earned text
			---@type function Get user's premium status
			---@return boolean isPremium whether user's premium exist
			isPremium = function ()
				local uData = userData.loadData(user.id);
				if not uData then
					return;
				end
				local premiumStatus = uData.premiumStatus;
				if premiumStatus and (premiumStatus > posixTime.now()) then
					return true;
				end
				return false;
			end;
			---@type boolean determine is slash command callback
			isSlashCommand = isSlashCommand;
			---@type function Get server's settings
			---@return table|nil serverData
			loadServerData = function ()
				return serverData.loadData(guild.id)
			end;
			saveServerData = function (overwrite)
				return serverData.saveData(guild.id,overwrite);
			end;
		};

		-- if reply text is function, run it and get result
		if type(replyText) == "function" then
			rawArgs = rawCommandText:sub(#rawCommandName+2,-1);
			args = strSplit(rawArgs,"\32");
			contents.rawArgs = rawArgs;
			local passed;
			passed,replyText = xpcall(replyText,function (err)
				err = tostring(err);
				local traceback = formatTraceback(debug.traceback());
				text = tostring(text);
				logger.errorf("An error occurred on running command function\n - original message : %s\n - error message was :\n%s\n - error traceback was :\n%s\n - more information was saved on log/debug.log",
					tostring(text),err,traceback
				);
				coroutine.wrap(message.reply)(message,{ ---@diagnostic disable-line
					content = ("커맨드 반응 생성중 오류가 발생했습니다!```log\nError message : %s\n%s```"):format(
						tostring(err),tostring(traceback)
					);
					reference = {message = message, mention = false};
				})
			end,message,args,contents,Command);
			if not passed then
				return;
			end
		end

		-- Making reply message
		local replyMsg;
		if replyText then -- if there are reply text
			local replyTextType = type(replyText);
			local embed = Command.embed;
			local components = Command.components;
			if replyTextType == "string" then -- if is string, making new message
				local messageContent = {
					components = components;
					embed = embed;
					content = commandHandler.formatReply(replyText .. loveText,{
						Msg = message;
						user = user;
						channel = channel;
					});
					reference = {message = message, mention = false};
				};

				if sendToDm then
					if type(sendToDm) == "boolean" then
						sendToDm = {content = zwsp; embed = { title = "개인 메시지로 전송되었습니다!" }};
					end
					messageContent.reference = nil;
					message:reply(sendToDm);
					message.author:getPrivateChannel():send(messageContent);
				else
					replyMsg = message:reply(messageContent);
				end
			elseif replyTextType == "table" then -- if is message (if func returned), set replyMsg to it
				replyMsg = replyText;
			end
		end

		-- 명령어에 담긴 함수를 실행합니다
		-- func (replyMsg,message,args,EXTENDTable);
		if func then -- 만약 커맨드 함수가 있으면
			-- 커맨드 함수 실행
			rawArgs = rawArgs or rawCommandText:sub(#CommandName+2,-1);
			contents.rawArgs = rawArgs;
			args = args or strSplit(rawArgs,"\32");
			xpcall(func,function (err)
				err = tostring(err);
				local traceback = formatTraceback(debug.traceback());
				text = tostring(text);
				logger.errorf("An error occurred on running command function\n - original message : %s\n - error message was :\n%s\n - error traceback was :\n%s\n - more information was saved on log/debug.log",
					tostring(text),err,traceback
				);
				---@diagnostic disable
				coroutine.wrap(replyMsg.setContent)(replyMsg,
					("명령어 처리중에 오류가 발생하였습니다```log\nError message : %s\n%s```"):format(err,traceback)
				);
				---@diagnostic enable
			end,replyMsg,message,args,contents,Command);
		end

		-- run after hook
		for _,thisHook in pairs(afterHook) do
			hookContent = hookContent or {
				text = text;
				user = user;
				channel = channel;
				isDm = isDm;
				message = message;
			};
			pcall(thisHook.func,thisHook,hookContent,contents);
		end
	end
	_G.processCommand = processCommand;

	-- on message
	client:on('messageCreate', processCommand);

	-- making slash command
	commandHandler.onSlash(function ()
		commandHandler.slashInited = true;
		client:slashCommand({ ---@diagnostic disable-line
			name = "미나";
			description = "미나와 대화합니다!";
			options = {
				{
					name = "내용";
					description = "미나와 나눌 대화를 입력해보세요!";
					type = discordia_enchant.enums.optionType.string;
					required = true;
				};
			};
			callback = function(interaction, params, cmd)
				local pass,err = xpcall(processCommand,
					function (err)
						err = tostring(err)
						local traceback = debug.traceback();
						logger.errorf(
							"Error occurred on executing slash command\nError message : %s\nError traceback",
							err,traceback
						);
						interaction:reply(
							("애플리케이션 명령어 실행중 오류가 발생했습니다!\n```%s\n%s```"):format(
								err,traceback
							)
						);
					end,
					userInteractWarpper(
						params["내용"],
						interaction
					)
				);
			end;
		});
	end,nil,nil,"MAIN");

	client:on("slashCommandsCommited",function ()
		logger.info("[Slash] All slash command loaded");
		-- execute scripts
		for _,str in ipairs(args) do
			local match = str:match("^execute=(.*)");
			if match then
				logger.infof("Require user script '%s'",match);
				local passed,err = pcall(require,match);
				if not passed then
					logger.errorf("Error occurred while loading user script '%s'\n%s",match,tostring(err));
				end
			end
		end
	end);

	startBot(ACCOUNTData.botToken,testingMode); -- init bot (init discordia)
	-- enable terminal features and live reload system
initProfiler:stop(); --#endregion --** Main logic **--
initProfiler:start"Init Terminal / Dev features"; --#region --** Init Terminal / Dev features **--
	do
		local terminalInputDisabled;
		local livereload = false;
		for _,v in pairs(app.args) do
			if v == "disable_terminal" or v == "env.disable_terminal" then
				terminalInputDisabled = true;
			elseif v == "livereload" or v == "env.livereload" or v == "reload" then
				livereload = true;
			end
			if terminalInputDisabled and livereload then
				break;
			end
		end
		if not terminalInputDisabled then
			term(); -- Load repl terminal system
		end
		_G.livereloadEnabled = livereload; -- enable live reload
	end
	require("app.livereload")(testingMode); -- loads livereload system; it will make uv event and take file changed signal
	require("app.version"); -- load version system
initProfiler:stop(); --#endregion --** Init Terminal / Dev features **--
initProfiler:stop(); -- stop main
