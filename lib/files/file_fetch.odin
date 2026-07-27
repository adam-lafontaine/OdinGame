package files

import "core:thread"


// Load a file on a new thread
// Over-complicated but made to resemble the emscripten fetch api

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


@(private="file")
FetchRequest :: struct
{
    // hide new and free from api
    ctx: FetchContext
}


@(private="file")
fetch_thread_proc :: proc(t: ^thread.Thread)
{
    req := (^FetchRequest)(t.data)

    ctx := req.ctx

    buffer := read_bytes(ctx.path)
    if !buffer.ok
    {
        buffer = read_bytes(ctx.path_backup)
    }

    if buffer.ok
    {
        ctx.read_bytes(to_byte_view(buffer), ctx.user_data)
        destroy_bytes(&buffer)
    }
    else
    {
        ctx.fetch_failed(ctx.user_data)
    }

    free(req)
}


fetch_start_thread :: proc(ctx: FetchContext) -> ^thread.Thread
{
    req := new(FetchRequest)
    req.ctx = ctx

    th := thread.create(fetch_thread_proc)
    th.data = req
    thread.start(th)

    return th
}