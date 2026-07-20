package span_view

import "core:mem"
import "core:slice"

import mb "../memory_buffer"


SpanView :: struct($T: typeid)
{
    data: []T,
    //length: u32
}


ByteView :: SpanView(byte)


make_view :: proc(buffer: mb.MemoryBuffer($T)) -> SpanView(T)
{
    return SpanView(T) {
        data = buffer.data
    }
}


sub_view :: proc(buffer: mb.MemoryBuffer($T), offset: u32, length: u32) -> SpanView(T)
{
    assert(len(buffer.data) > 0, "*** BAD BUFFER ***")
    
    return SpanView(T) {
        data = buffer.data[offset:offset + length]
    }
}


copy :: proc(src: SpanView($T), dst: SpanView(T))
{
    assert(len(src) == len(dst))

    for s, i in src.data // mem.copy()?
    {
        dst.data[i] = s
    }
}


clone :: proc(view: SpanView($T)) -> mb.MemoryBuffer(T)
{
    dst: mb.MemoryBuffer(T)

    dst.data = slice.clone(view.data)
    
    dst.ok = true
    dst.size = 0

    return dst
}