// Copyright (c) 2023 Christoffer Lerno. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the LICENSE_STDLIB file.
module std::core::mem::allocator;
import std::math;

struct ArenaAllocator (Allocator)
{
	char[] data;
	usz used;
}

<*
 Initialize a memory arena for use using the provided bytes.
*>
fn ArenaAllocator* ArenaAllocator.init(&self, char[] data)
{
	self.data = data;
	self.used = 0;
	return self;
}

fn void ArenaAllocator.clear(&self)
{
	self.used = 0;
}

struct ArenaAllocatorHeader @local
{
	usz size;
	char[*] data;
}

macro ArenaAllocator* wrap(char[] bytes)
{
	return (ArenaAllocator){}.init(bytes);
}

<*
 @require ptr != null
*>
fn void ArenaAllocator.release(&self, void* ptr, bool) @dynamic
{
	assert((uptr)ptr >= (uptr)self.data.ptr, "Pointer originates from a different allocator.");
	ArenaAllocatorHeader* header = ptr - ArenaAllocatorHeader.sizeof;
	// Reclaim memory if it's the last element.
	if (ptr + header.size == &self.data[self.used])
	{
		self.used -= header.size + ArenaAllocatorHeader.sizeof;
	}
}

fn usz ArenaAllocator.mark(&self) => self.used;
fn void ArenaAllocator.reset(&self, usz mark) => self.used = mark;

<*
 @require !alignment || math::is_power_of_2(alignment)
 @require alignment <= mem::MAX_MEMORY_ALIGNMENT : `alignment too big`
 @require size > 0
 @return? mem::INVALID_ALLOC_SIZE, mem::OUT_OF_MEMORY
*>
fn void*? ArenaAllocator.acquire(&self, usz size, AllocInitType init_type, usz alignment) @dynamic
{
	alignment = alignment_for_allocation(alignment);
	usz total_len = self.data.len;
	if (size > total_len) return mem::INVALID_ALLOC_SIZE?;
	void* start_mem = self.data.ptr;
	void* unaligned_pointer_to_offset = start_mem + self.used + ArenaAllocatorHeader.sizeof;
	void* mem = mem::aligned_pointer(unaligned_pointer_to_offset, alignment);
	usz end = (usz)(mem - self.data.ptr) + size;
	if (end > total_len) return mem::OUT_OF_MEMORY?;
	self.used = end;
	ArenaAllocatorHeader* header = mem - ArenaAllocatorHeader.sizeof;
	header.size = size;
	if (init_type == ZERO) mem::clear(mem, size, mem::DEFAULT_MEM_ALIGNMENT);
	return mem;
}

<*
 @require !alignment || math::is_power_of_2(alignment)
 @require alignment <= mem::MAX_MEMORY_ALIGNMENT : `alignment too big`
 @require old_pointer != null
 @require size > 0
 @return? mem::INVALID_ALLOC_SIZE, mem::OUT_OF_MEMORY
*>
fn void*? ArenaAllocator.resize(&self, void *old_pointer, usz size, usz alignment) @dynamic
{
	alignment = alignment_for_allocation(alignment);
	assert(old_pointer >= self.data.ptr, "Pointer originates from a different allocator.");
	usz total_len = self.data.len;
	if (size > total_len) return mem::INVALID_ALLOC_SIZE?;
	ArenaAllocatorHeader* header = old_pointer - ArenaAllocatorHeader.sizeof;
	usz old_size = header.size;
	// Do last allocation and alignment match?
	if (&self.data[self.used] == old_pointer + old_size && mem::ptr_is_aligned(old_pointer, alignment))
	{
		if (old_size >= size)
		{
			self.used -= old_size - size;
		}
		else
		{
			usz new_used = self.used + size - old_size;
			if (new_used > total_len) return mem::OUT_OF_MEMORY?;
			self.used = new_used;
		}
		header.size = size;
		return old_pointer;
	}
	// Otherwise just allocate new memory.
	void* mem = self.acquire(size, NO_ZERO, alignment)!;
	mem::copy(mem, old_pointer, old_size, mem::DEFAULT_MEM_ALIGNMENT, mem::DEFAULT_MEM_ALIGNMENT);
	return mem;
}