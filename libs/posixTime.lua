local time = os.time;
local diff = time() - time(os.date("!*t"));

return {gmt = diff,now = function ()
    return time() - diff;
end};
