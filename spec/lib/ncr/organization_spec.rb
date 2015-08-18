describe Ncr::Organization do
  describe '#==' do
    it "considers two objects with the same #code identical" do
      expect(Ncr::Organization.new(code: '12', name: 'foo')).to eq(Ncr::Organization.new(code: '12', name: 'foo'))
    end
  end

  describe '.all' do
    it "returns all records" do
      expect(Ncr::Organization.all.size).to be > 10
    end

    it "populates the attributes for each" do
      Ncr::Organization.all.each do |org|
        expect(org.code).to be_present
        expect(org.name).to be_present
      end
    end
  end
end
