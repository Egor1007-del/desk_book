position_names = [ "должность 1", "должность 2", "должность 3" ]
admin_login = ENV.fetch("ADMIN_LOGIN", "admin").strip.downcase
employee_password = ENV.fetch("EMPLOYEE_PASSWORD", "employee")
employee_names = [
  [ "Иванов", "Иван", "Сергеевич" ],
  [ "Петрова", "Анна", "Викторовна" ],
  [ "Сидоров", "Алексей", "Михайлович" ],
  [ "Смирнова", "Елена", "Андреевна" ],
  [ "Кузнецов", "Дмитрий", "Олегович" ],
  [ "Попова", "Мария", "Игоревна" ],
  [ "Васильев", "Николай", "Павлович" ],
  [ "Соколова", "Ольга", "Романовна" ],
  [ "Михайлов", "Артём", "Денисович" ],
  [ "Новикова", "Екатерина", "Алексеевна" ],
  [ "Фёдоров", "Максим", "Евгеньевич" ],
  [ "Морозова", "Наталья", "Сергеевна" ],
  [ "Волков", "Кирилл", "Андреевич" ],
  [ "Алексеева", "Ирина", "Дмитриевна" ],
  [ "Лебедев", "Роман", "Викторович" ],
  [ "Семёнова", "Татьяна", "Олеговна" ],
  [ "Егоров", "Павел", "Ильич" ],
  [ "Павлова", "Светлана", "Михайловна" ],
  [ "Козлов", "Андрей", "Николаевич" ],
  [ "Степанова", "Юлия", "Романовна" ],
  [ "Николаев", "Денис", "Алексеевич" ],
  [ "Орлова", "Виктория", "Игоревна" ],
  [ "Андреев", "Сергей", "Павлович" ],
  [ "Макарова", "Алиса", "Евгеньевна" ],
  [ "Захаров", "Михаил", "Дмитриевич" ],
  [ "Белова", "Дарья", "Сергеевна" ],
  [ "Григорьев", "Владислав", "Олегович" ],
  [ "Тарасова", "Ксения", "Андреевна" ],
  [ "Борисов", "Илья", "Викторович" ],
  [ "Комарова", "София", "Максимовна" ]
]

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
    admin = User.new(
      last_name: "Администратор",
      first_name: "Системы",
      position: positions.fetch("должность 1"),
      hired_on: Date.current,
      login: admin_login,
      password: password,
      password_confirmation: password
    )
    admin.save_with_role!(role: :admin)
  end

  admin.save_with_role!(role: :admin) unless admin.only_has_role?(:admin)

  employee_names.each_with_index do |(last_name, first_name, middle_name), index|
    login = format("employee%02d", index + 1)
    next if User.exists?(login: login)

    employee = User.new(
      last_name: last_name,
      first_name: first_name,
      middle_name: index.remainder(7).zero? ? nil : middle_name,
      position: positions.fetch(position_names.fetch(index.remainder(position_names.size))),
      hired_on: Date.new(2018 + index.remainder(7), index.remainder(12) + 1, index.remainder(27) + 1),
      phone: index.remainder(6).zero? ? nil : format("9%09d", index + 1),
      email: index.remainder(5).zero? ? nil : "#{login}@example.com",
      login: login,
      password: employee_password,
      password_confirmation: employee_password
    )
    employee.save_with_role!(role: :employee)
  end
end
