require 'sailthru'

class SailthruBatchingClient

  class << self
    attr_accessor :api_key, :api_secret
    attr_writer :file_root, :batch_size
  end

  # where we store our temp files
  def self.base_file_name
    "#{self.file_root}/#{Process.pid}-sailthru-list"
  end

  # max size that Sailthru can support
  def self.batch_size
    @batch_size ||= 10000000
  end

  # clear the files we created to push data to Sailthru
  def self.clear_tmp_files
    FileUtils.rm_rf("#{self.base_file_name}*")
  end

  # instance of sailthru client
  def self.client
    @client ||= ::Sailthru::SailthruClient.new(
      self.api_key, 
      self.api_secret, 
      "https://api.sailthru.com"
    )
  end

  # We are connected if a client is present
  def self.connected?
    @client.present?
  end

  # get an instance of sailthru client
  def self.establish_connection
    self.client
  end
  
  # root at which we are going to write our temp files
  def self.file_root
    @file_root ||= "/tmp"
  end

  # override respond_to? to also include methods of our 
  # instance of SailthruClient
  def self.respond_to?(m)
    return true if super(m)
    return self.client.respond_to?(m)
  end

  # update rows of email data
  def self.update_users(user_data_array, clear_tmp = true)
    # make sure we have the dir
    FileUtils.mkdir_p(File.dirname(self.base_file_name))
    self.clear_tmp_files if clear_tmp

    begin
      self.batch_data_as_json(user_data_array).each_with_index do |rows, i| 
        # write to the file system
        file = self.write_temp_file(rows, i)
        # send our file
        self.send_file(file)
      end
      return true
    ensure
      self.clear_tmp_files if clear_tmp
    end
  end
  
  protected

  def self.batch_data_as_json(data)
    # convert to strings so we can count bytes
    data = data.collect{|r| JSON.unparse(r)}
    ret = []
    # start off 0 size and empty batch
    size = 0
    batch = []
    # iterate, breaking into batches
    data.each do |row, i|
      # get the number of bytes in our string
      size += row.bytes.to_a.inject{|sum,x| sum + x}
      # if we've gone over the limit with this row, we
      # create a new batch and reset the size to 0
      if size > self.batch_size
        ret << batch
        batch = []
        size = 0
      end
      # add our row to the current batch
      batch << row
    end
    # if we have leftover records, put them here
    ret << batch unless batch.empty?
    ret
  end

  # proxy everything else to the client
  def self.method_missing(m, *args, &block)
    self.establish_connection
    # why Sailthru, would you override "send"
    @client.__send__(m, *args, &block)
  end

  # send a file to sailthru
  def self.send_file(file)
    i = 0
    begin
      SailthruBatchingClient.api_post(
        :job,
        {"job" => "update", "file" => file},
        "file"
      )
    rescue Exception => e
      if i < 5
        i += 1
        retry
      else
        raise e
      end
    end
  end
  
  # write a temp filte for a given group so that we 
  # can push the file to sailthru
  def self.write_temp_file(group, i)
    name = "#{self.base_file_name}.#{i}"
    File.open(name, 'wb') do |f|
      group.compact.each do |row|
        f.puts(row)
      end
    end
    name
  end
end