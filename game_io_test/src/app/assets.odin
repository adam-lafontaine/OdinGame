#+private
package app

ASSETS_BINARY :: #config(ASSETS_BINARY, false)

import "core:thread"

import img "../../../lib/image_view"
import mb "../../../lib/memory_buffer"
import fs "../../../lib/files"
import sv "../../../lib/span_view"
import "../../../lib/io/audio"
import "../../res"



get_res_bytes :: proc {
    res.get_MASK_bytes,
    res.get_MUSIC_bytes,
    res.get_SOUND_bytes
}


AssetStatus :: enum 
{
    None,
    Load,
    Process,
    Ready,
    Fail
}

when ASSETS_BINARY {

BIN_DATA_PATH :: "./io_test_data.bin"
BIN_DATA_FALLBACK :: "/home/adam/Repos/OdinGame/game_io_test/gen/out/io_test_data.bin"

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
    bin_bytes: ByteBuffer,

    status: AssetStatus
}


get_asset_bytes :: proc(memory: ^AssetMemory, id: $ID) -> ByteView
{
    return ByteView { data = get_res_bytes(memory.bin_bytes.data, id) }
}


destroy_asset_memory :: proc(memory: ^AssetMemory)
{
    img.destroy_buffer32(&memory.image_pixels)
    mb.destroy_buffer(&memory.bin_bytes)

    memory.status = .None
}

} else {

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

    status: AssetStatus
}


get_asset_bytes :: proc(memory: ^AssetMemory, id: $ID) -> ByteView
{
    return ByteView { data = get_res_bytes(id) }
}


destroy_asset_memory :: proc(memory: ^AssetMemory)
{
    img.destroy_buffer32(&memory.image_pixels)

    memory.status = .None
}

} // !ASSETS_BINARY


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


@(private="file")
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

    bv := get_asset_bytes(memory, id)
    ok := img.read_image_from_memory(bv, pixels, dst)

    return ok
}


@(private="file")
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

    bv := get_asset_bytes(memory, id)
    ok := audio.load_music_from_bytes(bv, dst)

    return ok
}


@(private="file")
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

    bv := get_asset_bytes(memory, id)
    ok := audio.load_sound_from_bytes(bv, dst)

    return ok
}


@(private="file")
read_asset_memory :: proc(memory: ^AssetMemory) -> bool
{    
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


when ASSETS_BINARY {

load_asset_memory_async :: proc(memory: ^AssetMemory) -> ^thread.Thread
{
    assets_read :: proc(bytes: ByteView, data: rawptr)
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

    return fs.fetch_start_thread(ctx)    
}

} else {


load_asset_memory_async :: proc(memory: ^AssetMemory) -> ^thread.Thread
{
    asset_thread_proc :: proc(t: ^thread.Thread)
    {
        am := (^AssetMemory)(t.data)

        ok := read_asset_memory(am)
        am.status = ok ? .Process : .Fail
    }

    th := thread.create(asset_thread_proc)
    th.data = memory
    thread.start(th)

    return th
}

}
