require 'asana'
require 'spec_helper'

describe Service::FogBugz do

  it 'has a title' do
    expect(Service::FogBugz.title).to eq('FogBugz')
  end

  describe 'schema and display configuration' do
    subject { Service::FogBugz }

    it { is_expected.to include_string_field :project_url }
    it { is_expected.to include_string_field :api_token }

    it { is_expected.to include_page 'API Token', [:project_url, :api_token] }
  end

  context 'with service' do
    let(:service) { Service::FogBugz.new('event_name', {}) }
    let(:config) do
      {
        :api_key => 'key',
        :project_url => 'https://yourproject.fogbugz.com'
      }
    end
    let(:payload) do
      {
        :title => 'foo title',
        :method => 'method name',
        :impact_level => 1,
        :impacted_devices_count => 1,
        :crashes_count => 1,
        :app => {
          :name => 'foo name',
          :bundle_identifier => 'foo.bar.baz'
        },
        :url => 'http://foo.com/bar'
      }
    end
    let(:error_response) { '<response><error code="0"></error></response>' }
    let(:invalid_response) { '' }

    describe :receive_verification do
      let(:success_response) { '<response><projects></projects></response>' }

      it 'succeeds given a valid response' do
        expect(service).to receive(:http_get).and_return(double(Faraday::Response, :body => success_response))
        response = service.receive_verification(config, nil)
        expect(response).to eq([true, 'Successfully verified Fogbugz settings'])
      end

      it 'fails given an error response' do
        expect(service).to receive(:http_get).and_return(double(Faraday::Response, :body => error_response))
        response = service.receive_verification(config, nil)
        expect(response).to eq([false, 'Oops! Please check your API key again.'])
      end

      it 'fails given an invalid response' do
        expect(service).to receive(:http_get).and_return(double(Faraday::Response, :body => invalid_response))
        response = service.receive_verification(config, nil)
        expect(response).to eq([false, 'Oops! Please check your API key again.'])
      end
    end

    describe :receive_issue_impact_change do
      let(:case_id) { "1" }
      let(:success_response) { "<response><case ixBug='#{case_id}'></case></response>" }

      it 'creates a new case given a valid response' do
        expect(service).to receive(:http_post).and_return(double(Faraday::Response, :body => success_response))
        response = service.receive_issue_impact_change(config, payload)
        expect(response).to eq({ :fogbugz_case_number => case_id })
      end

      it 'raises an exception given an error response' do
        expect(service).to receive(:http_post).and_return(double(Faraday::Response, :body => error_response))
        expect { service.receive_issue_impact_change(config, payload) }.to raise_error(/Could not create FogBugz/)
      end

      it 'raises an exception given an invalid response' do
        expect(service).to receive(:http_post).and_return(double(Faraday::Response, :body => invalid_response))
        expect { service.receive_issue_impact_change(config, payload) }.to raise_error(/Could not create FogBugz/)
      end
    end
  end
end
