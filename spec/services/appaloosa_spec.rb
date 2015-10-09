require 'spec_helper'

describe Service::Appaloosa do

  let(:web_hook_url) { 'https://www.appaloosa-store.com/123-fake-store/mobile_applications/456/issues?application_token=4d9b0a249ff0b82d47ab12394edd64c202d32edb6d9c44e5993bb38a8be345ca' }

  it 'has a title' do
    expect(Service::Appaloosa.title).to eq('Appaloosa')
  end

  describe 'schema and display configuration' do
    subject { Service::Appaloosa }

    it { is_expected.to include_string_field :url }

    it { is_expected.to include_page 'URL', [:url] }
  end

  describe 'receive_verification' do
    before do
      @config = { url: web_hook_url }
      @service = Service::Appaloosa.new('verification', {})
      @payload = {}
    end

    it 'should succeed upon successful api response' do
      test = Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.post('/') { [200, {}, ''] }
        end
      end

      expect(@service).to receive(:http_post)
        .with(web_hook_url)
        .and_return(test.post('/'))

      resp = @service.receive_verification(@config, @payload)
      expect(resp).to eq([true,  "Successfully sent a message to Appaloosa"])
    end

    it 'should fail upon unsuccessful api response' do
      [500, 401, 403].each do |status_code| 
        test = Faraday.new do |builder|
          builder.adapter :test do |stub|
            stub.post('/') { [status_code, {}, ''] }
          end
        end

        expect(@service).to receive(:http_post)
          .with(web_hook_url)
          .and_return(test.post('/'))

        resp = @service.receive_verification(@config, @payload)
        expect(resp).to eq([false, "Could not send a message to Appaloosa"])
      end
    end
  end

  describe 'receive_issue_impact_change' do
    before do
      @config = { :url => web_hook_url }
      @service = Service::Appaloosa.new('issue_impact_change', {})
      @payload = {
        :title => 'title',
        :impact_level => 1,
        :impacted_devices_count => 1,
        :crashes_count => 1,
        :app => {
          :name => 'name',
          :bundle_identifier => 'foo.bar.baz'
        }
      }
    end

    it 'should succeed upon successful api response' do
      test = Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.post('/') { [201, {}, ''] }
        end
      end

      expect(@service).to receive(:http_post)
        .with(web_hook_url)
        .and_return(test.post('/'))

      resp = @service.receive_issue_impact_change(@config, @payload)
      expect(resp).to eq(:no_resource)
    end

    it 'should fail with extra information upon unsuccessful api response' do
      test = Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.post('/') { [500, {}, 'fake_body'] }
        end
      end

      expect(@service).to receive(:http_post)
        .with(web_hook_url)
        .and_return(test.post('/'))

      expect {
        @service.receive_issue_impact_change(@config, @payload)
      }.to raise_error(/Appaloosa WebHook issue create failed: HTTP status code: 500, body: fake_body/)
    end
  end
end
