# frozen_string_literal: true
require 'spec_helper'

describe Rails.application do
  it 'responds to google_analytics_id' do
    expect(subject).to respond_to(:google_analytics_id)
  end
  it 'has the proper google analytics id' do
    allow(Socket).to receive(:gethostname).and_return('ss1prod')
    expect(subject.google_analytics_id).to eq('UA-33252017-2')
  end
end
