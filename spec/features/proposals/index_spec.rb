feature "Proposals index" do
  include ProposalTableSpecHelper

  scenario "filters pending proposals according to current_user" do
    user = create(:user)
    _reviewable_proposals = create_list(:proposal, 2, :with_approver, observer: user)
    _pending_proposals = create_list(:proposal, 2, :with_approver, approver_user: user)
    _canceled = create_list(:proposal, 2, status: "canceled", observer: user)
    @page = ProposalIndexPage.new

    login_as(user)
    @page.load

    expect(@page.needing_review).to have_content('Please review')
    expect(@page.pending).to have_content('Waiting for review')
    expect(@page.canceled).to have_content('Cancelled')
  end

  scenario "defaults to sorted by created date" do
    user = create(:user)
    proposals = create_list(:proposal, 2, :with_approver, approver_user: user)
    canceled = create_list(:proposal, 2, :with_approver, status: "canceled", approver_user: user)
    @page = ProposalIndexPage.new

    login_as(user)
    @page.load

    expect(@page.needing_review.desc_column_header).to have_content "Submitted"
    expect(@page.canceled.desc_column_header).to have_content "Submitted"

    expect_order(@page.pending, proposals.reverse)
    expect_order(@page.canceled, canceled.reverse)
  end

  feature "The 'needing review' section" do
    context "when there are requests that can be acted on by the user" do
      scenario "contains those requests" do
        user = create(:user)
        proposal = create(:proposal, :with_approver, approver_user: user)

        login_as(user)
        @page = ProposalIndexPage.new
        @page.load

        expect(@page.needing_review).to have_content "Purchase Requests Needing Review"
        expect(@page.needing_review.requests.first.public_id_link.text).to eq proposal.public_id
      end
    end

    context "when there are no requests that can be acted on by the user" do
      scenario "does not exist" do
        login_as(create(:user))
        @page = ProposalIndexPage.new
        @page.load

        expect(@page.needing_review).to_not have_content "Purchase Requests Needing Review"
        expect(@page.needing_review.requests).to be_empty
      end
    end
  end

  feature "new feature flag" do
    context "when the user hasn't seen a feature" do
      scenario "shows an icon when the user hasn't seen the help doc", :js do
        beta_active = create(:user, :beta_active, client_slug: "ncr")

        login_as(beta_active)
        visit proposals_path
        expect(page.find('.new-features-button img')['src']).to have_content('new_feature_icon.svg')
        click_on "New features"

        visit proposals_path
        expect(page.find('.new-features-button img')['src']).to have_content('new_feature_icon_none.svg')
      end
    end
  end


  feature "status field text" do
    context "when the user is an approver" do
      scenario "is correct for the user" do
        user = create(:user)
        approval_proposal = create_proposal_with_approvers(user, create(:user))
        @page = ProposalIndexPage.new

        login_as(user)
        @page.load

        expect(@page.needing_review.requests[0].public_id_link.text).to eq approval_proposal.public_id
        expect(@page.needing_review.requests[0].status.text).to eq "Please review"
      end
    end

    context "when the user is a purchaser" do
      scenario "is correct for the user" do
        user = create(:user)
        purchase_proposal = create_proposal_with_approvers(create(:user), user)
        purchase_proposal.individual_steps.first.complete!
        @page = ProposalIndexPage.new

        login_as(user)
        @page.load

        expect(@page.needing_review.requests[0].public_id_link.text).to eq purchase_proposal.public_id
        expect(@page.needing_review.requests[0].status.text).to eq "Please purchase"
      end
    end

    context "when the user's request is waiting for approval" do
      scenario "is correct for the user" do
        user = create(:user)
        approver = create(:user)
        approval_proposal = create_proposal_for_requester_with_approvers(user, approver, create(:user))
        @page = ProposalIndexPage.new

        login_as(user)
        @page.load

        expect(@page.pending.requests[0].public_id_link.text).to eq approval_proposal.public_id
        expect(@page.pending.requests[0].status.text).to eq "Pending Waiting for review from: #{approver.full_name}"
      end
    end

    context "when the user's request is waiting for purchase" do
      scenario "is correct for the user" do
        user = create(:user)
        purchaser = create(:user)
        purchase_proposal = create_proposal_for_requester_with_approvers(user, create(:user), purchaser)
        purchase_proposal.individual_steps.first.complete!
        @page = ProposalIndexPage.new

        login_as(user)
        @page.load

        expect(@page.pending.requests[0].public_id_link.text).to eq purchase_proposal.public_id
        expect(@page.pending.requests[0].status.text).to eq "Pending Waiting for purchase from: #{purchaser.full_name}"
      end
    end
  end

  def create_proposal_with_approvers(first_approver, second_approver)
    proposal = create(:proposal)
    steps = [
      create(:approval_step, user: first_approver),
      create(:purchase_step, user: second_approver)
    ]
    proposal.add_initial_steps(steps)
    proposal
  end

  def create_proposal_for_requester_with_approvers(requester, first_approver, second_approver)
    proposal = create_proposal_with_approvers(first_approver, second_approver)
    proposal.update(requester: requester)
    proposal
  end
end
