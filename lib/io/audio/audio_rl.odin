#+private
package audio

import "core:strings"
import rl "vendor:raylib"


MAX_MUSIC_TRACKS :: 2
MAX_SOUND_TRACKS :: 8



AudioList :: struct($T: typeid, $N: u32)
{
    items: [N + 1]T,
    active: [N + 1]b8,
    path: [N + 1]string,
}


add_item :: proc(list: ^AudioList($T, $N) , item: T, path: string) -> (i32, bool)
{
    count := cast(int)N

    for id in 1..<count
    {
        if !list.active[id]
        {
            list.items[id] = item
            list.active[id] = true
            list.path[id] = path
            return cast(i32)id, true
        }
    }

    return 0, false    
}


remove_item :: proc(list: ^AudioList($T, $N) , id: i32)
{
    id_min := cast(i32)1
    id_max := cast(i32)N

    if id < id_min || id > id_max
    {
        return
    }

    list.active[id] = false
    list.items[id] = list.items[0]
    delete(list.path[id])
}


get_item :: proc(list: ^AudioList($T, $N) , id: i32) -> (T, bool)
{
    id_min := cast(i32)1
    id_max := cast(i32)N

    if id < id_min || id > id_max
    {
        return list.items[0], false
    }

    return list.items[id], true
}


music_data: AudioList(rl.Music, MAX_MUSIC_TRACKS)
sound_data: AudioList(rl.Sound, MAX_SOUND_TRACKS)



/* api */

audio_destroy_music :: proc(music: ^Music)
{
    data, ok := get_item(&music_data, music.handle)
    if !ok
    {
        return
    }

    rl.StopMusicStream(data)
    rl.UnloadMusicStream(data)

    remove_item(&music_data, music.handle)
    music.handle = 0
}


audio_destroy_sound :: proc(sound: ^Sound)
{
    data, ok := get_item(&sound_data, sound.handle)
    if !ok
    {
        return
    }

    rl.StopSound(data)
    rl.UnloadSound(data)

    remove_item(&sound_data, sound.handle)
    sound.handle = 0
}


audio_init_audio :: proc() -> bool
{
    rl.InitAudioDevice()

    for id in 0..<len(music_data.items)
    {
        music_data.items[id] = {}
        music_data.active[id] = false
    }

    for id in 0..<len(sound_data.items)
    {
        sound_data.items[id] = {}
        sound_data.active[id] = false
    }

    return rl.IsAudioDeviceReady()
}


audio_close_audio :: proc()
{
    rl.CloseAudioDevice()
}


audio_load_music_from_file :: proc(music_file_path: string, music: ^Music) -> bool
{
    path := strings.clone_to_cstring(music_file_path)

    data := rl.LoadMusicStream(path)

    ok := rl.IsMusicValid(data)

    if !ok
    {
        return false
    }

    add_item(&music_data, data, string(path))

    return ok
}