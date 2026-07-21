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


MAX_MUSIC_TRACKS :: 8
MAX_SOUND_TRACKS :: 8

AUDIO_FILE_EXT :: ".ogg" // others?


AudioList :: struct($T: typeid, $H: typeid, $N: u32)
{
    id_nil: H,
    id_begin: H,
    id_end: H,

    count: int,

    items: [N + 1]T,
    active: [N + 1]b8,
}


init_audio_list :: proc(list: ^AudioList($T, $H, $N))
{
    list.count = cast(int)(N + 1)

    list.id_nil = cast(H)0
    list.id_begin = cast(H)1
    list.id_end = cast(H)(list.count)

    for i in 0..<list.count
    {
        list.items[i] = {}
        list.active[i] = false
    }
}


close_audio_list :: proc(list: ^AudioList($T, $H, $N), unload: $P)
{
    for i in 0..<list.count
    {
        if list.active[i]
        {
            unload(list.items[i])
            list.active[i] = false
        }
    }
}


add_item :: proc(list: ^AudioList($T, $H, $N), item: T) -> (H, bool)
{
    for id: H = list.id_begin; id < list.id_end; id += 1
    {
        if !list.active[id]
        {
            list.items[id] = item
            list.active[id] = true

            return id, true
        }
    }

    return list.id_nil, false    
}


remove_item :: proc(list: ^AudioList($T, $H, $N), id: H)
{
    if id < list.id_begin || id >= list.id_end
    {
        return
    }

    list.active[id] = false
    list.items[id] = list.items[list.id_nil]
}


get_item :: proc(list: ^AudioList($T, $H, $N), id: H) -> (T, bool)
{
    if id < list.id_begin || id >= list.id_end
    {
        return list.items[list.id_nil], false
    }

    return list.items[id], true
}


audio_sound_data: AudioList(rl.Sound, SoundID, MAX_SOUND_TRACKS)
audio_music_data: AudioList(rl.Music, MusicID, MAX_MUSIC_TRACKS)
audio_music_id: MusicID = 0


is_current_music :: proc(id: MusicID) -> bool
{
    return id != audio_music_data.id_nil && id == audio_music_id
}




/* api */

audio_destroy_music :: proc(music: ^Music)
{
    data, ok := get_item(&audio_music_data, music.handle)
    if !ok
    {
        return
    }

    rl.StopMusicStream(data)
    rl.UnloadMusicStream(data)

    remove_item(&audio_music_data, music.handle)
    music.handle = audio_music_data.id_nil
}


audio_destroy_sound :: proc(sound: ^Sound)
{
    data, ok := get_item(&audio_sound_data, sound.handle)
    if !ok
    {
        return
    }

    rl.StopSound(data)
    rl.UnloadSound(data)

    remove_item(&audio_sound_data, sound.handle)
    sound.handle = audio_sound_data.id_nil
}


audio_init_audio :: proc() -> bool
{
    rl.InitAudioDevice()

    init_audio_list(&audio_music_data)
    init_audio_list(&audio_sound_data)

    return rl.IsAudioDeviceReady()
}


audio_close_audio :: proc()
{
    close_audio_list(&audio_music_data, rl.UnloadMusicStream)
    close_audio_list(&audio_sound_data, rl.UnloadSound)
    rl.CloseAudioDevice()
}


audio_load_music_from_file :: proc(music_file_path: string, music: ^Music) -> bool
{
    reset_music(music)

    path := strings.clone_to_cstring(music_file_path)
    defer delete(path)

    data := rl.LoadMusicStream(path)
    if !rl.IsMusicValid(data)
    {
        return false
    }

    id, ok := add_item(&audio_music_data, data)
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
    defer delete(path)

    data := rl.LoadSound(path)
    if !rl.IsSoundValid(data)
    {
        return false
    }

    id, ok := add_item(&audio_sound_data, data)
    if ok
    {
        sound.handle = id
    }

    return ok
}


audio_load_music_from_bytes :: proc(bytes: ByteView, music: ^Music) -> bool
{
    reset_music(music)

    length := cast(i32)len(bytes.data)
    p := raw_data(bytes.data[:])

    data := rl.LoadMusicStreamFromMemory(AUDIO_FILE_EXT, p, length)
    if !rl.IsMusicValid(data)
    {
        return false
    }

    id, ok := add_item(&audio_music_data, data)
    if ok
    {
        music.handle = id
    }

    return ok
}


audio_load_sound_from_bytes :: proc(bytes: ByteView, sound: ^Sound) -> bool
{
    reset_sound(sound)

    length := cast(i32)len(bytes.data)
    p := raw_data(bytes.data[:])

    wave := rl.LoadWaveFromMemory(AUDIO_FILE_EXT, p, length)
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

    id, ok := add_item(&audio_sound_data, data)
    if ok
    {
        sound.handle = id
    }

    return ok
}


audio_play_music :: proc(music: ^Music)
{
    /*data, ok := get_item(&audio_music_data, music.handle)
    if !ok
    {
        return
    }

    rl.PlayMusicStream(data)*/
}


audio_toggle_pause_music :: proc()
{

}


audio_play_sound :: proc(sound: ^Sound)
{
    data, ok := get_item(&audio_sound_data, sound.handle)
    if !ok
    {
        return
    }

    rl.PlaySound(data)
}


audio_stop_sound :: proc(sound: ^Sound)
{
    data, ok := get_item(&audio_sound_data, sound.handle)
    if !ok
    {
        return
    }

    if rl.IsSoundPlaying(data)
    {
        rl.StopSound(data)
    }
}



audio_set_master_volume :: proc(volume: f32)
{
    rl.SetMasterVolume(volume)
}