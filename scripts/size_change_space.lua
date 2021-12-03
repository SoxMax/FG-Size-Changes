local function registerOptions()
    -- register option for toggling updates to token space on size change
    OptionsManager.registerOption2("RESIZETOKEN", false, "option_header_token", "option_label_RESIZETOKEN", "option_entry_cycler",
            { labels = "option_val_on", values="on", baselabel = "option_val_off", baseval="off", default="off"});
end


function onInit()
    registerOptions()


end
