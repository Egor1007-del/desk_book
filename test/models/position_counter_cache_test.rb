require "test_helper"

class PositionCounterCacheTest < ActiveSupport::TestCase
  setup do
    @position = Position.create!(name: "Counter source")
    @destination = Position.create!(name: "Counter destination")
  end

  test "empty position starts at zero and creation and destruction update count" do
    assert_equal 0, @position.users_count
    user = create_user
    assert_equal 1, @position.reload.users_count

    user.destroy_with_role_safety!

    assert_equal 0, @position.reload.users_count
  end

  test "changing position updates both counters and ordinary edits leave them unchanged" do
    user = create_user
    user.save_with_role!({ position: @destination }, role: :employee)

    assert_equal 0, @position.reload.users_count
    assert_equal 1, @destination.reload.users_count

    user.update!(phone: "12345")

    assert_equal 0, @position.reload.users_count
    assert_equal 1, @destination.reload.users_count
  end

  test "invalid creation does not increment counter" do
    assert_raises(ActiveRecord::RecordInvalid) { create_user(role: :unknown) }

    assert_equal 0, @position.reload.users_count
  end

  test "transaction rollback restores counters after creation and destruction" do
    User.transaction do
      create_user
      assert_equal 1, @position.reload.users_count
      raise ActiveRecord::Rollback
    end
    assert_equal 0, @position.reload.users_count

    user = create_user
    User.transaction do
      user.destroy_with_role_safety!
      assert_equal 0, @position.reload.users_count
      raise ActiveRecord::Rollback
    end
    assert_equal 1, @position.reload.users_count
  end

  test "failed last admin demotion rolls back saved position and counters" do
    admin = create_user(role: :admin)

    assert_raises(ActiveRecord::RecordInvalid) do
      admin.save_with_role!({ position: @destination }, role: :employee)
    end

    assert_equal @position.id, admin.reload.position_id
    assert_equal 1, @position.reload.users_count
    assert_equal 0, @destination.reload.users_count
  end

  private

  def create_user(role: :employee)
    User.new(
      last_name: "Counter", first_name: "Test", position: @position,
      hired_on: Date.new(2024, 1, 1), login: "counter-test",
      password: "secret123", password_confirmation: "secret123"
    ).tap { |user| user.save_with_role!(role: role) }
  end
end
