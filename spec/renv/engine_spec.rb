require 'renv/engine'
require 'timecop'
require 'fog'

describe Renv::Engine do
  let(:tempdir)  { Pathname.new('tmp').join("%08x" % rand(1<<31)) }
  let(:name)     { 'staging' }
  let(:app_name) { 'testapp' }
  let(:data)     { Renv::Data.new }
  # let(:env) {{
  #   'RENV_APP'                => 'testapp',
  #   'RENV_AWS_KEY_testapp'    => 'key',
  #   'RENV_AWS_SECRET_testapp' => 'secret',
  #   'RENV_BUCKET_testapp'     => 'testbucket'
  # }}

  let(:connection) do
    c = Fog::Storage.new(provider: 'Local', local_root: tempdir.to_s)
    c.directories.create(key: 'testbucket')
  end

  let(:options) {{ name: name, connection: connection, data: data }}
  
  let(:default_data) { "KEY1=value1\nKEY2=value2" }

  subject { described_class.new(**options) }

  def data_for(entry, value = nil)
    path = tempdir.join("testbucket/#{name}/#{entry}")
    if value
      path.parent.mkpath
      path.write(value)
    elsif path.exist?
      path.read
    else
      nil
    end
  end

  around do |example|
    tempdir.mkpath
    example.run
    tempdir.rmtree
  end
  
  before do
    allow(connection).to receive(:app_name).and_return(app_name)
    # TODO: proper separation would use the injected Data dependency
    # and do the following instead of parsing files:
    # allow(data).to receive(:dump).and_return('dump')
  end

  before do
    data_for(:current, default_data) if default_data
  end

  shared_examples 'writer' do
    it 'creates a backup' do
      timestamp = '2014-07-30T01:23:45'
      Timecop.freeze(timestamp) { perform }
      expect(data_for(timestamp)).not_to be_nil
    end
  end

  shared_examples 'preserving existing keypairs' do
    it 'leaves existing keypairs intact' do
      data_for(:current, "#{default_data}\nPRESERVED=value\n")
      perform
      expect(data_for(:current)).to match(/^PRESERVED=value$/)
    end
  end

  shared_examples 'initial conditions' do
    let(:default_data) { nil }
    
    it 'has no initial data' do
      expect(data_for(:current)).to be_nil
    end

    it 'works with an empty bucket' do
      expect { perform }.not_to raise_error
    end
  end

  describe 'set' do
    let(:perform) { subject.set('FOO' => 'bar', 'BAZ' => 'qux') }
    it 'writes keys to file' do
      perform
      expect(data_for(:current)).to match(/^FOO=bar$/)
      expect(data_for(:current)).to match(/^BAZ=qux$/)
    end

    it_behaves_like 'writer'
    it_behaves_like 'preserving existing keypairs'
    it_behaves_like 'initial conditions'
  end

  describe 'del' do
    let(:perform) { subject.del(['KEY1']) }

    it 'deletes key from store' do
      perform
      expect(data_for(:current)).not_to match(/^KEY1=/)
    end

    it_behaves_like 'writer'
    it_behaves_like 'preserving existing keypairs'
    it_behaves_like 'initial conditions'
  end

  describe 'load' do
    let(:perform) { subject.load("FOO=bar\nBAZ=qux") }

    it 'deletes key from store' do
      perform
      expect(data_for(:current)).to match(/^FOO=bar$/)
      expect(data_for(:current)).to match(/^BAZ=qux$/)
    end

    it_behaves_like 'writer'
    it_behaves_like 'preserving existing keypairs'
    it_behaves_like 'initial conditions'
  end

  describe 'get' do
    let(:perform) { subject.get('KEY1') }

    it 'returns the value' do
      expect(perform).to eq('value1')
    end

    it_behaves_like 'preserving existing keypairs'
    it_behaves_like 'initial conditions'
  end

  describe 'dump' do
    let(:perform) { subject.dump }

    it 'returns the value' do
      expect(perform).to match(/^KEY1=value1$/)
      expect(perform).to match(/^KEY2=value2$/)
    end

    it_behaves_like 'preserving existing keypairs'
    it_behaves_like 'initial conditions'
  end
end
