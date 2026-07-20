#+private
package app

import "core:thread"

import img "../../../lib/image_view"
import mb "../../../lib/memory_buffer"
import fs "../../../lib/files"
import sv "../../../lib/span_view"
import "../../res"


BIN_DATA_PATH :: "./io_test_data.bin";
BIN_DATA_FALLBACK :: "/home/adam/Repos/OdinGame/game_io_test/res/io_test_data.bin";



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
        A: ByteView,
        B: ByteView,
        C: ByteView,
        D: ByteView,
    },

    sound: struct
    {
        A: ByteView,
        B: ByteView,
        C: ByteView,
        D: ByteView,
    },

    image_pixels: img.Buffer32,
    bin_bytes: ByteBuffer,

    status: AssetStatus
}


destroy_asset_memory :: proc(memory: ^AssetMemory)
{
    img.destroy_buffer32(&memory.image_pixels)
    mb.destroy_buffer(&memory.bin_bytes)

    memory.status = .None
}


count_asset_pixels :: proc() -> u32
{
    w := res.masks[.keyboard].width
    h := res.masks[.keyboard].height
    count := w * h

    w = res.masks[.gamepad].width
    h = res.masks[.gamepad].height
    count += w * h

    w = res.masks[.mouse].width
    h = res.masks[.mouse].height
    count += w * h

    w = res.masks[.arrow].width
    h = res.masks[.arrow].height
    count += w * h

    return count
}


read_image :: proc(memory: ^AssetMemory, id: res.ImageID) -> bool
{
    pixels := &memory.image_pixels

    dst: ^ImageView = nil

    switch id
    {
    case .keyboard: dst = &memory.image.keyboard
    case .gamepad:  dst = &memory.image.gamepad
    case .mouse:    dst = &memory.image.mouse
    case .arrow:    dst = &memory.image.arrow
    case: return false
    }

    info := res.masks[id]

    bv := sv.sub_view(memory.bin_bytes, info.offset, info.size)
    ok := img.read_image_from_memory(bv, pixels, dst)

    return ok
}


read_asset_memory :: proc(memory: ^AssetMemory) -> bool
{
    buffer := &memory.bin_bytes
    if !buffer.ok
    {
        assert(false, "*** BAD BUFFER ***")
        return false
    }
    
    pixels := &memory.image_pixels
    n_pixels := count_asset_pixels()

    result := mb.create_buffer(pixels, n_pixels)
    if result != .OK
    {
        assert(false, "*** ASSET PIXELS ***")
        return false
    }

    ok := true
    
    for id in res.ImageID
    {
        ok &= read_image(memory, id)
    }

    assert(ok, "*** READ IMAGE ***")
    
    return ok
}


/*load_asset_memory :: proc(memory: ^AssetMemory) -> bool
{
    memory.status = .Load

    buffer := fs.read_bytes(BIN_DATA_PATH)
    if !buffer.ok
    {
        buffer = fs.read_bytes(BIN_DATA_FALLBACK)
    }

    if !buffer.ok
    {
        assert(false, "*** ASSET BUFFER ***")
        memory.status = .Fail
        return false
    }

    assert(len(buffer.data) > 0, "*** WAT? ***")

    memory.bin_bytes = buffer
    
    ok := read_asset_memory(memory)
    assert(ok, "*** ASSET READ ***")

    memory.status = ok ? .Process : .Fail

    return ok
}*/


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
    am := (^AssetMemory)(data)
    am.status = .Fail
}


load_asset_memory_async :: proc(memory: ^AssetMemory) -> ^thread.Thread
{
    // blocking for now
    /*ok := load_asset_memory(memory)
    if !ok
    {
        assert(false, "*** LOAD ASSETS ***")
    }*/

    

    ctx := new(fs.FetchContext)
    ctx.path = BIN_DATA_PATH
    ctx.path_backup = BIN_DATA_FALLBACK
    ctx.read_bytes = assets_read
    ctx.fetch_failed = assets_fail
    ctx.user_data = memory

    return fs.fetch_start_thread(ctx)    
}


