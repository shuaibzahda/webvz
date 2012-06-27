class String
  def strip_quotes
    gsub(/\A['"]+|['"]+\Z/, "")
  end
end
