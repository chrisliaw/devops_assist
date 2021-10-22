

RSpec.describe DevopsAssist::ReleaseLogger do

  after(:each) do
    subject.reset_log
  end

  it 'log release versions' do
    
    rl = subject.class.load
    expect(rl).not_to be_nil
    expect(rl.releases).to be_empty

    rl.log_release(:testing, "0.1.0") do |ops|
      case ops
      when :released_by
        "john"
      when :released_location
        "Paris"
      end
    end


    expect(rl.is_version_exist?("0.1")).to be true
    expect(rl.is_version_exist?("0.2")).to be false
    expect(rl.last_version_number == "0.1.0").to be true

    rl.log_release(:testing, "0.2.0") do |ops|
      case ops
      when :released_by
        "jack"
      when :released_location
        "London"
      end
    end

    expect { rl.log_release(:testing, "0.2") }.to raise_exception(DevopsAssist::ReleaseLogError)
    expect(rl.last_version_number == "0.2.0").to be true

  end

end
