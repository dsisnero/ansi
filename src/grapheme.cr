module Ansi
  # UAX #29 extended grapheme cluster segmentation, ported from the splitter in
  # `github.com/clipperhouse/uax29/v2@v2.7.0` (the segmenter the vendored Go
  # source uses) over the property tables vendored in `src/gcb.cr`.
  #
  # The `textseg` shard was dropped here: its state machine is single-slot, so a
  # Prepend, a control or an illegal byte reset the state it was tracking and the
  # boundaries after them differed from Go (Prepend runs, Hangul jamo, extended
  # pictographic sequences, regional indicator parity). This splitter keeps the
  # four pieces of state uax29 keeps and applies the same rules in the same order,
  # so a boundary is the one Go finds.
  #
  # GB9c (Indic conjuncts) is on by default, matching `StringWidth` and the
  # pinned Go source. Pass `incb: false` for the older boundaries
  # `github.com/rivo/uniseg` produces, which is what Go's terminal input decoders
  # see: there a virama ends its segment. The property tables in `src/gcb.cr` come
  # from the same uax29 release, so both modes are table-driven.
  module Grapheme
    # GB9c `Consonant [Extend Linker]* Linker [Extend Linker]* x Consonant`.
    private enum IncbState
      None
      Consonant
      Linker
    end

    # Returns the exclusive end offset of the cluster that starts at *offset*:
    # one `Next()` of uax29's iterator, which is also what Go's per-cluster
    # `FirstGraphemeCluster` runs.
    #
    # Pass `incb: false` for the older, GB9c-free segmentation that
    # `github.com/rivo/uniseg` (and therefore Go's input decoders) produces:
    # without GB9c a virama ends its segment, so "\u0938\u094d\u0924\u0947" is
    # two segments instead of one. Terminal decoders need that split to emit one
    # key per code point sequence; width measurement needs the join.
    #
    # The rule ladder is the behavior; folding it into helpers would obscure the
    # UAX #29 ordering, which is what decides a boundary.
    # ameba:disable Metrics/CyclomaticComplexity
    def self.cluster_end(bytes : Bytes, offset : Int32, incb : Bool = true) : Int32
      size = bytes.size
      return offset if offset < 0 || offset >= size

      current, width = GCB.lookup(bytes, offset)
      # An encoding cut short by the end of the input cannot be segmented:
      # uax29 takes the rest of the buffer as the final cluster.
      return size if width == 0

      pos = offset + width
      last_ex_ignore = 0_u32
      last_last_ex_ignore = 0_u32
      regional_run = 0
      incb_state = IncbState::None

      while pos < size
        last = current
        # uax29 skips _Extend when remembering the previous two, for GB11.
        if (last & GCB::Extend) == 0
          last_last_ex_ignore = last_ex_ignore
          last_ex_ignore = last
        end
        incb_state = fold_incb(incb_state, last) if incb

        current, width = GCB.lookup(bytes, pos)
        return size if width == 0

        # No rule can apply when neither side has a property.
        break if (current | last) == 0

        # GB3
        if (current & GCB::LF) != 0 && (last & GCB::CR) != 0
          pos += width
          next
        end

        # GB4, GB5
        break if ((current | last) & (GCB::Control | GCB::CR | GCB::LF)) != 0

        # GB6
        if (current & (GCB::L | GCB::V | GCB::LV | GCB::LVT)) != 0 && (last & GCB::L) != 0
          pos += width
          next
        end

        # GB7
        if (current & (GCB::V | GCB::T)) != 0 && (last & (GCB::LV | GCB::V)) != 0
          pos += width
          next
        end

        # GB8
        if (current & GCB::T) != 0 && (last & (GCB::LVT | GCB::T)) != 0
          pos += width
          next
        end

        # GB9
        if (current & (GCB::Extend | GCB::ZWJ)) != 0
          pos += width
          next
        end

        # GB9a
        if (current & GCB::SpacingMark) != 0
          pos += width
          next
        end

        # GB9b
        if (last & GCB::Prepend) != 0
          pos += width
          next
        end

        # GB9c (skipped in the GB9c-free/uniseg mode)
        if incb && incb_state.linker? && (current & GCB::InCBConsonant) != 0
          incb_state = IncbState::Consonant
          pos += width
          next
        end

        # GB11
        if (current & GCB::ExtendedPictographic) != 0 && (last & GCB::ZWJ) != 0 &&
           (last_last_ex_ignore & GCB::ExtendedPictographic) != 0
          pos += width
          next
        end

        # GB12, GB13
        if (current & last & GCB::RegionalIndicator) != 0
          regional_run += 1
          if regional_run.odd?
            pos += width
            next
          end
        end

        break
      end

      pos
    end

    # Folds the Indic_Conjunct_Break class of *properties* into *state*, the way
    # uax29 updates its GB9c state as it advances.
    private def self.fold_incb(state : IncbState, properties : UInt32) : IncbState
      return IncbState::None if (properties & (GCB::InCBConsonant | GCB::InCBLinker | GCB::InCBExtend)) == 0

      if (properties & GCB::InCBConsonant) != 0
        state = IncbState::Consonant unless state.linker?
      elsif (properties & GCB::InCBLinker) != 0
        state = IncbState::Linker if state.consonant? || state.linker?
      end
      state
    end
  end
end
