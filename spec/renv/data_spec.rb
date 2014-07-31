require 'renv/data'

describe Renv::Data do
  let(:payload) { '' }
  subject { described_class.new(payload) }

  context 'with a simple payload' do
    let(:payload) { "FOO=bar\nBAR=baz" }
    
    describe '#[]' do
      it 'returns nil for unknown keys' do
        expect(subject['DO_YOU_EVEN']).to be_nil
      end

      it 'returns key values' do
        expect(subject['FOO']).to eq('bar')
      end
    end

    describe '#[]=' do
      it 'aborts on bad keys' do
        expect { subject['hello, world!'] = 'foo' }.to raise_error(SystemExit)
      end

      it 'sets key values' do
        subject['DO_YOU'] = 'even'
        expect(subject['DO_YOU']).to eq('even')
      end
    end

    describe '#dump' do
      it 'serializes the hash' do
        subject['BAZ'] = 'qux'
        expect(subject.dump).to eq("FOO=bar\nBAR=baz\nBAZ=qux\n")
      end
    end

    describe '#load' do
      it 'adds extra keys' do
        subject.load('QUX=even')
        expect(subject['QUX']).to eq('even')
      end

      it 'does not remove existing keys' do
        subject.load('QUX=even')
        expect(subject['FOO']).to eq('bar')
      end

      it 'replaces same keys' do
        subject.load('FOO=qux')
        expect(subject['FOO']).to eq('qux')
      end
    end
  end

  describe '#initialize' do
    it 'does not require a payload' do
      expect { described_class.new }.not_to raise_error
    end

    it 'accepts comments' do
      payload.replace "# comment1\nFOO=bar\n# comment 2"
      expect(subject['FOO']).to eq('bar')
    end

    it 'accepts blank lines' do
      payload.replace "\n\nFOO=bar\n\n\n# comment 2\n\n"
      expect(subject['FOO']).to eq('bar')
    end

    it 'accepts multiple equal signs' do
      payload.replace "FOO=bar=baz"
      expect(subject['FOO']).to eq('bar=baz')
    end

    it 'accepts spaces in values' do
      payload.replace "FOO=bar  baz"
      expect(subject['FOO']).to eq('bar  baz')
    end

    it 'rejects misformatted pairs' do
      payload.replace "FOO: bar baz"
      expect { subject }.to raise_error(SystemExit)
    end

    it 'only loads the last of identical keys' do
      payload.replace "FOO=bar\nFOO=qux"
      expect(subject['FOO']).to eq('qux')
    end
  end
end
