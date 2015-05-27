json.array!(@clockings) do |clocking|
  json.extract! clocking, :id, :finger, :direction, :clocking, :workday
  json.url clocking_url(clocking, format: :json)
end
