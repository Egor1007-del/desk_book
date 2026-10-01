require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @position = Position.create!(name: "Developer")
  end

  test "requires personal data, hiring date, login, and position" do
    %i[last_name first_name hired_on login].each do |attribute|
      user = User.new(valid_attributes.merge(attribute => nil))

      assert_not user.valid?
      assert user.errors.of_kind?(attribute, :blank)
    end

    user = User.new(valid_attributes.merge(position: nil))

    assert_not user.valid?
    assert user.errors.of_kind?(:position, :blank)
  end

  test "database requires all mandatory columns" do
    required_columns = %w[last_name first_name position_id hired_on login encrypted_password]

    required_columns.each do |column_name|
      assert_not User.columns_hash.fetch(column_name).null
    end
  end

  test "allows optional middle name, phone, and email" do
    user = User.create!(valid_attributes.merge(middle_name: nil, phone: nil, email: nil))

    assert_predicate user, :persisted?
  end

  test "normalizes login before validation" do
    user = User.create!(valid_attributes.merge(login: "  John.Doe  "))

    assert_equal "john.doe", user.login
  end

  test "requires login to be unique regardless of case and surrounding spaces" do
    User.create!(valid_attributes.merge(login: "john.doe"))
    duplicate = User.new(valid_attributes.merge(login: "  JOHN.DOE  "))

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:login, :taken)
  end

  test "database index enforces case insensitive login uniqueness" do
    User.create!(valid_attributes.merge(login: "john.doe"))

    assert_raises(ActiveRecord::RecordNotUnique) do
      User.insert!({
        last_name: "Smith",
        first_name: "Jane",
        position_id: @position.id,
        hired_on: Date.new(2024, 2, 1),
        login: "JOHN.DOE",
        encrypted_password: "another-password-digest"
      })
    end
  end

  test "builds full name with a middle name" do
    user = User.new(last_name: "Doe", first_name: "John", middle_name: "Michael")

    assert_equal "Doe John Michael", user.full_name
  end

  test "builds full name without a blank middle name" do
    user = User.new(last_name: "Doe", first_name: "John", middle_name: " ")

    assert_equal "Doe John", user.full_name
  end

  private

  def valid_attributes
    {
      last_name: "Doe",
      first_name: "John",
      position: @position,
      hired_on: Date.new(2024, 1, 15),
      login: "john.doe",
      encrypted_password: "password-digest"
    }
  end
end
