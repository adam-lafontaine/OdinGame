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
        ctx.read_bytes(sv.make_view(buffer), ctx.user_data)
        mb.destroy_buffer(&buffer)
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


BinaryFile :: struct
{
    file: ^os.File,
    size: u32,
    ok: bool
}


BinaryRange :: struct
{
    offset: u32,
    length: u32,
}


create_binary_file :: proc(path: string) -> BinaryFile
{
    flags: os.File_Flags = {.Write, .Create, .Trunc}
    
    perm : os.Permissions = {
        .Read_User,
        .Write_User, 
        .Read_Other,
        .Write_Other,
        .Read_Group,
        .Write_Group
    }

    bin: BinaryFile

    file, err := os.open(path, flags, perm)
    if err != nil
    {
        bin.ok = false
        return bin
    }

    bin.file = file
    bin.size = 0
    bin.ok = true

    return bin
}


close_binary_file :: proc(bin: ^BinaryFile)
{
    os.close(bin.file)
    bin.size = 0
    bin.ok = false
}


append_binary_file :: proc(bin: ^BinaryFile, bytes: []u8) -> (BinaryRange, bool)
{
    range: BinaryRange

    n, err := os.write(bin.file, bytes)
    if err != nil
    {
        return range, false
    }

    range.offset = bin.size
    range.length = cast(u32)n

    bin.size += range.length

    return range, true
}
