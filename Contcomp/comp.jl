using CSV, DataFrames, Statistics

# List of ISO codes for top 9 economies + Costa Rica (uppercase)
selected_iso = ["BRA", "CHN", "CRI", "FRA", "DEU", "IND", "IDN", "JPN", "RUS", "USA"]

# Load GDP data
gdp = CSV.read("capita.csv", DataFrame)

# Extract and uppercase the first part of SERIES_CODE (before the dot)
gdp[!, :ISO] = [uppercase(String(split(code, ".")[1])) for code in gdp.SERIES_CODE]

# Filter GDP for selected countries only
gdp_filtered = filter(row -> row.ISO in selected_iso, gdp)

# Load HDI data
hdi = CSV.read("hdr-data.csv", DataFrame)
hdi[!, :countryIsoCode] = [uppercase(String(code)) for code in hdi.countryIsoCode]

# Filter HDI for selected countries only
hdi_filtered = filter(row -> row.countryIsoCode in selected_iso, hdi)

# Join filtered datasets
combined = innerjoin(gdp_filtered, hdi_filtered, on = [:ISO => :countryIsoCode])

# Create a clean, readable summary
println("GDP per Capita (PPP) and Human Development Data:")
println("=" ^ 60)

for row in eachrow(combined)
    country = row.country  # Using country from GDP data
    iso = row.ISO
    
    # Get the most recent GDP value (assuming the last column is most recent)
    gdp_cols = names(gdp_filtered)[occursin.("2", names(gdp_filtered))]
    if !isempty(gdp_cols)
        latest_gdp = row[gdp_cols[end]]
    else
        latest_gdp = "N/A"
    end
    
    ihdi = row.value  # IHDI value from HDI data
    
    println("Country: $country ($iso)")
    println("  GDP per Capita (PPP): \$$(round(latest_gdp, digits=0))")
    println("  Inequality-adjusted HDI: $ihdi")
    println()
end

# Also create a simple table view
println("\nSummary Table:")
println("=" ^ 60)
println("Country                   | ISO | GDP per Capita (PPP) | IHDI")
println("-" ^ 60)

for row in eachrow(combined)
    country = rpad(row.country, 25)
    iso = row.ISO
    
    # Get latest GDP
    gdp_cols = names(gdp_filtered)[occursin.("2", names(gdp_filtered))]
    if !isempty(gdp_cols)
        gdp_value = Int(round(row[gdp_cols[end]]))
        latest_gdp = "\$$gdp_value"
    else
        latest_gdp = "N/A"
    end
    
    ihdi = row.value
    
    println("$country | $iso | $(rpad(latest_gdp, 20)) | $ihdi")
end
