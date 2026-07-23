#+private
package app

import "core:thread"

import img "../../../lib/image_view"
import mb "../../../lib/memory_buffer"
//import fs "../../../lib/files"
import sv "../../../lib/span_view"
import "../../../lib/io/audio"
import "../../res"


//BIN_DATA_PATH :: "./io_test_data.bin"
//BIN_DATA_FALLBACK :: "/home/adam/Repos/OdinGame/game_io_test/res/io_test_data.bin"


AssetStatus :: enum 
{
    None,
    Load,
    Process,
    Ready,
    Fail
}


AssetMemory :: struct 
{
    image: struct
    {
        gamepad: ImageView,
        keyboard: ImageView,
        mouse: ImageView,
        arrow: ImageView
    },

    music: struct
    {
        A: Music,
        B: Music,
        C: Music,
        D: Music,
    },

    sound: struct
    {
        A: Sound,
        B: Sound,
        C: Sound,
        D: Sound,
    },

    image_pixels: img.Buffer32,
    //bin_bytes: ByteBuffer,

    status: AssetStatus
}


destroy_asset_memory :: proc(memory: ^AssetMemory)
{
    img.destroy_buffer32(&memory.image_pixels)
    //mb.destroy_buffer(&memory.bin_bytes)

    memory.status = .None
}


count_asset_pixels :: proc() -> u32
{
    masks := &res.MASK_Images

    w := masks[.keyboard].width
    h := masks[.keyboard].height
    count := w * h

    w = masks[.controller].width
    h = masks[.controller].height
    count += w * h

    w = masks[.mouse].width
    h = masks[.mouse].height
    count += w * h

    w = masks[.arrow].width
    h = masks[.arrow].height
    count += w * h

    return cast(u32) count
}


read_image :: proc(memory: ^AssetMemory, id: res.MASK_ID) -> bool
{
    pixels := &memory.image_pixels

    dst: ^ImageView = nil

    switch id
    {
    case .keyboard:   dst = &memory.image.keyboard
    case .controller: dst = &memory.image.gamepad
    case .mouse:      dst = &memory.image.mouse
    case .arrow:      dst = &memory.image.arrow
    case: return false
    }

    info := res.MASK_Images[id]

    //bv := sv.sub_view(memory.bin_bytes, info.offset, info.size)

    bv := ByteView { data = info.data }
    ok := img.read_image_from_memory(bv, pixels, dst)

    return ok
}


read_music :: proc(memory: ^AssetMemory, id: res.MUSIC_ID) -> bool
{
    dst: ^Music
    
    switch id
    {
    case .game_00: dst = &memory.music.A
    case .game_01: dst = &memory.music.B
    case .game_02: dst = &memory.music.C
    case .game_03: dst = &memory.music.D
    }

    info := res.MUSIC_Audio[id]

    //bv := sv.sub_view(memory.bin_bytes, info.offset, info.size)

    bv := ByteView { data = info.data }
    ok := audio.load_music_from_bytes(bv, dst)

    return ok
}


read_sound :: proc(memory: ^AssetMemory, id: res.SOUND_ID) -> bool
{
    dst: ^Sound

    switch id
    {
    case .laserRetro_000:      dst = &memory.sound.A
    case .open_001:            dst = &memory.sound.B
    case .confirmation_002:    dst = &memory.sound.C
    case .explosionCrunch_003: dst = &memory.sound.D
    }

    info := res.SOUND_Audio[id]

    //bv := sv.sub_view(memory.bin_bytes, info.offset, info.size)

    bv := ByteView { data = info.data }
    ok := audio.load_sound_from_bytes(bv, dst)

    return ok
}


read_asset_memory :: proc(memory: ^AssetMemory) -> bool
{
    /*buffer := &memory.bin_bytes
    if !buffer.ok
    {
        assert(false, "*** BAD BUFFER ***")
        return false
    }*/
    
    pixels := &memory.image_pixels
    n_pixels := count_asset_pixels()

    result := mb.create_buffer(pixels, n_pixels)
    if result != .OK
    {
        assert(false, "*** ASSET PIXELS ***")
        return false
    }

    ok := true
    
    for id in res.MASK_ID
    {
        ok &= read_image(memory, id)
    }

    assert(ok, "*** READ IMAGE ***")

    for id in res.MUSIC_ID
    {
        ok &= read_music(memory, id)
    }

    assert(ok, "*** READ MUSIC ***")

    for id in res.SOUND_ID
    {
        ok &= read_sound(memory, id)
    }

    assert(ok, "*** READ MUSIC ***")
    
    return ok
}


@(private="file")
asset_thread_proc :: proc(t: ^thread.Thread)
{
    am := (^AssetMemory)(t.data)

    ok := read_asset_memory(am)
    am.status = ok ? .Process : .Fail
}


load_asset_memory_async :: proc(memory: ^AssetMemory) -> ^thread.Thread
{
    /*assets_read :: proc(bytes: ByteView, data: rawptr)
    {
        am := (^AssetMemory)(data)

        am.bin_bytes = sv.clone(bytes)
        if !am.bin_bytes.ok
        {
            am.status = .Fail
            return
        }

        ok := read_asset_memory(am)
        am.status = ok ? .Process : .Fail
    }

    assets_fail :: proc(data: rawptr)
    {
        assert(false, "*** FAIL ***")
        am := (^AssetMemory)(data)
        am.status = .Fail
    }

    ctx := fs.FetchContext {
        path = BIN_DATA_PATH,
        path_backup = BIN_DATA_FALLBACK,
        read_bytes = assets_read,
        fetch_failed = assets_fail,
        user_data = memory
    }

    return fs.fetch_start_thread(ctx)*/

    th := thread.create(asset_thread_proc)
    th.data = memory
    thread.start(th)

    return th
}


