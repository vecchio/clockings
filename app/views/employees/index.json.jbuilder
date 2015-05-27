json.array!(@employees) do |employee|
  json.extract! employee, :id, :name, :surname, :sort, :finger
  json.url employee_url(employee, format: :json)
end
