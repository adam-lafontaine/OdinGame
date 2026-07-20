#+private
package audio

import "core:strings"
import "core:slice"

import rl "vendor:raylib"


reset_music :: proc(music: ^Music)
{
    music.handle = 0
    music.is_on = false
    music.is_paused = false
}


reset_sound :: proc(sound: ^Sound)
{
    sound.handle = 0
    sound.is_on = false
}


MAX_MUSIC_TRACKS :: 2
MAX_SOUND_TRACKS :: 8


AudioList :: struct($T: typeid, $N: u32)
{
    items: [N + 1]T,
    active: [N + 1]b8,
    path: [N + 1]string,
}


init_audio_list :: proc(list: ^AudioList($T, $N))
{
    for i in 0..<len(list.items)
    {
        list.items[i] = {}
        list.active[i] = false
    }
}


close_audio_list :: proc(list: ^AudioList($T, $N), unload: $P)
{
    for i in 0..<len(list.items)
    {
        if list.active[i]
        {
            unload(list.items[i])            
            delete(list.path[i])
            list.active[i] = false
        }
    }
}


add_item :: proc(list: ^AudioList($T, $N), item: T, path: string) -> (i32, bool)
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


remove_item :: proc(list: ^AudioList($T, $N), id: i32)
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


get_item :: proc(list: ^AudioList($T, $N), id: i32) -> (T, bool)
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

    init_audio_list(&music_data)
    init_audio_list(&sound_data)

    return rl.IsAudioDeviceReady()
}


audio_close_audio :: proc()
{
    close_audio_list(&music_data, rl.UnloadMusicStream)
    close_audio_list(&sound_data, rl.UnloadSound)
    rl.CloseAudioDevice()
}


audio_load_music_from_file :: proc(music_file_path: string, music: ^Music) -> bool
{
    reset_music(music)

    path := strings.clone_to_cstring(music_file_path)
    data := rl.LoadMusicStream(path)
    if !rl.IsMusicValid(data)
    {
        return false
    }

    id, ok := add_item(&music_data, data, string(path))
    if ok
    {
        music.handle = id
    }

    return ok
}


audio_load_sound_from_file :: proc(music_file_path: string, sound: ^Sound) -> bool
{
    reset_sound(sound)

    path := strings.clone_to_cstring(music_file_path)
    data := rl.LoadSound(path)
    if !rl.IsSoundValid(data)
    {
        return false
    }

    id, ok := add_item(&sound_data, data, string(path))
    if ok
    {
        sound.handle = id
    }

    return ok
}


audio_load_music_from_bytes :: proc(bytes: ByteView, music: ^Music) -> bool
{
    reset_music(music)

    length := len(bytes.data)
    p := slice.bytes_from_ptr(bytes.data, length)

    data := rl.LoadMusicStreamFromMemory("ogg", p, length)
    if !rl.IsMusicValid(data)
    {
        return false
    }

    id, ok := add_item(&music_data, data, string(path))
    if ok
    {
        music.handle = id
    }

    return ok
}


audio_load_sound_from_bytes :: proc(bytes: ByteView, sound: ^Sound) -> bool
{
    reset_sound(sound)

    length := len(bytes.data)
    p := slice.bytes_from_ptr(bytes.data, length)

    wave := rl.LoadWaveFromMemory("ogg", p, length)
    defer rl.UnloadWave(wave)
    if !rl.IsWaveValid(wave)
    {
        return false
    }

    data := rl.LoadSoundFromWave(wave)
    if !rl.IsSoundValid(data)
    {
        return false
    }

    id, ok := add_item(&sound_data, data, string(path))
    if ok
    {
        sound.handle = id
    }

    return ok
}