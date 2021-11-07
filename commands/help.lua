local help = [[
~~도움말이 당신보다 강력해 도움말을 열람하실 수 없습니다~~
**이것 저것!** 다양한 기능의 미나봇에 오신걸 환영합니다

> 일반
일반적인 명령어들입니다!
자세한 사항은 `미나 도움말 일반` 을 입력하세요

> 오락
가지고 놀기 좋은 명령어들입니다!
자세한 사항은 `미나 도움말 오락` 을 입력하세요

> 가르치기
봇을 가르칠 수 있는 명령어입니다!
자세한 사항은 `미나 도움말 가르치기` 를 입력하세요

> 음악 [베타 기능]
음성 채팅방에서 노래를 틀 수 있습니다!
자세한 사항은 `미나 도움말 음악` 을 입력하세요]];

--[[
> 오락
자세한 사항은 `미나 도움말 오락` 을 입력하세요

> 트위치 검색 [검색할것]
유튜브에서 키워드를 검색합니다!
> 트위터 검색 [검색할것]
유튜브에서 키워드를 검색합니다!
> 구글 검색 [검색할것]
유튜브에서 키워드를 검색합니다!
> 네이버 검색 [검색할것]
유튜브에서 키워드를 검색합니다!
]]

local function buildHelpAlias(keyword)
    return {
        ("도움말%s"):format(keyword);
        ("%s도움말"):format(keyword);
        ("%s 도움말"):format(keyword);
        ("%s 사용법"):format(keyword);
        ("%s사용법"):format(keyword);
        ("사용법%s"):format(keyword);
        ("사용법 %s"):format(keyword);
        ("도움 %s"):format(keyword);
        ("도움%s"):format(keyword);
        ("%s 도움"):format(keyword);
        ("%s도움"):format(keyword);
    };
end

return {
    ["도움말"] = {
        alias = {"도움","사용법"};
        reply = help;
    };
    ["도움말 오락"] = {
        alias = buildHelpAlias("오락");
        reply = [[
봇을 가지고 놀 수 있는 명령어입니다!

> [한글/영문] 타자연습
타자연습을 시작합니다!

> 지뢰찾기 [베타]
지뢰찾기를 할 수 있어요, 아직 불안정합니다

> 주사위 던지기
주사위를 던져 수를 뽑아요

> 동전 뒤집기
동전을 뒤집어요

> 가위/바위/보
가위바위보를 할 수 있어요

**게임 스텟 기능**
> 에이펙스 스텟 [유저이름]
해당 유저의 에이펙스 스텟을 보여줍니다
]];
    };
    ["도움말 관리"] = {
        alias = buildHelpAlias("관리");
        reply = [[
서버 관리에 유용한 명령어입니다!

> 지워 [지울 메시지 수]
메시지 수 만큼 해당 채널의 최근 메시지를 지웁니다!

> 서버나이
현재 서버의 나이를 가져옵니다

> 계정나이
내 계정의 나이(생성한지 몇일째인지)를 가져옵니다

> 계정나이 [유저 맨션]
해당 유저의 계정 나이(생성한지 몇일째인지) 를 가져옵니다
유저 아이디로 쓸 수도 있습니다]];
    };
    ["도움말 일반"] = {
        alias = buildHelpAlias("일반");
        reply = [[
일반적인 명령어들입니다!

> 호감도
내 호감도를 봅니다

> 호감도 [유저 맨션]
해당 유저의 호감도를 봅니다, ID 를 입력해도 사용할 수 있습니다

> 뽑기 [뽑을것1],[뽑을것2],[뽑을것3] ...
아무거나 하나를 뽑을 수 있어요

> 코로나 현황
현재 코로나 현황을 가져옵니다

> [한국어/영어] 명언
명언을 가져옵니다

> 동물사진 [동물이름]
동물의 사진을 가져옵니다! 이용 가능한 동물 이름은 `동물사진` 을 입력하면 볼 수 있어요

> 사전 [검색할것]
네이버 사전 (어학사전 아닙니다) 에서 키워드를 검색합니다

> 유튜브 검색 [검색할것]
유튜브에서 키워드를 검색합니다

> ~~한강 물 온도~~
~~한강 물 온도를 가져옵니다~~

> 아스키 [영문/숫자]
영단어와 숫자로 쓴 단어를 아스키 아트로 그립니다

> 열차그리기 [영문/숫자]
영단어와 숫자로 쓴 단어를 아스키 아트 열차로 그립니다

> 핑
봇의 핑을 확인합니다

> 버전
봇의 버전을 가져옵니다

> 미나초대
미나 봇 초대 링크를 가져옵니다

> 시간
현재 시간을 보여줍니다

> 나이
미나가 얼마나 살았는지 보여줍니다

> ~~탱크~~
~~아스키 아트로 탱크를 그립니다~~

> 제작진
제작진을 보여줍니다

> 생일
미나가 등장한 날을 보여줍니다]];
    };
};