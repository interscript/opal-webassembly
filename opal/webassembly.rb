require 'native'

require 'webassembly/instance'
require 'webassembly/module'
require 'webassembly/table'
require 'webassembly/memory'
require 'webassembly/global'

module WebAssembly
  @libs = {}

  def self.libs
    @libs
  end

  def self.load_from_buffer(buffer, name)
    begin
      mod = Module.new(buffer)
      @libs[name] = Instance.new(mod)
      loaded(name)
    rescue CantLoadSyncError
      # We are in Chromium which disallows loading a module synchronously
      %x{
        WebAssembly.instantiate(#{buffer}).then(function(d) {
          #{
            @libs[name] = `d.instance`
            loaded(name)
          }
        })
      }
    end
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

  @waiting_for = []

  def self.wait_for(*libs, &block)
    prom = nil
    unless block_given?
      prom = `new Promise(function(ok, fail) {
        #{
          block = `ok`
        }
      })`
    end

    if libs.all? { |lib| @libs[lib] }
      yield
    else
      @waiting_for << [libs, block]
    end

    prom
  end

  def self.loaded(lib)
    @waiting_for.each do |libs, block|
      if libs.all? { |lib| @libs[lib] }
        block.()
      end
    end
  end

  def self.[](name)
    self.libs[name]
  end
end
