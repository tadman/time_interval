require 'helper'

class TestTimeInterval < Test::Unit::TestCase
  def test_mask_integrity
    assert_equal TimeInterval::MASK.length, TimeInterval::MASK.uniq.length
  end

  def test_default_state
    interval = TimeInterval.new
    
    assert_equal interval.to_i, Time.now.to_i
  end

  def test_custom_interval
    # Create a custom interval with a simple definition based on the regular
    # calendar.

    interval_type = TimeInterval.with_definition(
      [ :second, 60, :minute, 60, :hour, 24, :day, 7, :week ]
    )
    
    assert_equal 5, interval_type.scale.length

    assert_equal 1, interval_type.size
    assert_equal 1, interval_type.size(:second)
    assert_equal 60, interval_type.size(:minute)
    assert_equal 60 * 60, interval_type.size(:hour)
    assert_equal 24 * 60 * 60, interval_type.size(:day)
    assert_equal 7 * 24 * 60 * 60, interval_type.size(:week)
    
    # Construct a series of expectations by multiplying out into the
    # required numbre of seconds.
    weeks = 5
    days = 4 + weeks * 7
    hours = 3 + days * 24
    minutes = 2 + hours * 60
    seconds = 1 + minutes * 60
    
    # Create an interval with this value
    interval = interval_type.new(seconds)
    
    assert interval
    
    # When accessed using the default #to_i conversion method, the value
    # returned should be seconds since epoch.
    assert_equal seconds, interval.to_i
    
    # Different interval slices can be obtained by passing in the name from
    # the definition.
    assert_equal -(TimeInterval::MASK[0] | seconds), interval.to_i(:second)
    assert_equal -(TimeInterval::MASK[1] | minutes), interval.to_i(:minute)
    assert_equal -(TimeInterval::MASK[2] | hours), interval.to_i(:hour)
    assert_equal -(TimeInterval::MASK[3] | days), interval.to_i(:day)
    assert_equal -(TimeInterval::MASK[4] | weeks), interval.to_i(:week)
    
    # These times can be decoded to a value approximately equal to the
    # original, losing granularity where it has been masked out.
    
    assert_equal weeks * 7 * 24 * 60 * 60, interval_type.new(interval.to_i(:week)).to_i
    assert_equal days * 24 * 60 * 60, interval_type.new(interval.to_i(:day)).to_i
    assert_equal hours * 60 * 60, interval_type.new(interval.to_i(:hour)).to_i
    assert_equal minutes * 60, interval_type.new(interval.to_i(:minute)).to_i
    assert_equal seconds, interval_type.new(interval.to_i(:second)).to_i
  end
end
