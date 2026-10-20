module Ansi
  module Sixel
    # Max-heap matching Go's container/heap behavior for the sixel cube
    # priority queue. The block returns true when *left* should be popped
    # before *right*.
    class MaxHeap(T)
      getter size : Int32

      def initialize(&@less : T, T -> Bool)
        @items = [] of T
        @size = 0
      end

      def push(item : T) : Nil
        @items << item
        @size += 1
        up(@size - 1)
      end

      def pop : T
        raise IndexError.new("empty heap") if @size == 0

        swap(0, @size - 1)
        down(0, @size - 1)
        @size -= 1
        @items.pop
      end

      private def up(j : Int32) : Nil
        loop do
          i = (j - 1) // 2
          break if i == j || !@less.call(@items[j], @items[i])

          swap(i, j)
          j = i
        end
      end

      private def down(i0 : Int32, n : Int32) : Nil
        i = i0
        loop do
          j1 = 2 * i + 1
          break if j1 >= n

          j = j1
          j2 = j1 + 1
          if j2 < n && @less.call(@items[j2], @items[j1])
            j = j2
          end

          break unless @less.call(@items[j], @items[i])

          swap(i, j)
          i = j
        end
      end

      private def swap(i : Int32, j : Int32) : Nil
        @items[i], @items[j] = @items[j], @items[i]
      end
    end
  end
end
