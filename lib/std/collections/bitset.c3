<*
 @require SIZE > 0
*>
module std::collections::bitset{SIZE};

alias Type = uint;

const BITS = Type.sizeof * 8;
const SZ = (SIZE + BITS - 1) / BITS;

struct BitSet
{
	Type[SZ] data;
}

fn usz BitSet.cardinality(&self)
{
	usz n;
	foreach (x : self.data)
	{
		n += x.popcount();
	}
	return n;
}

<*
 @require i < SIZE
*>
fn void BitSet.set(&self, usz i)
{
	usz q = i / BITS;
	usz r = i % BITS;
	self.data[q] |= 1 << r;
}

<*
 @require i < SIZE
*>
fn void BitSet.unset(&self, usz i)
{
	usz q = i / BITS;
	usz r = i % BITS;
	self.data[q] &= ~(1 << r);
}

<*
 @require i < SIZE
*>
fn bool BitSet.get(&self, usz i) @operator([]) @inline
{
	usz q = i / BITS;
	usz r = i % BITS;
	return self.data[q] & (1 << r) != 0;
}

fn usz BitSet.len(&self) @operator(len) @inline
{
	return SZ * BITS;
}

<*
 @require i < SIZE
*>
fn void BitSet.set_bool(&self, usz i, bool value) @operator([]=) @inline
{
	if (value) return self.set(i);
	self.unset(i);
}

<*
 @require Type.kindof == UNSIGNED_INT
*>
module std::collections::growablebitset{Type};
import std::collections::list;

const BITS = Type.sizeof * 8;

alias GrowableBitSetList = List{Type};

struct GrowableBitSet
{
	GrowableBitSetList data;
}

<*
 @param initial_capacity
 @param [&inout] allocator : "The allocator to use, defaults to the heap allocator"
*>
fn GrowableBitSet* GrowableBitSet.init(&self, Allocator allocator, usz initial_capacity = 1)
{
	self.data.init(allocator, initial_capacity);
	return self;
}

fn GrowableBitSet* GrowableBitSet.tinit(&self, usz initial_capacity = 1)
{
	return self.init(tmem, initial_capacity) @inline;
}

fn void GrowableBitSet.free(&self)
{
	self.data.free();
}

fn usz GrowableBitSet.cardinality(&self)
{
	usz n;
	foreach (x : self.data)
	{
		n += x.popcount();
	}
	return n;
}

fn void GrowableBitSet.set(&self, usz i)
{
	usz q = i / BITS;
	usz r = i % BITS;
	usz current_len = self.data.len();
	while (q >= current_len)
	{
		self.data.push(0);
		current_len++;
	}
	self.data.set(q, self.data[q] | (1 << r));
}

fn void GrowableBitSet.unset(&self, usz i)
{
	usz q = i / BITS;
	usz r = i % BITS;
	if (q >= self.data.len()) return;
	self.data.set(q, self.data[q] &~ (1 << r));
}

fn bool GrowableBitSet.get(&self, usz i) @operator([]) @inline
{
	usz q = i / BITS;
	usz r = i % BITS;
	if (q >= self.data.len()) return false;
	return self.data[q] & (1 << r) != 0;
}

fn usz GrowableBitSet.len(&self) @operator(len)
{
	usz n = self.data.len() * BITS;
	if (n > 0) n -= (usz)self.data[^1].clz();
	return n;
}

fn void GrowableBitSet.set_bool(&self, usz i, bool value) @operator([]=) @inline
{
	if (value) return self.set(i);
	self.unset(i);
}