--[[

작성 : qwreey
2021y 04m 07d
6:00 (PM)

LUA 렌덤을 핸들링

]]

local pi3 = math.pi^13
return function (min,max)
    local rm = (collectgarbage("count")%1*pi3)^2 * 1000000;
    local ts = (os.clock()*pi3)^2;
    local seed = math.floor(ts*((((min/13)^2+(max/11)^2)*pi3)^2+rm));
    math.randomseed(seed);
    return math.random(min,max);
end;