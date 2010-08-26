class TimeInterval
  # == Constants ============================================================
  
  MASK = (0..30).to_a.collect { |i| (1 << 31) - (1 << (30 - i)) }.freeze

  DEFAULT_SCALE = (0..30).to_a.collect { |i| [ i, MASK[i] ] }.freeze
  DEFAULT_SCALE_NAME = (0..30).to_a.freeze
  
  # == Class Methods ========================================================
  
  def self.with_definition(definition)
    scale_defn = nil
    scale_name_defn = [ ]
    
    case (definition)
    when Array
      case (definition[0])
      when String, Symbol
        definition = [ 1 ] + definition
      end
      
      scale_defn = { }
      scale_factor = 1

      definition.each_with_index do |element, i|
        case (i % 2)
        when 0
          scale_factor *= element
        when 1
          scale_defn[element] = [ MASK[scale_defn.length], scale_factor ]
          scale_name_defn << element
        end
      end
    else
      scale = [ ]

      31.times do |i|
        scale_factor = i ** definition
        if (scale_factor < (1 << 31))
          scale_defn.push([ MASK[i], scale_factor ])
          scale_name_defn << i
        end
      end
    end

    subclass = nil
    
    if (scale_defn)
      subclass = Class.new(self)

      methods = Module.new do
        define_method(:scale) do
          scale_defn
        end

        define_method(:scale_name) do
          scale_name_defn
        end
      end
      
      subclass.send(:extend, methods)
    end
    
    subclass or self
  end
  
  def self.interval_to_i(value)
    value = value.to_i

    if (value < 0)
      value = -value
      
      index = (0..30).to_a.reverse.detect do |i|
        MASK[i] == value & MASK[i]
      end

      value = (value ^ MASK[index]) * scale[scale_name[index]][1]
    end
    
    value
  end
  
  def self.scale
    DEFAULT_SCALE
  end
  
  def self.scale_name
    DEFAULT_SCALE_NAME
  end

  def self.size(at_scale = nil)
    scale_details = scale[at_scale || scale_name[0]]
    
    scale_details and scale_details[1]
  end

  def self.now
    new(nil)
  end
  
  # == Instance Methods =====================================================

  def initialize(value = nil)
    @time = self.class.interval_to_i(value || Time.now.utc)
  end
  
  def to_i(at_scale = nil)
    case (at_scale)
    when nil
      @time
    else
      scale_details = self.class.scale[at_scale]
      
      -(scale_details[0] | (@time / scale_details[1]))
    end
  end
end
