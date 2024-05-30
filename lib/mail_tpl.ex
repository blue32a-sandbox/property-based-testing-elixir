defmodule Bday.MailTpl do
  def body(employee) do
    name = Bday.Employee.first_name(employee)
    "Happy birthday, dear #{name}!"
  end

  def full(employee) do
    {[Bday.Employee.email(employee)], "Happy birthday!", body(employee)}
  end
end
