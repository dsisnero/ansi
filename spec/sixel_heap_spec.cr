require "./spec_helper"

describe "Ansi::Sixel::MaxHeap" do
  it "pops values in Go container/heap order" do
    heap = Ansi::Sixel::MaxHeap(Int32).new { |left, right| left > right }
    [5, 3, 5, 1, 5, 2, 4].each { |value| heap.push(value) }

    popped = [] of Int32
    while heap.size > 0
      popped << heap.pop
    end
    popped.should eq [5, 5, 5, 4, 3, 2, 1]
  end

  it "matches Go when pushes and pops are interleaved" do
    heap = Ansi::Sixel::MaxHeap(Int32).new { |left, right| left > right }
    heap.push(10)
    heap.pop.should eq 10

    [7, 7, 3].each { |value| heap.push(value) }

    popped = [] of Int32
    while heap.size > 0
      popped << heap.pop
    end
    popped.should eq [7, 7, 3]
  end
end
