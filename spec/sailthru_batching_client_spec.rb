require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "SailthruBatchingClient" do
  

  context ".api_key" do
    it "sets its api_key" do
      SailthruBatchingClient.api_key = "test"
      SailthruBatchingClient.api_key.should eql("test")
    end
  end

  context ".api_secret" do
    it "sets its api_secret" do
      SailthruBatchingClient.api_secret = "test"
      SailthruBatchingClient.api_secret.should eql("test")
    end
  end

  context ".base_file_name" do
    it "should be configurable and based on the process id" do
      SailthruBatchingClient.file_root = "/tmp"
      SailthruBatchingClient.base_file_name.should eql(
        "/tmp/#{Process.pid}-sailthru-list"
      )
    end
  end

  context ".batch_size" do
    it "should default to 10_000_000" do
      SailthruBatchingClient.batch_size.should eql(10000000)
    end

    it "should be configurable" do
      SailthruBatchingClient.batch_size = 1
      SailthruBatchingClient.batch_size.should eql(1)
    end
  end

  context ".client" do
    it "initializes a new SailthruClient" do
      SailthruBatchingClient.api_key = "key"
      SailthruBatchingClient.api_secret = "secret"

      Sailthru::SailthruClient.expects(:new).with(
        "key", "secret", "https://api.sailthru.com"
      )

      SailthruBatchingClient.client
    end
  end

  context ".method_missing" do

    it "should proxy all other methods to method_missing" do
      SailthruBatchingClient.client.expects(:api_post).with("abc")
      SailthruBatchingClient.api_post("abc")
    end

  end

  context ".update_users" do

    before(:each) do
      SailthruBatchingClient.batch_size = 10000000
    end

    after(:each) do
      SailthruBatchingClient.clear_tmp_files
    end

    it "should write a file to sailthru" do

      args = [
        :job,
        {"job" => "update", "file" => "/tmp/#{Process.pid}-sailthru-list.0"},
        "file"
      ]

      SailthruBatchingClient.expects(:api_post)
        .with(*args)
        .returns({"job_id" => "213"})

      SailthruBatchingClient.update_users(
        [{"email" => "dan.langevin@gmail.com"}],
        false
      )

      File.read("/tmp/#{Process.pid}-sailthru-list.0").should eql(
        JSON.unparse({"email" => "dan.langevin@gmail.com"}) + "\n"
      )

    end

  end

end
