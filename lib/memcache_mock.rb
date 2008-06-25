class MemCacheMock
  attr_writer :namespace
  
  def initialize
    @data = {}
    @expiry = {}
    @auto_clear = false
  end
  
  def namespace
    @namespace.to_s
  end
  
  def cache_key(key)
    "#{namespace}:#{key}"
  end

  # Note:  This doesn't work exactly like memcache's incr
  # because MemCacheMock doesn't support raw storage.
  # This version will work on marshalled data.
  # This is also not atomic.
  def incr(key, amount=1)
    oldval = get(key).to_i or return nil
    newval = oldval + amount
    set(key, newval) # Note: Loses the expiry.
    return newval
  end

  def decr(key, amount=1)
    incr(key, amount * -1)
  end
  
  def set(*args)
    do_set(*args)
  end

  # Note:  Raw not implemented.
  def do_set(key, value, expiry = 0, raw=false)
    return '' if @auto_clear
    key = cache_key(key)

    @data[key] = Marshal.dump(value)
    @expiry[key] = Time.now + expiry if expiry != 0
    'STORED'
  end

  def add(key, value, expiry = 0)
    do_set(key, value, expiry) unless get(key)
  end

  def kind_of?(type)
    (type == MemCache) || super
  end
  
  def delete(key)
    key = cache_key(key)
    @data.delete(key)
  end
  
  def clear
    @data.clear
    @expiry.clear 
  end
  
  def get_multi(*keys)
    hash = {}
    keys.each do |key|
      val = get(key)
      key = cache_key(key).sub("#{namespace}:",'')
      hash[key] = val if val
    end
    hash
  end

  # Note:  Raw not implemented.
  def get(key, raw=false)
    key = cache_key(key)
    clear if @auto_clear
    if @expiry[key] and Time.now > @expiry[key]
      @data[key]   = nil
      @expiry[key] = nil
    end
    return if not @data[key]
    Marshal.load(@data[key])
  end
  
  def [](key)
    get(key)
  end

  def []=(key, value)
    set(key, value)
  end

  def empty?
    @data.empty?
  end
  
  def keys
    @data.keys
  end
  
  def auto_clear_on(&block)
    if block_given?
      auto_clear_block(true, &block)
    else
      @auto_clear = true
    end
  end
  
  def auto_clear_off(&block)
    if block_given?
      auto_clear_block(false, &block)
    else
      @auto_clear = false
    end
  end

  def auto_clear_block(value, &block)
    old_auto_clear = @auto_clear
    @auto_clear = value
    block.call
    @auto_clear = old_auto_clear
  end

end
