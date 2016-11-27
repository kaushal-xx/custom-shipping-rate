json.content do
  arr1 = []
  json.array!(@state) do |st|
    values = @shipping_weights.where(state: st.state).order("id")
    arr2 = []
    arr2.push(st.state) 
    values.each do |v|
      arr2.push(v.price.to_s)
    end
    arr1.push arr2
  end
  json.array!(arr1)
end

json.header_content do
  header_arr = ['Ship To State ---  Weight Range']
  @sheet_headers.each do |sh|
    header_arr.push sh.weight
  end
  json.array!(header_arr)
end
