local interactMessageWarpper = require("class.interactMessageWarpper");
local interactionData = _G.interactionData;
local discordia_enchant = _G.discordia_enchant;
local components = discordia_enchant.components;
local enums = discordia_enchant.enums;
local client = _G.client;

local insert = table.insert;
local remove = table.remove;
local function makeId(id)
	return "vote_" .. tostring(id);
end
local header = "따끈 따끈한 투표!";

local function makeVoteText(data,items)
	items = items or data.items;
	local title = data.title;
	local str = ("**%s**\n"):format(title or header);
	local selected = data.selected or {};
	local allUserCount = 0;
	for _,v in pairs(selected) do
		allUserCount = allUserCount + #v;
	end

	for i,v in ipairs(items) do
		str = str .. ("> %d. %s"):format(i,v);
		local this = selected[tostring(i)];
		local thisLen = this and #this;
		if thisLen and (thisLen ~= 0) then
			str = str
				.. (" [%d명 %d%%]\n"):format(thisLen,(thisLen/allUserCount)*100)
				.. ("> <@" .. table.concat(this,"> <@") .. ">\n");
		else
			str = str .. " [0명 0%]\n";
		end
	end

	return str .. "(아래에 버튼을 눌러 투표하세요)";
end

local function makeVoteButtons(items)
	local lenItems = #items;
	local buttons = {};
	local lastRow;
	for i = 1,lenItems do
		if i%5 == 1 then
			local row = components.actionRow.new({});
			lastRow = row.components;
			insert(buttons,row);
		end
		insert(lastRow,components.button.new {
			custom_id = ("action_vote_%d"):format(i);
			label = tostring(i);
			style = enums.buttonStyle.primary;
		});
	end

	return buttons;
end

local function makeVote(messageId,rawString,title)
	if title == "" then
		title = nil;
	elseif title then
		title = title:gsub("<[@&](%d)+>",function (str)
			return ("@%s"):format(tostring(str));
		end):gsub("@everyone","everyone"):gsub("@here","here");
	end

	local items = {};
	for str in rawString:gmatch("[^,]+") do
		local this = str:gsub("\n",""):gsub("*",""):gsub("_",""):gsub(">",""):gsub("`","")
			:gsub("<[@&](%d+)>",function (str)
				return ("@%s"):format(tostring(str));
			end):gsub("@everyone","everyone"):gsub("@here","here");
		insert(items,this);
	end

	local id = makeId(messageId);
	local data = {
		items = items;
		title = title;
	};
	interactionData:new(id,data);

	local lenItems = #items;
	if lenItems > 10 then
		return {content = "너무 많은 옵션이 있습니다!\n> 최대 아이템 갯수는 10개 입니다"};
	elseif lenItems < 2 then
		return {content = "옵션이 너무 적습니다!\n> 최소 아이템 갯수는 2개 입니다"};
	end

	return {
		content = makeVoteText(data,items);
		components = makeVoteButtons(items);
	};
end

local function updateVote(userId,selectionNumber,data)
	selectionNumber = tostring(selectionNumber);
	local selected = data.selected;
	if not selected then
		selected = {};
		data.selected = selected;
	end

	local removed;
	for selectedIndex,selectedList in pairs(selected) do
		for selectedUserIndex,selectedUserId in ipairs(selectedList) do
			if selectedUserId == userId then
				remove(selectedList,selectedUserIndex);
				removed = selectedIndex;
				break;
			end
		end
		if removed then
			break;
		end
	end

	if removed == selectionNumber then
		return;
	end
	local this = selected[selectionNumber];
	if not this then
		this = {};
		selected[selectionNumber] = this;
	end
	insert(this,userId);
end

---@param id string
---@param object interaction
local function buttonPressed(id,object)
	local voteSelection = tonumber(id:match("action_vote_(%d+)"));
	if not voteSelection then
		return;
	end

	local message = object.message;
	local parentInteraction = object.parentInteraction;
	if not message and parentInteraction then
		message = interactMessageWarpper.new(parentInteraction);
		message.replyed = true;
	end
	if message then
		local voteId = makeId(message.id);
		local data = interactionData.loadData(voteId);
		if not data then
			return;
		end

		updateVote(object.user.id,voteSelection,data);
		object:update({
			components = message.components;
			content = makeVoteText(data);
		});
		interactionData.saveData(voteId);
	end
end
client:onSync("buttonPressed",promise.async(buttonPressed));

---@type table<string, Command>
local export = {
	["투표"] = {
		alias = "선거";
		reply = "⏳ 잠시만 기다려주세요!";
		command = {"vote","v","투표"};
		func = function (replyMsg,message,args,Content)
			replyMsg:update(
				makeVote(replyMsg.id,Content.rawArgs)
			);
		end;
		onSlash = function ()
			client:slashCommand({ ---@diagnostic disable-line
				name = "투표";
				description = "투표를 만듭니다!";
				options = {
					{
						name = "내용";
						description = "투표 내용입니다! ',' 을 이용해 개별로 구분하세요!";
						type = discordia_enchant.enums.optionType.string;
						required = true;
					};
					{
						name = "제목";
						description = "투표의 제목을 설정합니다! (이 옵션은 비워둘 수 있습니다)";
						type = discordia_enchant.enums.optionType.string;
						required = false;
					};
				};
				callback = function(interaction, params, cmd)
					interaction:reply(
						makeVote(interaction.id,params["내용"],params["제목"])
					);
				end;
			});
		end;
	};
};
return export;
