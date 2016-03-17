describe ObserverMailer do
  include MailerSpecHelper

  describe "#observer_added_notification" do
    it "sends to the observer" do
      proposal = create(:proposal, :with_observer)
      observation = proposal.observations.first

      mail = ObserverMailer.observer_added_notification(observation, nil)

      observer = observation.user
      expect(mail.to).to eq([observer.email_address])
    end

    it "includes who they were added by" do
      adder = create(:user)
      PaperTrail.whodunnit = adder.id

      proposal = create(:proposal, :with_observer)
      observation = proposal.observations.first
      expect(observation.created_by).to eq(adder)

      mail = ObserverMailer.observer_added_notification(observation, nil)
      expect(mail.body.encoded).to include("to this request by #{adder.full_name}")
    end

    it "excludes who they were added by, if not available" do
      proposal = create(:proposal, :with_observer)
      observation = proposal.observations.first

      mail = ObserverMailer.observer_added_notification(observation, nil)
      expect(mail.body.encoded).to_not include("to this request by ")
    end

    it "includes the reason, if there is one" do
      proposal = create(:proposal)
      observer = create(:user)
      adder = create(:user)
      reason = "is an absolute ledge"
      proposal.add_observer(observer, adder, reason)
      observation = proposal.observations.first

      mail = ObserverMailer.observer_added_notification(observation, reason)
      expect(mail.body.encoded).to include("with given reason '#{reason}'")
    end
  end

  describe "#observer_removed_notification" do
    it "sends to the observer" do
      proposal = create(:proposal, :with_observer)
      observation = proposal.observations.first
      observer = observation.user

      mail = ObserverMailer.observer_removed_notification(proposal, observer)

      expect(mail.to).to eq([observer.email_address])
    end
  end

  describe "#proposal_complete" do
    let(:mail) { ObserverMailer.proposal_complete(observer, proposal) }

    it_behaves_like "a proposal email"
  end

  private

  def proposal
    @proposal ||= create(:proposal)
  end

  def observer
    @observer ||= create(:observation).user
  end
end
