module Ansi
  module Sixel
    # Port of x/ansi/sixel/palette_sort.go, a pattern-defeating quicksort with
    # the same xorshift-based pattern breaking used by the Go median-cut sort.
    module PaletteSort
      enum SortedHint
        Unknown
        Increasing
        Decreasing
      end

      MAX_INSERTION         = 12
      SHORTEST_NINTHER      = 50
      MAX_SWAPS             = 4 * 3
      MAX_STEPS             =  5
      SHORTEST_SHIFTING     = 50
      BREAK_PATTERNS_LENGTH =  8

      # xorshift paper: https://www.jstatsoft.org/article/view/v008i14/xorshift.pdf
      struct Xorshift
        def initialize(@state : UInt64)
        end

        def next_value : UInt64
          @state ^= @state << 13
          @state ^= @state >> 7
          @state ^= @state << 17
          @state
        end
      end

      # Equivalent to Go's `1 << bits.Len(uint(length))`.
      def self.next_power_of_two(length : Int32) : UInt32
        1_u32 << bit_length(length)
      end

      private def self.bit_length(value : Int32) : Int32
        bits = 0
        while value > 0
          bits += 1
          value >>= 1
        end
        bits
      end

      # Sorts *data* in place using the same pdqsort implementation as Go.
      def self.sort!(data : Array(T), &cmp : T, T -> Int32) : Nil forall T
        pdqsort(data, 0, data.size, bit_length(data.size), cmp)
      end

      private def self.insertion_sort(data : Array(T), a : Int32, b : Int32, cmp : Proc(T, T, Int32)) : Nil forall T
        i = a + 1
        while i < b
          j = i
          while j > a && cmp.call(data[j], data[j - 1]) < 0
            data[j], data[j - 1] = data[j - 1], data[j]
            j -= 1
          end
          i += 1
        end
      end

      private def self.sift_down(data : Array(T), lo : Int32, hi : Int32, first : Int32, cmp : Proc(T, T, Int32)) : Nil forall T
        root = lo
        loop do
          child = 2 * root + 1
          break if child >= hi

          if child + 1 < hi && cmp.call(data[first + child], data[first + child + 1]) < 0
            child += 1
          end

          return unless cmp.call(data[first + root], data[first + child]) < 0

          data[first + root], data[first + child] = data[first + child], data[first + root]
          root = child
        end
      end

      private def self.heap_sort(data : Array(T), a : Int32, b : Int32, cmp : Proc(T, T, Int32)) : Nil forall T
        first = a
        lo = 0
        hi = b - a

        i = (hi - 1) // 2
        while i >= 0
          sift_down(data, i, hi, first, cmp)
          i -= 1
        end

        i = hi - 1
        while i >= 0
          data[first], data[first + i] = data[first + i], data[first]
          sift_down(data, lo, i, first, cmp)
          i -= 1
        end
      end

      private def self.pdqsort(data : Array(T), a : Int32, b : Int32, limit : Int32, cmp : Proc(T, T, Int32)) : Nil forall T
        was_balanced = true
        was_partitioned = true

        loop do
          length = b - a

          if length <= MAX_INSERTION
            insertion_sort(data, a, b, cmp)
            return
          end

          if limit == 0
            heap_sort(data, a, b, cmp)
            return
          end

          unless was_balanced
            break_patterns(data, a, b)
            limit -= 1
          end

          pivot, hint = choose_pivot(data, a, b, cmp)
          if hint == SortedHint::Decreasing
            reverse_range(data, a, b)
            pivot = (b - 1) - (pivot - a)
            hint = SortedHint::Increasing
          end

          if was_balanced && was_partitioned && hint == SortedHint::Increasing
            return if partial_insertion_sort(data, a, b, cmp)
          end

          if a > 0 && cmp.call(data[a - 1], data[pivot]) >= 0
            a = partition_equal(data, a, b, pivot, cmp)
            next
          end

          mid, already_partitioned = partition(data, a, b, pivot, cmp)
          was_partitioned = already_partitioned

          left_len = mid - a
          right_len = b - mid
          balance_threshold = length // 8
          if left_len < right_len
            was_balanced = left_len >= balance_threshold
            pdqsort(data, a, mid, limit, cmp)
            a = mid + 1
          else
            was_balanced = right_len >= balance_threshold
            pdqsort(data, mid + 1, b, limit, cmp)
            b = mid
          end
        end
      end

      private def self.partition(data : Array(T), a : Int32, b : Int32, pivot : Int32, cmp : Proc(T, T, Int32)) : {Int32, Bool} forall T
        data[a], data[pivot] = data[pivot], data[a]
        i = a + 1
        j = b - 1

        while i <= j && cmp.call(data[i], data[a]) < 0
          i += 1
        end
        while i <= j && cmp.call(data[j], data[a]) >= 0
          j -= 1
        end
        if i > j
          data[j], data[a] = data[a], data[j]
          return {j, true}
        end

        data[i], data[j] = data[j], data[i]
        i += 1
        j -= 1

        loop do
          while i <= j && cmp.call(data[i], data[a]) < 0
            i += 1
          end
          while i <= j && cmp.call(data[j], data[a]) >= 0
            j -= 1
          end
          break if i > j

          data[i], data[j] = data[j], data[i]
          i += 1
          j -= 1
        end

        data[j], data[a] = data[a], data[j]
        {j, false}
      end

      private def self.partition_equal(data : Array(T), a : Int32, b : Int32, pivot : Int32, cmp : Proc(T, T, Int32)) : Int32 forall T
        data[a], data[pivot] = data[pivot], data[a]
        i = a + 1
        j = b - 1

        loop do
          while i <= j && cmp.call(data[a], data[i]) >= 0
            i += 1
          end
          while i <= j && cmp.call(data[a], data[j]) < 0
            j -= 1
          end
          break if i > j

          data[i], data[j] = data[j], data[i]
          i += 1
          j -= 1
        end

        i
      end

      private def self.partial_insertion_sort(data : Array(T), a : Int32, b : Int32, cmp : Proc(T, T, Int32)) : Bool forall T
        i = a + 1

        MAX_STEPS.times do
          while i < b && cmp.call(data[i], data[i - 1]) >= 0
            i += 1
          end

          return true if i == b
          return false if b - a < SHORTEST_SHIFTING

          data[i], data[i - 1] = data[i - 1], data[i]

          if i - a >= 2
            j = i - 1
            while j >= 1
              break if cmp.call(data[j], data[j - 1]) >= 0

              data[j], data[j - 1] = data[j - 1], data[j]
              j -= 1
            end
          end

          if b - i >= 2
            j = i + 1
            while j < b
              break if cmp.call(data[j], data[j - 1]) >= 0

              data[j], data[j - 1] = data[j - 1], data[j]
              j += 1
            end
          end
        end

        false
      end

      private def self.break_patterns(data : Array(T), a : Int32, b : Int32) : Nil forall T
        length = b - a
        return if length < BREAK_PATTERNS_LENGTH

        random = Xorshift.new(length.to_u64)
        modulus = next_power_of_two(length)
        idx = a + (length // 4) * 2 - 1
        last = a + (length // 4) * 2 + 1

        while idx <= last
          other = (random.next_value & (modulus - 1).to_u64).to_i32
          other -= length if other >= length
          data[idx], data[a + other] = data[a + other], data[idx]
          idx += 1
        end
      end

      private def self.choose_pivot(data : Array(T), a : Int32, b : Int32, cmp : Proc(T, T, Int32)) : {Int32, SortedHint} forall T
        l = b - a
        swaps = 0
        i = a + (l // 4) * 1
        j = a + (l // 4) * 2
        k = a + (l // 4) * 3

        if l >= BREAK_PATTERNS_LENGTH
          if l >= SHORTEST_NINTHER
            i, swaps = median_adjacent(data, i, swaps, cmp)
            j, swaps = median_adjacent(data, j, swaps, cmp)
            k, swaps = median_adjacent(data, k, swaps, cmp)
          end
          j, swaps = median(data, i, j, k, swaps, cmp)
        end

        hint = case swaps
               when 0
                 SortedHint::Increasing
               when MAX_SWAPS
                 SortedHint::Decreasing
               else
                 SortedHint::Unknown
               end
        {j, hint}
      end

      private def self.order2(data : Array(T), a : Int32, b : Int32, swaps : Int32, cmp : Proc(T, T, Int32)) : {Int32, Int32, Int32} forall T
        if cmp.call(data[b], data[a]) < 0
          {b, a, swaps + 1}
        else
          {a, b, swaps}
        end
      end

      private def self.median(data : Array(T), a : Int32, b : Int32, c : Int32, swaps : Int32, cmp : Proc(T, T, Int32)) : {Int32, Int32} forall T
        a, b, swaps = order2(data, a, b, swaps, cmp)
        b, _, swaps = order2(data, b, c, swaps, cmp)
        _, b, swaps = order2(data, a, b, swaps, cmp)
        {b, swaps}
      end

      private def self.median_adjacent(data : Array(T), a : Int32, swaps : Int32, cmp : Proc(T, T, Int32)) : {Int32, Int32} forall T
        median(data, a - 1, a, a + 1, swaps, cmp)
      end

      private def self.reverse_range(data : Array(T), a : Int32, b : Int32) : Nil forall T
        i = a
        j = b - 1
        while i < j
          data[i], data[j] = data[j], data[i]
          i += 1
          j -= 1
        end
      end
    end
  end
end
