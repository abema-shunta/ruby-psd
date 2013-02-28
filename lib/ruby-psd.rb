class RubyPSD

  # Official documents of PSD File Format is here. 
  # http://www.adobe.com/devnet-apps/photoshop/fileformatashtml/PhotoshopFileFormats.htm#50577409_20023

  def initialize(path)
    @path = path
    @width = 0
    @height = 0
    @layers = []
  end
  attr_accessor :width, :height, :layers
    
  def get_file_header 
  [
    [0x38, 0x42, 0x50, 0x53], # Signature[4] : 8BPS
    [0x00, 0x01], #Version[2] : always it's must be 1
    [0x00, 0x00, 0x00, 0x00, 0x00, 0x00],  #Reserved[6]
    [0x00, 0x04], # The number of channels in the image, Usually it's RGBA so it will be 4 
    num2bytes(@height, 4), # Height[4]
    num2bytes(@width, 4), # Width[4]
    [0x00, 0x08], #Depth[2]: the number of bits per channel. Supported values are 1, 8, 16 and 32. opted 8bit as default.
    [0x00, 0x03] #ColorMode: opted RGB Mode(3) as default. 
  ].flatten.pack("C*")
  end
  
  def get_color_mode_data
    # I'm not sure about this specs so I makes it as only 4 byte length of zero
    [0x00, 0x00, 0x00, 0x00].pack("C*")
  end

  def get_image_resources
    # I'm not sure about this specs so I makes it as only 4 byte length of zero
    [0x00, 0x00, 0x00, 0x00].pack("C*")
  end

  def get_layer_and_mask_information
    
    layer_info = get_layer_info
    global_layer_info = get_global_layer_info
    additional_layer_info = get_additional_layer_info
    size_of_layer_and_mask_information = layer_info.size + global_layer_info.size + additional_layer_info.size
    
    [
      num2bytes(size_of_layer_and_mask_information, 4),
      layer_info,
      global_layer_info,
      additional_layer_info
    ].flatten.pack("C*")
    
  end
  
  def get_layer_info
    
    _LAYER_COUNT_LENGTH = 2
    layer_counts = get_layer_counts
    layer_records = get_layer_records
    channel_image_data = get_channel_image_data(layer_counts)
    
    size_of_layer_info = _LAYER_COUNT_LENGTH + layer_records.size + channel_image_data.size
    
    [
      num2bytes(size_of_layer_info, 4),
      num2bytes(layer_counts, 2),
      layer_records,
      channel_image_data
    ].flatten
    
  end
  
  def get_layer_counts
    # 1 is the count of default art layer named "background"
    1 + (get_key_nums @layers) * 2
  end
  
  def get_key_nums(layers)
    ret = layers.size
    layers.each do |v|
      if v.class == Array
        ret += get_key_nums(v) - 1 
      end
    end
    ret
  end
  
  def get_layer_records
    art_layer_record = get_art_layer_record
    layers_array = convert_layers_to_array(@layers)
    group_layer_records = layers_array.map do |name|
      get_group_layer_record name
    end
    [art_layer_record, group_layer_records].flatten
  end
  
  def get_art_layer_record
    get_layer_record "background", []    
  end
  
  def convert_layers_to_array(arr)
    def pick_up_from_array(ar, prev = nil)
      ret = []
      ar.each_with_index do |a, i|
        if a.class == Array
          ret += pick_up_from_array(a)
          if prev != nil and ar[i+1].class != Array
            ret << "</Layer group>"
            prev = nil
          end
        else
          if prev != nil
            ret << "</Layer group>"
          end
          ret << a
          prev = a
        end
      end
      ret << "</Layer group>" if prev != nil
      ret
    end
    (pick_up_from_array arr).flatten.reverse
  end
  
  def get_group_layer_record(name)
    if name == "</Layer group>"
      additional_data = [
        [0x38, 0x42, 0x49, 0x4D], # Blend mode signature: '8BIM'
        [0x6c, 0x73, 0x63, 0x74], # Section divider setting 'lscr'
        [0x00, 0x00, 0x00, 0x04], # Length of this additional record
        [0x00, 0x00, 0x00, 0x03]  # Type. This is 3 = bounding section divider.
      ]
    else
      additional_data = [
        [0x38, 0x42, 0x49, 0x4D], # Blend mode signature: '8BIM'
        [0x6c, 0x73, 0x63, 0x74], # Section divider setting 'lscr'
        [0x00, 0x00, 0x00, 0x0c], # Length of this additional record. It might be 12.
        [0x00, 0x00, 0x00, 0x01], # Type. This is 1 = bounding section divider.
        # Following is only present if length = 12
        [0x38, 0x42, 0x49, 0x4D], # Blend mode signature: '8BIM'
        [0x70, 0x61, 0x73, 0x73], # Blend mode key: 'pass'   
      ]    
    end
    get_layer_record name, additional_data.flatten
  end
  
  def get_layer_record (name, additional_data)
    
    pascal_name = get_pascal_name(name, 4)
    size_of_additional_data = 8 + pascal_name.size + additional_data.size
    [
      [0x00] * 16, #Rectangle containing the contents of the layer
      [0x00, 0x04], #Number of channels in the layer ( Usually it will be 4 as RGBA )
      # Channel information. Six bytes per channel, consisting of: 2 bytes for Channel ID
      # 4 bytes for length of corresponding channel data
      [0xFF, 0xFF] + [0x00, 0x00, 0x00, 0x02], #-1 = transparency
      [0x00, 0x00] + [0x00, 0x00, 0x00, 0x02], #0 = red
      [0x00, 0x01] + [0x00, 0x00, 0x00, 0x02], #1 = green
      [0x00, 0x02] + [0x00, 0x00, 0x00, 0x02], #2 = blue
      [0x38, 0x42, 0x49, 0x4D], # Blend mode signature: '8BIM'
      [0x6E, 0x6F, 0x72, 0x6D], # Blend mode key: 'norm'
      [0xFF], #Opacity. 0 = transparent ... 255 = opaque
      [0x00], #Clipping: 0 = base, 1 = non-base
      [0x08], #Flags: [00001000]
              #  bit 0 = transparency protected; 
              #  bit 1 = visible; 
              #  bit 2 = obsolete;
              #  bit 3 = 1 for Photoshop 5.0 and later, tells if bit 4 has useful information;
              #  bit 4 = pixel data irrelevant to appearance of document
      [0x00], #  Just Filler (zero)
      num2bytes(size_of_additional_data, 4),
      [0x00] * 4, # Layer mask data. It won't be.
      [0x00] * 4, # Layer blending ranges. It won't be.
      pascal_name,
      additional_data
    ].flatten
    
  end
  
  def get_pascal_name(name, padding)
    arr = name.unpack("C*")
    arr = [arr.size] + arr
    if ((arr.size % padding) > 0) 
      arr += ([0] * (padding - (arr.size % padding))) 
    end
    arr
  end
  
  def get_channel_image_data(layer_count)
    [0x00] * 8 * layer_count
  end
  
  def get_global_layer_info
    [0x00] * 4
  end
  
  def get_additional_layer_info
    []
  end
  
  def get_image_data
    image_data = generate_image_data
    [
      [0x00, 0x01],
      image_data # Compression method: 1 = RLE compressed the image data starts with the byte 
    ].flatten.pack("C*")
  end
  
  def generate_image_data
    
    packet = get_packet_bytes(@width)
    channels = 4
    [
      [0x00, 0x00] * @height * channels,
      packet * @height * channels
    ]

  end
  
  def get_packet_bytes(width)
    divided = width / 128
    remainder = width % 128
    ret = []
    [divided, remainder]
    divided.times do
      ret << [0x101 - 128, 0xFF]
    end
    ret << [0x101 - remainder, 0xFF]
    ret.flatten
  end
  
  def generate
    psd = open @path, "w"
    psd.print get_file_header
    psd.print get_color_mode_data
    psd.print get_image_resources
    psd.print get_layer_and_mask_information
    psd.print get_image_data
    psd.close
  end
  
  def output_psd
  end
  
  def num2bytes (num, size)
    num.to_s(16).rjust(size*2,"0").unpack("a2"*(size)).map{|a| "0x#{a}".to_i(16)}
  end
  
end


