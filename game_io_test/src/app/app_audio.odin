#+private
package app

import "../../../lib/io/audio"


MusicView :: struct 
{
    data: ^Music
}


SoundView :: struct
{
    data: ^Sound
}


play_sound :: proc(sound: SoundView)
{
    audio.play_sound(sound.data)
}


play_music :: proc(music: MusicView)
{
    audio.play_music(music.data)
}


stop_music ::audio.stop_music
music_refresh :: audio.music_refresh


MusicList :: struct
{
    music_A: MusicView,
    music_B: MusicView,
    music_C: MusicView,
    music_D: MusicView,
}


make_music_list :: proc(memory: ^AssetMemory) -> MusicList
{
    return MusicList {
        music_A = { data = &memory.music.A },
        music_B = { data = &memory.music.B },
        music_C = { data = &memory.music.C },
        music_D = { data = &memory.music.D },
    }
}


SoundList :: struct
{
    sound_A: SoundView,
    sound_B: SoundView,
    sound_C: SoundView,
    sound_D: SoundView,
}


make_sound_list :: proc(memory: ^AssetMemory) -> SoundList
{
    return SoundList {
        sound_A = { data = &memory.sound.A },
        sound_B = { data = &memory.sound.B },
        sound_C = { data = &memory.sound.C },
        sound_D = { data = &memory.sound.D },
    }
}