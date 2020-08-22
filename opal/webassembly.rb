require 'native'

require 'webassembly/instance'
require 'webassembly/module'

module WebAssembly
  @libs = {}

  def self.libs
    @libs
  end

  def self.load_from_buffer(buffer, name)
    mod = Module.new(buffer)
    @libs[name] = Instance.new(mod)
  end

  %x{
    // Taken from https://github.com/niklasvh/base64-arraybuffer/blob/master/lib/base64-arraybuffer.js
    var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // Use a lookup table to find the index.
    var lookup = new Uint8Array(256);
    for (var i = 0; i < chars.length; i++) {
      lookup[chars.charCodeAt(i)] = i;
    }

    function base64_to_arraybuffer(base64) {
      var bufferLength = base64.length * 0.75,
      len = base64.length, i, p = 0,
      encoded1, encoded2, encoded3, encoded4;

      if (base64[base64.length - 1] === "=") {
        bufferLength--;
        if (base64[base64.length - 2] === "=") {
          bufferLength--;
        }
      }

      var arraybuffer = new ArrayBuffer(bufferLength),
      bytes = new Uint8Array(arraybuffer);

      for (i = 0; i < len; i+=4) {
        encoded1 = lookup[base64.charCodeAt(i)];
        encoded2 = lookup[base64.charCodeAt(i+1)];
        encoded3 = lookup[base64.charCodeAt(i+2)];
        encoded4 = lookup[base64.charCodeAt(i+3)];

        bytes[p++] = (encoded1 << 2) | (encoded2 >> 4);
        bytes[p++] = ((encoded2 & 15) << 4) | (encoded3 >> 2);
        bytes[p++] = ((encoded3 & 3) << 6) | (encoded4 & 63);
      }

      return arraybuffer;
    }
  }

  def self.load_from_base64(base64, name)
    self.load_from_buffer(`base64_to_arraybuffer(#{base64})`, name)
  end

  def self.[](name)
    self.libs[name]
  end
end
