position_names = [ "должность 1", "должность 2", "должность 3" ]
admin_login = ENV.fetch("ADMIN_LOGIN", "admin").strip.downcase

ApplicationRecord.transaction do
  positions = position_names.index_with do |name|
    Position.find_or_create_by!(name: name)
  end

  Role::NAMES.each do |name|
    Role.find_or_create_by!(name: name)
  end

  admin = User.find_by(login: admin_login)

  unless admin
    password = ENV.fetch("ADMIN_PASSWORD", "admin")
    admin = User.create_with_role!(
      {
        last_name: "Администратор",
        first_name: "Системы",
        position: positions.fetch("должность 1"),
        hired_on: Date.current,
        login: admin_login,
        password: password,
        password_confirmation: password
      },
      role: :admin
    )
  end

  admin.assign_role!(:admin) unless admin.only_has_role?(:admin)
end
