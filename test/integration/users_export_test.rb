require "test_helper"
require "zip"

class UsersExportTest < ActionDispatch::IntegrationTest
  XLSX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  setup do
    developer = Position.create!(name: "Developer")
    manager = Position.create!(name: "Manager")

    @employee = create_user(
      login: "private-employee-login",
      role: :employee,
      position: developer,
      last_name: "Ivanov",
      first_name: "Ivan",
      middle_name: "Ivanovich",
      phone: "+7 900 123 45 67",
      email: "ivanov@example.com"
    )
    @admin = create_user(
      login: "private-admin-login",
      role: :admin,
      position: manager,
      last_name: "Petrov",
      first_name: "Petr",
      phone: nil,
      email: nil
    )
  end

  test "unauthenticated user cannot export the registry" do
    get users_path(format: :xlsx)

    assert_response :unauthorized
  end

  test "employee can export only public registry fields" do
    sign_in_as(@employee)

    get users_path(format: :xlsx)

    assert_xlsx_response
    assert_equal [
      [ "Full name", "Position", "Phone", "Email" ],
      [ @employee.full_name, @employee.position.name, @employee.phone, @employee.email ],
      [ @admin.full_name, @admin.position.name, nil, nil ]
    ], worksheet_rows
    assert_phone_is_left_aligned
    assert_private_fields_absent
  end

  test "admin can export the same public registry fields" do
    sign_in_as(@admin)

    get users_path(format: :xlsx)

    assert_xlsx_response
    assert_equal 3, worksheet_rows.size
    assert_private_fields_absent
  end

  test "registry has a non-Turbo Excel download link" do
    sign_in_as(@employee)

    get users_path

    assert_response :success
    assert_select "a[href='#{users_path(format: :xlsx)}'][data-turbo='false']",
      text: "Download Excel"
  end

  private

  def create_user(login:, role:, position:, last_name:, first_name:, middle_name: nil, phone:, email:)
    User.new(
      last_name: last_name,
      first_name: first_name,
      middle_name: middle_name,
      position: position,
      hired_on: Date.new(2024, 1, 15),
      phone: phone,
      email: email,
      login: login,
      password: "secret123",
      password_confirmation: "secret123"
    ).tap do |user|
      user.save_with_role!(role: role)
    end
  end

  def sign_in_as(user)
    post user_session_path, params: {
      user: { login: user.login, password: "secret123" }
    }
    follow_redirect!
  end

  def assert_xlsx_response
    assert_response :success
    assert_equal XLSX_CONTENT_TYPE, response.media_type
    assert_equal 'attachment; filename="employees.xlsx"', response.headers["Content-Disposition"]
  end

  def assert_private_fields_absent
    cells = worksheet_rows.flatten.compact

    assert_not_includes cells, @employee.login
    assert_not_includes cells, @admin.login
    assert_not_includes cells, "employee"
    assert_not_includes cells, "admin"
    assert_not_includes cells, "secret123"
    assert_not_includes cells, @employee.encrypted_password
  end

  def worksheet_rows
    Zip::File.open_buffer(StringIO.new(response.body)) do |archive|
      document = Nokogiri::XML(archive.read("xl/worksheets/sheet1.xml"))
      document.remove_namespaces!

      return document.xpath("//sheetData/row").map do |row|
        row.xpath("./c").map { |cell| cell.xpath(".//t").map(&:text).join.presence }
      end
    end
  end

  def assert_phone_is_left_aligned
    Zip::File.open_buffer(StringIO.new(response.body)) do |archive|
      worksheet = Nokogiri::XML(archive.read("xl/worksheets/sheet1.xml"))
      styles = Nokogiri::XML(archive.read("xl/styles.xml"))
      worksheet.remove_namespaces!
      styles.remove_namespaces!

      phone_cell = worksheet.xpath("//sheetData/row")[1].xpath("./c")[2]
      cell_style = styles.xpath("//cellXfs/xf")[phone_cell["s"].to_i]

      assert_equal "inlineStr", phone_cell["t"]
      assert_equal "left", cell_style.at_xpath("./alignment")["horizontal"]
    end
  end
end
