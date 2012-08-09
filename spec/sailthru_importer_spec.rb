require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "SailthruImporter" do
  

  context ".api_key" do
    it "sets its api_key" do
      SailthruImporter.api_key = "test"
      SailthruImporter.api_key.should eql("test")
    end
  end

  context ".api_secret" do
    it "sets its api_secret" do
      SailthruImporter.api_secret = "test"
      SailthruImporter.api_secret.should eql("test")
    end
  end

  context ".base_file_name" do
    it "should be configurable and based on the process id" do
      SailthruImporter.file_root = "/tmp"
      SailthruImporter.base_file_name.should eql(
        "/tmp/#{Process.pid}-sailthru-list"
      )
    end
  end

  context ".batch_size" do
    it "should default to 10_000_000" do
      SailthruImporter.batch_size.should eql(10000000)
    end

    it "should be configurable" do
      SailthruImporter.batch_size = 1
      SailthruImporter.batch_size.should eql(1)
    end
  end

  context ".client" do
    it "initializes a new SailthruClient" do
      SailthruImporter.api_key = "key"
      SailthruImporter.api_secret = "secret"

      Sailthru::SailthruClient.expects(:new).with(
        "key", "secret", "https://api.sailthru.com"
      )

      SailthruImporter.client
    end
  end

  context ".method_missing" do

    it "should proxy all other methods to method_missing" do
      SailthruImporter.client.expects(:api_post).with("abc")
      SailthruImporter.api_post("abc")
    end

  end

  context ".update_users" do

    before(:each) do
      SailthruImporter.batch_size = 10000000
    end

    after(:each) do
      SailthruImporter.clear_tmp_files
    end

    it "should write a file to sailthru" do

      args = [
        :job,
        {"job" => "update", "file" => "/tmp/#{Process.pid}-sailthru-list.0"},
        "file"
      ]

      SailthruImporter.expects(:api_post)
        .with(*args)
        .returns({"job_id" => "213"})

      SailthruImporter.update_users(
        [{"email" => "dan.langevin@gmail.com"}],
        false
      )

      File.read("/tmp/#{Process.pid}-sailthru-list.0").should eql(
        JSON.unparse({"email" => "dan.langevin@gmail.com"}) + "\n"
      )

    end

  end

end
