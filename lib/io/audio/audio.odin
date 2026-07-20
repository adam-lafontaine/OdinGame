package audio


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