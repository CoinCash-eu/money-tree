require 'openssl'

module MoneyTree
  module Support
    INT32_MAX = 256 ** [1].pack("L*").size
    INT64_MAX = 256 ** [1].pack("Q*").size
    
    def int_to_base58(int_val, leading_zero_bytes=0)
      alpha = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
      base58_val, base = '', alpha.size
      while int_val > 0
        int_val, remainder = int_val.divmod(base)
        base58_val = alpha[remainder] + base58_val
      end
      base58_val
    end

    def base58_to_int(base58_val)
      alpha = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
      int_val, base = 0, alpha.size
      base58_val.reverse.each_char.with_index do |char,index|
        raise ArgumentError, 'Value not a valid Base58 String.' unless char_index = alpha.index(char)
        int_val += char_index*(base**index)
      end
      int_val
    end

    def encode_base58(hex)
      leading_zero_bytes  = (hex.match(/^([0]+)/) ? $1 : '').size / 2
      ("1"*leading_zero_bytes) + int_to_base58( hex.to_i(16) )
    end

    def decode_base58(base58_val)
      s = base58_to_int(base58_val).to_s(16); s = (s.bytesize.odd? ? '0'+s : s)
      s = '' if s == '00'
      leading_zero_bytes = (base58_val.match(/^([1]+)/) ? $1 : '').size
      s = ("00"*leading_zero_bytes) + s  if leading_zero_bytes > 0
      s
    end
    alias_method :base58_to_hex, :decode_base58
    
    def to_serialized_base58(hex)
      hash = sha256 hex
      hash = sha256 hash
      checksum = hash.slice(0..7)
      address = hex + checksum
      encode_base58 address
    end
    
    def sha256(source, opts = {})
      source = [source].pack("H*") unless opts[:ascii]
      bytes_to_hex OpenSSL::Digest::SHA256.digest(source)
    end
    
    def ripemd160(source, opts = {})
      source = [source].pack("H*") unless opts[:ascii]
      bytes_to_hex OpenSSL::Digest::RIPEMD160.digest(source)
    end
    
    def encode_base64(hex)
      [[hex].pack("H*")].pack("m0")
    end
    
    def decode_base64(base64)
      base64.unpack("m0").unpack("H*")
    end
    
    def hmac_sha512(key, message)
      digest = OpenSSL::Digest::SHA512.new
      OpenSSL::HMAC.digest digest, key, message
    end
    
    def hmac_sha512_hex(key, message)
      md = hmac_sha512(key, message)
      md.unpack("H*").first.rjust(64, '0')
    end
    
    def bytes_to_int(bytes, base = 16)
      # bytes = bytes.bytes unless bytes.respond_to?(:inject)
      # bytes.inject {|a, b| (a << 8) + b }
      if bytes.is_a?(Array)
        bytes = bytes.pack("C*")
      end
      bytes.unpack("H*")[0].to_i(16)
    end
    
    def int_to_hex(i)
      hex = i.to_s(16)
      hex = '0' + hex unless (hex.length % 2).zero?
      hex.downcase
    end
    
    def int_to_bytes(i)
      [int_to_hex(i)].pack("H*")
    end
    
    def bytes_to_hex(i)
      i.unpack("H*")[0].downcase
    end
    
    def hex_to_bytes(i)
      [i].pack("H*")
    end
    
    def hex_to_int(i)
      bytes_to_int(hex_to_bytes(i))
    end
  end
end