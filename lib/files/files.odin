package files

import "core:os"
import "core:strings"

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


destroy_bytes :: proc(buffer: ^ByteBuffer)
{
    mb.destroy_buffer(buffer)
}


to_byte_view :: proc(buffer: ByteBuffer) -> ByteView
{
    return sv.make_view(buffer)
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
