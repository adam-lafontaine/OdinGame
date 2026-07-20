package audio


import sv "../../span_view"


ByteView :: sv.ByteView


Music :: struct
{
    handle: i32,

    is_on: bool,
    is_paused: bool,
}


Sound :: struct
{
    handle: i32,

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