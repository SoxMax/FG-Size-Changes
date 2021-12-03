sizes = {"fine", "diminutive", "tiny", "small", "medium", "large", "huge", "gargantuan", "colossal"}

function getActorSize(rSource)
    local type = DB.getValue(DB.findNode(rSource.sCTNode), "type", ""):lower()
    if type ~= "" then
        for index,size in ipairs(sizes) do
            if type:find(size, 1, true) then
                return index, size
            end
        end
    end
end
