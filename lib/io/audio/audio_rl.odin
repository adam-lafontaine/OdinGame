#+private file
package audio

import "core:strings"
import "core:slice"
import "core:mem"

import rl "vendor:raylib"

//import "core:fmt"

FF_WAV :: ".wav"
FF_OGG :: ".ogg"
FF_MP3 :: ".mp3"


find_file_format :: proc(bytes: []byte) -> cstring
{
    cmp :: proc(b: rawptr, str: string) -> bool
    {
        return mem.compare_ptrs(b, raw_data(str), len(str)) == 0
    }

    b := raw_data(bytes)

    if cmp(b, "RIFF") || cmp(b, "WAVE")
    {
        return FF_WAV
    }
    else if cmp(b, "OggS")
    {
        return FF_OGG
    }
    else if cmp(b, "ID3")
    {
        return FF_MP3
    }    

    return "error"
}


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

//AUDIO_FILE_EXT :: ".ogg" // others?

// $P: ^Music or ^Sound
// $T: rl.Music or rl.Sound
// $H: handle, MusicID or SoundID
// $N: array size
// Element zero is nil/invalid
AudioList :: struct($P: typeid, $T: typeid, $H: typeid, $N: u32)
{
    id_nil: H,
    id_begin: H,
    id_end: H,

    count: int,

    ptr: [N + 1]P,

    items: [N + 1]T,
    active: [N + 1]b8,
}


init_audio_list :: proc(list: ^AudioList($P, $T, $H, $N))
{
    list.count = cast(int)(N + 1)

    list.id_nil = cast(H)0
    list.id_begin = cast(H)1
    list.id_end = cast(H)(list.count)

    for i in 0..<list.count
    {
        list.ptr[i] = nil
        list.items[i] = {}
        list.active[i] = false
    }
}


close_audio_list :: proc(list: ^AudioList($P, $T, $H, $N), unload: $U)
{
    for i in 0..<list.count
    {
        if list.active[i]
        {
            unload(list.items[i])
            list.ptr[i] = nil
            list.active[i] = false
        }
    }
}


add_item :: proc(list: ^AudioList($P, $T, $H, $N), ptr: P, item: T) -> (H, bool)
{
    for id: H = list.id_begin; id < list.id_end; id += 1
    {
        if !list.active[id]
        {
            list.ptr[id] = ptr
            list.items[id] = item
            list.active[id] = true

            return id, true
        }
    }

    return list.id_nil, false    
}


remove_item :: proc(list: ^AudioList($P, $T, $H, $N), id: H)
{
    if id < list.id_begin || id >= list.id_end
    {
        return
    }

    list.active[id] = false
    list.ptr[id] = nil
    list.items[id] = list.items[list.id_nil]

}


get_item :: proc(list: ^AudioList($P, $T, $H, $N), id: H) -> (T, bool)
{
    if id < list.id_begin || id >= list.id_end
    {
        return list.items[list.id_nil], false
    }

    return list.items[id], true
}


audio_sound_data: AudioList(^Sound, rl.Sound, SoundID, MAX_SOUND_TRACKS)
audio_music_data: AudioList(^Music, rl.Music, MusicID, MAX_MUSIC_TRACKS)
audio_music_id: MusicID = 0


is_current_music :: proc(id: MusicID) -> bool
{
    return id != audio_music_data.id_nil && id == audio_music_id
}


remove_music :: proc(music: ^Music)
{
    id_nil := audio_music_data.id_nil

    if is_current_music(music.handle)
    {
        audio_music_id = id_nil
    }

    remove_item(&audio_music_data, music.handle)
    music.handle = id_nil
    music.is_on = false
    music.is_paused = false
}


remove_sound :: proc(sound: ^Sound)
{
    remove_item(&audio_sound_data, sound.handle)
    sound.handle = audio_sound_data.id_nil
    sound.is_on = false
}


add_music :: proc(item: rl.Music, music: ^Music) -> bool
{
    id, ok := add_item(&audio_music_data, music, item)
    if ok
    {
        music.handle = id
    }

    return ok
}


add_sound :: proc(item: rl.Sound, sound: ^Sound) -> bool
{
    id, ok := add_item(&audio_sound_data, sound, item)
    if ok
    {
        sound.handle = id
    }

    return ok
}


get_rl_music :: proc(id: MusicID) -> (rl.Music, bool)
{
    return get_item(&audio_music_data, id)
}


