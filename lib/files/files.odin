package files

import "core:os"
import "core:strings"
import "core:thread"

import mb "../memory_buffer"
import sv "../span_view"


ByteBuffer :: mb.MemoryBuffer(byte)
ByteView :: sv.ByteView


read_bytes :: proc(path: string) -> ByteBuffer
{
    buffer := ByteBuffer { ok = false, size = 0 }

    data, err := os.read_entire_file(path, context.allocator)
    if err == nil
    {
        buffer.data = data
        buffer.ok = true
    }

    return buffer
}


FetchReadCallback :: proc(bytes: ByteView, data: rawptr)
FetchFailCallback :: proc(data: rawptr)


FetchContext :: struct 
{
    path: string,
    path_backup: string,
    read_bytes: FetchReadCallback,
    fetch_failed: FetchFailCallback,

    user_data: rawptr,
}


fetch :: proc(ctx: ^FetchContext)
{
    buffer := read_bytes(ctx.path)
    if !buffer.ok
    {
        read_bytes(ctx.path_backup)
    }

    if buffer.ok
    {
        ctx.read_bytes(sv.make_view(buffer), ctx.user_data)
        mb.destroy_buffer(&buffer)
    }
    else
    {
        ctx.fetch_failed(ctx.user_data)
    }

    free(ctx)
}


fetch_start_thread :: proc(ctx: ^FetchContext) -> ^thread.Thread
{
    thread_proc :: proc(t: ^thread.Thread)
    {
        fc := (^FetchContext)(t.data)
        fetch(fc)
    }

    th := thread.create(thread_proc)
    th.data = ctx
    thread.start(th)

    return th
}
