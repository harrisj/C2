describe "White House Service Center proposals" do
  it "requires sign-in" do
    visit '/whsc/proposals/new'
    expect(current_path).to eq('/')
    expect(page).to have_content("You need to sign in")
  end

  context "when signed in" do
    let(:requester) { FactoryGirl.create(:user) }

    before do
      login_as(requester)
    end

    it "saves a Cart with the attributes" do
      visit '/whsc/proposals/new'
      fill_in 'Description', with: "buying stuff"
      fill_in 'Vendor', with: 'ACME'
      fill_in 'Amount', with: 123.45

      expect {
        click_on 'Submit for approval'
      }.to change { Cart.count }.from(0).to(1)

      expect(page).to have_content("Proposal submitted")

      cart = Cart.last
      expect(cart.name).to eq("buying stuff")
      expect(cart.getProp(:vendor)).to eq('ACME')
      # TODO should this persist as a number?
      expect(cart.getProp(:amount)).to eq('123.45')
      expect(cart.requester).to eq(requester)
    end

    it "doesn't save when the amount is too high" do
      visit '/whsc/proposals/new'
      fill_in 'Description', with: "buying stuff"
      fill_in 'Vendor', with: 'ACME'
      fill_in 'Amount', with: 10_000

      expect {
        click_on 'Submit for approval'
      }.to_not change { Cart.count }

      expect(current_path).to eq('/whsc/proposals')
      expect(page).to have_content("Amount must be less than or equal to 3000")
      # keeps the form values
      expect(find_field('Amount').value).to eq('10000')
    end
  end
end