get_rl_sound :: proc(id: SoundID) -> (rl.Sound, bool)
{
    return get_item(&audio_sound_data, id)
}


get_audio_music :: proc() -> (^Music, rl.Music, bool)
{
    data, ok := get_rl_music(audio_music_id)
    if !ok
    {
        return nil, data, ok
    }

    music := audio_music_data.ptr[audio_music_id]
    ok &= music != nil

    return music, data, ok
}


/* api */

@(private)
audio_destroy_music :: proc(music: ^Music)
{
    data, ok := get_rl_music(music.handle)
    if !ok
    {
        return
    }

    rl.StopMusicStream(data)
    rl.UnloadMusicStream(data)

    remove_music(music)
}


@(private)
audio_destroy_sound :: proc(sound: ^Sound)
{
    data, ok := get_rl_sound(sound.handle)
    if !ok
    {
        return
    }

    rl.StopSound(data)
    rl.UnloadSound(data)

    remove_sound(sound)
}


@(private)
audio_init_audio :: proc() -> bool
{
    rl.InitAudioDevice()

    init_audio_list(&audio_music_data)
    init_audio_list(&audio_sound_data)

    audio_music_id = audio_music_data.id_nil

    return rl.IsAudioDeviceReady()
}


@(private)
audio_close_audio :: proc()
{
    close_audio_list(&audio_music_data, rl.UnloadMusicStream)
    close_audio_list(&audio_sound_data, rl.UnloadSound)
    rl.CloseAudioDevice()
}


@(private)
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

    return add_music(data, music)
}


@(private)
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

    return add_sound(data, sound)
}


@(private)
audio_load_music_from_bytes :: proc(bytes: ByteView, music: ^Music) -> bool
{
    reset_music(music)

    ext := find_file_format(bytes.data)
    length := cast(i32)len(bytes.data)
    p := raw_data(bytes.data)

    data := rl.LoadMusicStreamFromMemory(ext, p, length)
    if !rl.IsMusicValid(data)
    {
        return false
    }

    return add_music(data, music)
}


@(private)
audio_load_sound_from_bytes :: proc(bytes: ByteView, sound: ^Sound) -> bool
{
    reset_sound(sound)

    ext := find_file_format(bytes.data)
    length := cast(i32)len(bytes.data)
    p := raw_data(bytes.data)

    wave := rl.LoadWaveFromMemory(ext, p, length)
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

    return add_sound(data, sound)
}


@(private)
audio_play_music :: proc(music: ^Music)
{
    audio_music_stop()

    data, ok := get_rl_music(music.handle)
    if ok
    {
        rl.PlayMusicStream(data)
        audio_music_id = music.handle
    }
    
    music.is_on = true
    music.is_paused = false
}


@(private)
audio_music_toggle_pause :: proc()
{
    music, data, ok := get_audio_music()
    if !ok
    {
        return
    }

    playing := rl.IsMusicStreamPlaying(data)

    if music.is_on
    {
        music.is_paused = !playing
    }
    else if playing
    {
        // error
        rl.StopMusicStream(data)
        music.is_paused = false
        return
    }

    if playing
    {
        rl.PauseMusicStream(data)
        music.is_paused = true
    }
    else
    {
        rl.ResumeMusicStream(data)
        music.is_paused = false
    }
}


@(private)
audio_music_stop :: proc()
{
    music, data, ok := get_audio_music()
    if !ok
    {
        return
    }

    rl.StopMusicStream(data)
    music.is_on = false
    music.is_paused = false
}


@(private)
audio_play_sound :: proc(sound: ^Sound)
{
    data, ok := get_rl_sound(sound.handle)
    if !ok
    {
        sound.is_on = false
        return
    }

    if rl.IsSoundPlaying(data)
    {
        rl.StopSound(data)        
    }

    rl.PlaySound(data)
    sound.is_on = true
}


@(private)
audio_stop_sound :: proc(sound: ^Sound)
{
    sound.is_on = false

    data, ok := get_rl_sound(sound.handle)
    if !ok
    {
        return
    }

    if rl.IsSoundPlaying(data)
    {
        rl.StopSound(data)
    }
}


@(private)
audio_set_master_volume :: proc(volume: f32)
{
    rl.SetMasterVolume(volume)
}


@(private)
audio_music_update_jank :: proc()
{
    data, ok := get_rl_music(audio_music_id)
    if ok
    {
        // music won't play if this isn't called every frame
        rl.UpdateMusicStream(data)
    }
}