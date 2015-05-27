json.array!(@holidays) do |holiday|
  json.extract! holiday, :id, :holiday, :holidate
  json.url holiday_url(holiday, format: :json)
end
