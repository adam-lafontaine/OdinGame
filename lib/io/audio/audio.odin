package audio


import sv "../../span_view"


ByteView :: sv.ByteView
MusicID :: distinct i32
SoundID :: distinct i32


Music :: struct
{
    handle: MusicID,
    is_on: bool,
    is_paused: bool,
}


Sound :: struct
{
    handle: SoundID,
    is_on: bool,
}


destroy_music :: proc(music: ^Music)
{
    // stop_music
    audio_destroy_music(music)
}


destroy_sound :: proc(sound: ^Sound)
{
    // stop sound
    audio_destroy_sound(sound)
}


init_audio :: proc() -> bool
{
    return audio_init_audio()
}


close_audio :: proc()
{
    audio_close_audio()
}


load_music_from_file :: proc(music_file_path: string, music: ^Music) -> bool
{
    return audio_load_music_from_file(music_file_path, music)
}


load_sound_from_file :: proc(music_file_path: string, sound: ^Sound) -> bool
{
    return audio_load_sound_from_file(music_file_path, sound)
}


load_music_from_bytes :: proc(bytes: ByteView, music: ^Music) -> bool
{
    return audio_load_music_from_bytes(bytes, music)
}


load_sound_from_bytes :: proc(bytes: ByteView, sound: ^Sound) -> bool
{
    return audio_load_sound_from_bytes(bytes, sound)
}


play_music :: proc(music: ^Music)
{
    audio_play_music(music)
}


toggle_pause_music :: proc(){}


stop_music :: proc()
{
    audio_music_stop()
}


//fade_in_music :: proc(music: ^Music, fade_ms: u32){}

//fade_out_music :: proc(fade_ms: u32){}


play_sound :: proc(sound: ^Sound)
{
    audio_play_sound(sound)
}


//play_sound_loop :: proc(sound: ^Sound){}


stop_sound :: proc(sound: ^Sound)
{
    audio_stop_sound(sound)
}

//stop_sound :: proc(){}


set_master_volume :: proc(volume: f32) { audio_set_master_volume(volume) }


music_refresh :: proc() { audio_music_update_jank() }