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

    n_bytes := len(src) * size_of(T)
    s := &src.data[0]
    d := &dst.data[0]

    mem.copy(d, s, n_bytes)
}


clone :: proc(view: SpanView($T)) -> mb.MemoryBuffer(T)
{
    dst: mb.MemoryBuffer(T)

    dst.data = slice.clone(view.data)
    
    dst.ok = true
    dst.size = 0

    return dst
}