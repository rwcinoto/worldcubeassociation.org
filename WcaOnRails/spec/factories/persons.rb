# frozen_string_literal: true
FactoryGirl.define do
  factory :person do
    wca_id do
      mid = ('A'..'Z').to_a.sample(4).join
      "2016#{mid}01".tap do |id|
        id.next! while Person.exists?(wca_id: id)
      end
    end
    subId 1
    name { Faker::Name.name }
    countryId { Country.all_real.sample.id }
    gender "m"
    year 1966
    month 4
    day 4

    factory :person_with_multiple_sub_ids do
      after(:create) do |person|
        person.update_using_sub_id(countryId: "Israel")
      end
    end

    factory :person_who_has_competed_once do
      after(:create) do |person|
        competition = FactoryGirl.create(:competition, :with_delegate)
        FactoryGirl.create :result, person: person, competitionId: competition.id
        FactoryGirl.create :result, person: person, competitionId: competition.id
      end
    end
  end
end
