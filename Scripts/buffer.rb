#==============================================================================
# ** Buffer
#------------------------------------------------------------------------------
# Autor: Valentine
#==============================================================================

class Binary_Writer

  def initialize
    @write_buffer = []
    @write_pack = ''
    @write_size = 0
  end

  def write_byte(byte)
    write(byte, 'c', 1)
  end

  def write_boolean(value)
    write_byte(value ? 1 : 0)
  end

  def write_short(short)
    write(short, 's', 2)
  end

  def write_int(int)
    write(int, 'i', 4)
  end

  def write_long(long)
    # q representa um número de 64 bits, diferentemente de l que
    #representa um número de 32 bits
    write(long, 'q', 8)
  end

  def write_string(str)
    write_short(str.bytesize)
    str.each_byte { |c| write_byte(c) }
  end

  def to_s
    @write_buffer.pack(@write_pack)
  end

  private

  def write(value, format, n)
    @write_buffer << value
    @write_pack << format
    @write_size += n
  end

end

#==============================================================================
# ** Binary_Reader
#==============================================================================
class Binary_Reader

  def initialize(str)
    @read_bytes = str.bytes
    @read_pos = 0
  end

  def read_byte
    byte = @read_bytes[@read_pos]
    @read_pos += 1
    byte
  end

  def read_boolean
    read_byte == 1
  end

  def read_short
    read(2, 's')
  end

  def read_int
    read(4, 'i')
  end

  def read_long
    read(8, 'q')
  end

  def read_string
    size = read_short
    read(size, "A#{size}")
  end

  def can_read?
    @read_pos < @read_bytes.size
  end

  private

  def read(n, format)
    bytes = @read_bytes[@read_pos, @read_pos + n]
    @read_pos += n
    bytes.pack('C*').unpack(format)[0]
  end

end

#==============================================================================
# ** Buffer_Writer
#==============================================================================
class Buffer_Writer < Binary_Writer

  def to_s
    ([@write_size] + @write_buffer).pack("s#{@write_pack}")
  end

end
