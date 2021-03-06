# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Registering for a competition" do
  let(:user) { FactoryGirl.create :user }
  let(:delegate) { FactoryGirl.create :delegate }
  let(:competition) { FactoryGirl.create :competition, :registration_open, delegates: [delegate], showAtAll: true }

  context "signed in as user" do
    before :each do
      sign_in user
    end

    scenario "User registers for a competition" do
      visit competition_register_path(competition)
      check "registration_events_333"
      click_button "Register!"
      expect(page).to have_text("Successfully registered!")
      registration = competition.registrations.find_by_user_id(user.id)
      expect(registration).not_to eq nil
    end

    scenario "User with preferred events goes to register page" do
      user.update_attribute :user_preferred_events_attributes, [ {event_id: "333"}, {event_id: "444"}, {event_id: "555"} ]
      competition.update_attribute :eventSpecs, "444 555 666"

      visit competition_register_path(competition)
      expect(find("#registration_events_444")).to be_checked
      expect(find("#registration_events_555")).to be_checked
      expect(find("#registration_events_666")).to_not be_checked
    end
  end

  context "not signed in" do
    scenario "following sign in link on register page should redirect back to register page" do
      visit competition_register_path(competition)

      within('#competition-data') do
        click_link("Sign in")
      end
      fill_in "Email or WCA ID", with: user.email
      fill_in "Password", with: user.password
      click_button "Sign in"

      expect(current_url).to eq competition_register_url(competition)
    end
  end

  context "signed in as delegate" do
    let(:registration) { FactoryGirl.create(:registration, user: user, competition: competition) }
    before :each do
      sign_in delegate
    end

    scenario "updating registration" do
      visit edit_registration_path(registration)
      fill_in "Guests", with: 1
      click_button "Update Registration"
      expect(registration.reload.guests).to eq 1
    end

    scenario "deleting registration" do
      visit edit_registration_path(registration)
      click_link "Delete"
      expect(Registration.find_by_id(registration.id)).to eq nil
    end
  end
end
