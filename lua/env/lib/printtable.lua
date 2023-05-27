local function is_good_key(s)
    return string.match(s, "^[%a_][%w_]*$") ~= nil
end


local prettyprint_map = {
    string = function(v)
        return "\"" .. v .. "\""
    end,

    vector = function(v)
        return "vector(" .. tostring(v) .. ")"
    end,

    ["function"] = function(v)
        return "function ", " -- \"" .. debug.info(v, "n") .. "\" at " .. debug.info(v, "s") .. ":" .. debug.info(v, "l")
    end,
}

local cache
local function _printtable(t, i, printcustom)
    if cache[t] then return end
    cache[t] = true
    local prefix = string.rep("\t", i)
    for k, v in pairs(t) do
        if type(k) ~= "string" then
            k = "[" .. tostring(k) .. "]"
        elseif not is_good_key(k) then
            k = "[\"" .. k .. "\"]"
        end
        
        local vtype = type(v)
        if vtype ~= "table" then
            local prettyprint = prettyprint_map[vtype]
            local extra = ""
            if prettyprint then
                v, extra = prettyprint(v)
            else
                v = tostring(v)
            end
            extra = extra == nil and "" or extra
            printcustom(prefix .. k .. " = ", v, ",", extra)
        elseif next(v) == nil then
            printcustom(prefix .. k .. " = {},")
        else
            printcustom(prefix .. k .. " = {")
            _printtable(v, i + 1, printcustom)
            printcustom(prefix .. "},")
        end
    end
end

local function printtable(t, printcustom)
    printcustom = printcustom or print

    if type(t) ~= "table" then
        printcustom(t)
        return
    end

    if next(t) == nil then
        printcustom("{}")
        return
    end

    cache = {}
    print("{")
    _printtable(t, 1, printcustom)
    print("}")
end

return printtable
