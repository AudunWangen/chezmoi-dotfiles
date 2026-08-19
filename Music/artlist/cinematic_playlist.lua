obs = obslua

source_name = ""
folder_path = ""
playlist = {}
current_index = 0
current_source_name = ""

function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

function build_playlist()
    playlist = {}
    local dir = obs.os_opendir(folder_path)
    if dir then
        local entry = obs.os_readdir(dir)
        while entry do
            if not entry.directory and entry.d_name:match("%.mp3$") then
                table.insert(playlist, folder_path .. "/" .. entry.d_name)
            end
            entry = obs.os_readdir(dir)
        end
        obs.os_closedir(dir)
    end
    shuffle(playlist)
    current_index = 0
end

function play_next()
    current_index = current_index + 1
    if current_index > #playlist then
        build_playlist()
        current_index = 1
    end
    local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "local_file", playlist[current_index])
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end

function media_ended(cd)
    play_next()
end

function connect_signal()
    local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
        local sh = obs.obs_source_get_signal_handler(source)
        obs.signal_handler_connect(sh, "media_ended", media_ended)
        obs.obs_source_release(source)
    end
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "source_name", "Media Source name", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_path(props, "folder_path", "MP3 folder", obs.OBS_PATH_DIRECTORY, "*.mp3", nil)
    return props
end

function script_update(settings)
    source_name = obs.obs_data_get_string(settings, "source_name")
    folder_path = obs.obs_data_get_string(settings, "folder_path")
    build_playlist()
    connect_signal()
    if #playlist > 0 then
        play_next()
    end
end

function script_load(settings)
    math.randomseed(os.time())
end

function script_description()
    return "Shuffled MP3 playlist using a Media Source. Set the Media Source name and the folder containing your MP3s."
end
